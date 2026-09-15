import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import 'secure_store.dart';

/// The complete token pair is one secure-storage value. The SQLite database holds
/// only opaque coordination IDs and a lease deadline, never passwords or tokens.
class StoredSession {
  const StoredSession({
    required this.id,
    required this.server,
    required this.userId,
    required this.refreshToken,
    required this.accessToken,
  });
  final String id, server, userId, refreshToken;
  final String? accessToken;

  Map<String, dynamic> toJson() => {
    'id': id,
    'server': server,
    'user_id': userId,
    'refresh_token': refreshToken,
    'access_token': accessToken,
  };

  static StoredSession? parse(Map<String, dynamic>? value) {
    if (value == null ||
        value['id'] is! String ||
        value['server'] is! String ||
        value['user_id'] is! String ||
        value['refresh_token'] is! String ||
        (value['id'] as String).isEmpty ||
        (value['refresh_token'] as String).isEmpty ||
        (value['access_token'] != null && value['access_token'] is! String)) {
      return null;
    }
    return StoredSession(
      id: value['id'] as String,
      server: value['server'] as String,
      userId: value['user_id'] as String,
      refreshToken: value['refresh_token'] as String,
      accessToken: value['access_token'] as String?,
    );
  }
}

class RefreshLease {
  const RefreshLease(this.session, this.owner);
  final StoredSession session;
  final String owner;
}

/// SQLite transactions serialize both Flutter engines, including two isolates in
/// one process. No network request runs inside a transaction. Completion checks
/// session ID AND lease owner, so a late worker cannot overwrite a newer login.
/// A crash between the secure write and SQL commit fails closed on mismatched IDs.
class SessionCoordinator {
  SessionCoordinator(
    this.store, {
    Future<Database> Function()? openDatabase,
    int Function()? nowMs,
  }) : _open = openDatabase ?? _openDefault,
       _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);
  final SecureStore store;
  final Future<Database> Function() _open;
  final int Function() _now;
  Future<Database>? _database;
  static const leaseDuration = Duration(minutes: 2);

  static String _id() => base64UrlEncode(
    List<int>.generate(24, (_) => Random.secure().nextInt(256)),
  ).replaceAll('=', '');

  static Future<void> createSchema(Database db, int version) async {
    await db.execute(
      'CREATE TABLE session_coordination ('
      'id INTEGER PRIMARY KEY CHECK(id=1), session_id TEXT, lease_owner TEXT, '
      'lease_until INTEGER NOT NULL DEFAULT 0, migrated INTEGER NOT NULL DEFAULT 0)',
    );
    await db.insert('session_coordination', {'id': 1});
  }

  static Future<Database> _openDefault() async => openDatabase(
    '${await getDatabasesPath()}/session-coordination.db',
    version: 1,
    onCreate: createSchema,
  );

  Future<Database> get _db => _database ??= _open();

  Future<Map<String, Object?>> _row(Transaction tx) async =>
      (await tx.query('session_coordination', where: 'id=1')).single;

  Future<StoredSession?> _record(Map<String, Object?> row) async {
    final value = StoredSession.parse(await store.readSessionData());
    return value != null && row['session_id'] == value.id ? value : null;
  }

  Future<StoredSession?> read(String server) async =>
      (await _db).transaction((tx) async {
        final value = await _record(await _row(tx));
        return value?.server == server ? value : null;
      }, exclusive: true);

  Future<StoredSession> install({
    required String server,
    required String userId,
    required String refreshToken,
    required String accessToken,
  }) async {
    final record = StoredSession(
      id: _id(),
      server: server,
      userId: userId,
      refreshToken: refreshToken,
      accessToken: accessToken,
    );
    await (await _db).transaction((tx) async {
      await store.writeSessionData(record.toJson());
      await tx.update('session_coordination', {
        'session_id': record.id,
        'lease_owner': null,
        'lease_until': 0,
        'migrated': 1,
      }, where: 'id=1');
      await store.clearRefreshToken();
      await store.clearBackgroundAccessToken();
    }, exclusive: true);
    return record;
  }

  /// Called once by foreground bootstrap against the already-saved active server.
  /// Background workers never migrate an unbound legacy token on their own.
  Future<void> migrateLegacy(String server) async {
    await (await _db).transaction((tx) async {
      final row = await _row(tx);
      if (row['migrated'] == 1) return;
      final token = await store.readRefreshToken();
      String? id;
      if (token != null && token.isNotEmpty) {
        id = _id();
        await store.writeSessionData(
          StoredSession(
            id: id,
            server: server,
            userId: '',
            refreshToken: token,
            accessToken: null,
          ).toJson(),
        );
      }
      await tx.update('session_coordination', {
        'session_id': id,
        'migrated': 1,
      }, where: 'id=1');
      await store.clearRefreshToken();
      await store.clearBackgroundAccessToken();
    }, exclusive: true);
  }

  Future<RefreshLease?> acquire(String server) async =>
      (await _db).transaction((tx) async {
        final row = await _row(tx);
        final record = await _record(row);
        if (record == null ||
            record.server != server ||
            (row['lease_until'] as int) > _now()) {
          return null;
        }
        final owner = _id();
        await tx.update('session_coordination', {
          'lease_owner': owner,
          'lease_until': _now() + leaseDuration.inMilliseconds,
        }, where: 'id=1');
        return RefreshLease(record, owner);
      }, exclusive: true);

  Future<StoredSession?> complete(
    RefreshLease lease, {
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async => (await _db).transaction((tx) async {
    final row = await _row(tx);
    final saved = await _record(row);
    if (saved == null ||
        saved.refreshToken != lease.session.refreshToken ||
        row['session_id'] != lease.session.id ||
        row['lease_owner'] != lease.owner ||
        (row['lease_until'] as int) <= _now() ||
        accessToken.isEmpty ||
        refreshToken.isEmpty ||
        userId.isEmpty ||
        (lease.session.userId.isNotEmpty && lease.session.userId != userId)) {
      return null;
    }
    final record = StoredSession(
      id: lease.session.id,
      server: lease.session.server,
      userId: userId,
      refreshToken: refreshToken,
      accessToken: accessToken,
    );
    await store.writeSessionData(record.toJson());
    await tx.update('session_coordination', {
      'lease_owner': null,
      'lease_until': 0,
    }, where: 'id=1');
    return record;
  }, exclusive: true);

  Future<void> release(RefreshLease lease) async {
    await (await _db).update(
      'session_coordination',
      {'lease_owner': null, 'lease_until': 0},
      where: 'id=1 AND session_id=? AND lease_owner=?',
      whereArgs: [lease.session.id, lease.owner],
    );
  }

  /// Returns the old record for best-effort server revocation. Notifications must
  /// be cancelled in this same critical section, after any old publish finished.
  Future<StoredSession?> clear({
    Future<void> Function()? afterClear,
  }) async => (await _db).transaction((tx) async {
    final record = await _record(await _row(tx));
    await tx.update('session_coordination', {
      'session_id': null,
      'lease_owner': null,
      'lease_until': 0,
      'migrated': 1,
    }, where: 'id=1');
    // Commit the inactive marker even if the OS keyring refuses deletion.
    // Neither read/migrate nor a late refresh can reactivate residual bytes.
    try {
      await store.clearSession();
    } on Object {
      /* inactive marker wins */
    }
    if (afterClear != null) {
      try {
        await afterClear();
      } on Object {
        /* logout must stay committed */
      }
    }
    return record;
  }, exclusive: true);

  /// Only local notification/state publication is allowed here, never HTTP.
  Future<bool> whileCurrent(
    StoredSession expected,
    Future<void> Function() action,
  ) async => (await _db).transaction((tx) async {
    final record = await _record(await _row(tx));
    if (record?.id != expected.id ||
        record?.server != expected.server ||
        record?.userId != expected.userId) {
      return false;
    }
    await action();
    return true;
  }, exclusive: true);
}
