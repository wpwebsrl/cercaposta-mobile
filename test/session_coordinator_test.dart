import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cercaposta/core/auth/secure_store.dart';
import 'package:cercaposta/core/auth/session_coordinator.dart';
import 'package:cercaposta/core/background/bg_constants.dart';
import 'package:cercaposta/core/background/notify_task.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Transport implements HttpClientAdapter {
  Transport(this.handle);
  final Future<ResponseBody> Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handle(options);
  @override
  void close({bool force = false}) {}
}

class DeleteFailingStore extends SecureStore {
  @override
  Future<void> clearSession() async => throw StateError('keyring unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late SecureStore store;
  late SessionCoordinator foreground, background;
  var now = 1000000;
  const server = 'https://a.example';

  Future<StoredSession> install(String user) => foreground.install(
    server: server,
    userId: user,
    refreshToken: 'refresh-$user',
    accessToken: 'access-$user',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'active_server': server,
      kPrefOsNotifications: true,
    });
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: SessionCoordinator.createSchema,
      ),
    );
    store = SecureStore();
    foreground = SessionCoordinator(
      store,
      openDatabase: () async => db,
      nowMs: () => now,
    );
    background = SessionCoordinator(
      store,
      openDatabase: () async => db,
      nowMs: () => now,
    );
  });
  tearDown(() async => db.close());

  test('concurrent owners acquire exactly one refresh lease', () async {
    await install('A');
    final leases = await Future.wait(
      List.generate(
        12,
        (i) => (i.isEven ? foreground : background).acquire(server),
      ),
    );
    expect(leases.whereType<RefreshLease>(), hasLength(1));
    final lease = leases.whereType<RefreshLease>().single;
    expect(
      await foreground.complete(
        lease,
        accessToken: 'new-a',
        refreshToken: 'new-r',
        userId: 'A',
      ),
      isNotNull,
    );
    expect((await background.read(server))?.refreshToken, 'new-r');
  });

  test('late background completion after logout cannot overwrite B', () async {
    await install('A');
    final old = (await background.acquire(server))!;
    await foreground.clear();
    final b = await install('B');
    final fresh = (await foreground.acquire(server))!;
    expect(
      await background.complete(
        old,
        accessToken: 'late-a',
        refreshToken: 'late-r',
        userId: 'A',
      ),
      isNull,
    );
    await background.release(old);
    expect(
      await background.acquire(server),
      isNull,
      reason: 'old owner cannot release the new lease',
    );
    expect((await foreground.read(server))?.id, b.id);
    expect(
      await foreground.complete(
        fresh,
        accessToken: 'fresh-b',
        refreshToken: 'fresh-rb',
        userId: 'B',
      ),
      isNotNull,
    );
  });

  test('expired lease completion cannot overwrite a successor', () async {
    await install('A');
    final expired = (await background.acquire(server))!;
    now += SessionCoordinator.leaseDuration.inMilliseconds + 1;
    final current = (await foreground.acquire(server))!;
    expect(
      await background.complete(
        expired,
        accessToken: 'late',
        refreshToken: 'late',
        userId: 'A',
      ),
      isNull,
    );
    await background.release(expired);
    expect(
      await foreground.complete(
        current,
        accessToken: 'good',
        refreshToken: 'good',
        userId: 'A',
      ),
      isNotNull,
    );
  });

  test('wrong user in refresh response never alters the stored pair', () async {
    await install('A');
    final lease = (await foreground.acquire(server))!;
    expect(
      await foreground.complete(
        lease,
        accessToken: 'bad',
        refreshToken: 'bad',
        userId: 'B',
      ),
      isNull,
    );
    expect((await foreground.read(server))?.refreshToken, 'refresh-A');
  });

  test(
    'uncommitted secure record fails closed and old legacy token cannot reappear',
    () async {
      await install('A');
      await store.writeSessionData(
        const StoredSession(
          id: 'uncommitted',
          server: server,
          userId: 'B',
          refreshToken: 'B',
          accessToken: 'B',
        ).toJson(),
      );
      expect(await foreground.read(server), isNull);
      await foreground.clear();
      await store.writeRefreshToken('stale-legacy');
      await foreground.migrateLegacy(server);
      expect(await foreground.read(server), isNull);
    },
  );

  test('legacy migration binds only the saved server and runs once', () async {
    await store.writeRefreshToken('legacy');
    await foreground.migrateLegacy(server);
    expect((await foreground.read(server))?.refreshToken, 'legacy');
    expect(await background.read('https://b.example'), isNull);
    expect(await store.readRefreshToken(), isNull);
  });

  test('late publication cannot mutate another session baseline', () async {
    final old = await install('A');
    await foreground.clear();
    await install('B');
    var published = false;
    expect(
      await background.whileCurrent(old, () async {
        published = true;
      }),
      isFalse,
    );
    expect(published, isFalse);
  });

  test(
    'keyring deletion failure cannot resurrect a logged-out session',
    () async {
      await install('A');
      final old = (await background.acquire(server))!;
      final failing = SessionCoordinator(
        DeleteFailingStore(),
        openDatabase: () async => db,
        nowMs: () => now,
      );
      await failing.clear();
      expect(
        await store.readSessionData(),
        isNotNull,
        reason: 'the OS deletion actually failed',
      );
      expect(await foreground.read(server), isNull);
      expect(
        await background.complete(
          old,
          accessToken: 'late',
          refreshToken: 'late',
          userId: 'A',
        ),
        isNull,
      );
      await foreground.migrateLegacy(server);
      expect(await foreground.read(server), isNull);
    },
  );

  test(
    'logout cancellation follows any already-started notification publication',
    () async {
      final old = await install('A');
      final entered = Completer<void>(), release = Completer<void>();
      final order = <String>[];
      final publishing = background.whileCurrent(old, () async {
        entered.complete();
        await release.future;
        order.add('published');
      });
      await entered.future;
      final clearing = foreground.clear(
        afterClear: () async {
          order.add('cancelled');
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(order, isEmpty);
      release.complete();
      await publishing;
      await clearing;
      expect(order, ['published', 'cancelled']);
      expect(await foreground.read(server), isNull);
    },
  );

  test(
    'current account still receives new notifications after its silent baseline',
    () async {
      await install('A');
      final prefs = await SharedPreferences.getInstance();
      var revision = 1;
      var published = 0;
      final dio = Dio(BaseOptions(baseUrl: '$server/api/v1'));
      dio.httpClientAdapter = Transport((request) async {
        final data = request.path == '/auth/refresh'
            ? {
                'access_token': 'rotated-$revision',
                'refresh_token': 'rotated-r$revision',
                'user': {'id': 'A'},
              }
            : request.path == '/events/state'
            ? {
                'revs': {'notifications': revision},
              }
            : {
                'items': [
                  {
                    'id': 'n$revision',
                    'created_at': DateTime.now()
                        .add(const Duration(minutes: 1))
                        .toIso8601String(),
                  },
                ],
              };
        return ResponseBody.fromString(
          jsonEncode(data),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      Future<void> poll() => runNotifyPoll(
        preferences: prefs,
        coordinator: background,
        client: dio,
        publish: (items, _) async {
          published += items.length;
        },
      );
      await poll();
      expect(published, 0);
      revision = 2;
      await poll();
      expect(published, 1);
      await poll();
      expect(published, 1, reason: 'same revision does not notify twice');
      expect((await foreground.read(server))?.userId, 'A');
      dio.close();
    },
  );

  for (final blockedPath in ['/auth/refresh', '/notifications']) {
    test('notification poll ignores old work paused at $blockedPath', () async {
      final old = await install('A');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBgSessionId, old.id);
      await prefs.setInt(kBgBaselineMs, 1);
      final entered = Completer<void>(), release = Completer<void>();
      var published = false;
      final dio = Dio(BaseOptions(baseUrl: '$server/api/v1'));
      dio.httpClientAdapter = Transport((request) async {
        if (request.path == blockedPath) {
          entered.complete();
          await release.future;
        }
        final data = request.path == '/auth/refresh'
            ? {
                'access_token': 'rotated-A',
                'refresh_token': 'rotated-rA',
                'user': {'id': 'A'},
              }
            : request.path == '/events/state'
            ? {
                'revs': {'notifications': 2},
              }
            : {
                'items': [
                  {'id': 'private-A', 'created_at': '2026-09-14T12:00:00Z'},
                ],
              };
        return ResponseBody.fromString(
          jsonEncode(data),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      final pending = runNotifyPoll(
        preferences: prefs,
        coordinator: background,
        client: dio,
        publish: (_, __) async {
          published = true;
        },
      );
      await entered.future;
      await foreground.clear();
      final b = await install('B');
      await prefs.setString(kBgSessionId, b.id);
      await prefs.setInt(kBgLastRev, 42);
      release.complete();
      await pending;
      expect(published, isFalse);
      expect((await foreground.read(server))?.refreshToken, 'refresh-B');
      expect(prefs.getString(kBgSessionId), b.id);
      expect(prefs.getInt(kBgLastRev), 42);
      dio.close();
    });
  }
}
