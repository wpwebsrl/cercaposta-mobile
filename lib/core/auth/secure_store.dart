import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_exception.dart';
import 'biometric_vault.dart';
import 'device_grant.dart';

class PendingGoogleOAuth {
  const PendingGoogleOAuth({
    required this.server,
    required this.state,
    required this.verifier,
  });

  final String server;
  final String state;
  final String verifier;
}

class PendingAppleOAuth {
  const PendingAppleOAuth({
    required this.server,
    required this.state,
    required this.verifier,
  });

  final String server;
  final String state;
  final String verifier;
}

/// Refresh sessions and non-secret biometric selectors. Device credentials use
/// an independent OS-protected store with authentication on every read.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage, BiometricVault? biometricVault})
    : _vault = biometricVault ?? NativeBiometricVault(),
      _s =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _s;
  final BiometricVault _vault;
  static const _kGrantInfo = 'biometric_grant_v1';

  static const _kRefresh = 'refresh_token';
  static const _kSessionRecord = 'session_record_v3';

  Future<Map<String, dynamic>?> readSessionData() async {
    final raw = await _s.read(key: _kSessionRecord);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } on Object {
      return null;
    }
  }

  Future<void> writeSessionData(Map<String, dynamic> value) =>
      _s.write(key: _kSessionRecord, value: jsonEncode(value));

  Future<void> clearSessionData() => _s.delete(key: _kSessionRecord);
  static const _kPassword = 'unlock_password'; // legacy, unlock-only
  static const _kCredServer = 'cred_server';
  static const _kCredUsername = 'cred_username';
  static const _kCredPassword = 'cred_password';
  static const _kCredentials = 'credentials_v2';
  static const _kGoogleServer = 'google_oauth_server';
  static const _kGoogleState = 'google_oauth_state';
  static const _kGoogleVerifier = 'google_oauth_verifier';
  static const _kAppleServer = 'apple_oauth_server';
  static const _kAppleState = 'apple_oauth_state';
  static const _kAppleVerifier = 'apple_oauth_verifier';

  Future<String?> readRefreshToken() => _s.read(key: _kRefresh);
  Future<void> writeRefreshToken(String token) =>
      _s.write(key: _kRefresh, value: token);
  Future<void> clearRefreshToken() => _s.delete(key: _kRefresh);

  // --- background-isolate token hand-off (docs/notifiche.md) -----------------
  // When the background notification isolate rotates the tokens it stashes the fresh access token
  // here; the foreground adopts it on resume (bg_rotated flag) instead of refreshing again and
  // racing the isolate. Not a long-lived secret — cleared as soon as it's adopted.
  static const _kBgAccess = 'bg_access_token';
  Future<String?> readBackgroundAccessToken() => _s.read(key: _kBgAccess);
  Future<void> writeBackgroundAccessToken(String token) =>
      _s.write(key: _kBgAccess, value: token);
  Future<void> clearBackgroundAccessToken() => _s.delete(key: _kBgAccess);

  // Reading the button/account selector never reads a password or native secret.
  Future<void> purgeLegacyPasswords() async {
    for (final key in [
      _kCredentials,
      _kCredServer,
      _kCredUsername,
      _kCredPassword,
      _kPassword,
    ]) {
      await _s.delete(key: key);
    }
  }

  Future<DeviceGrantInfo?> readGrantInfo() async {
    await purgeLegacyPasswords();
    final raw = await _s.read(key: _kGrantInfo);
    if (raw == null || raw.length > 8192) return null;
    try {
      return DeviceGrantInfo.parse(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<DeviceGrant> readGrant(
    DeviceGrantInfo info, {
    required String reason,
    required String cancel,
  }) async {
    final raw = await _vault.read(
      info.storageName,
      reason: reason,
      cancel: cancel,
    );
    if (raw == null || raw.length > 8192) {
      throw ApiException('biometric.reenroll');
    }
    try {
      final value = jsonDecode(raw);
      final bound = DeviceGrantInfo.parse(value);
      if (bound == null ||
          !bound.matches(info) ||
          value['device_secret'] is! String ||
          !RegExp(
            r'^[A-Za-z0-9_-]{43}$',
          ).hasMatch(value['device_secret'] as String)) {
        throw ApiException('biometric.reenroll');
      }
      return DeviceGrant(info, value['device_secret'] as String);
    } on ApiException {
      rethrow;
    } on Object {
      throw ApiException('biometric.reenroll');
    }
  }

  /// Publish the selector only after the OS accepted the protected write.
  /// A unique device ID keeps a cancelled replacement from destroying the old grant.
  Future<DeviceGrantInfo?> writeGrant(
    DeviceGrant grant, {
    required String reason,
    required String cancel,
    void Function()? beforePublish,
  }) async {
    final previous = await readGrantInfo();
    if (previous?.storageName == grant.info.storageName) {
      throw ArgumentError('New device ID required');
    }
    try {
      await _vault.write(
        grant.info.storageName,
        jsonEncode({...grant.info.toJson(), ...grant.credential}),
        reason: reason,
        cancel: cancel,
      );
      beforePublish?.call();
      await _s.write(key: _kGrantInfo, value: jsonEncode(grant.info.toJson()));
    } on Object {
      try {
        await _vault.delete(grant.info.storageName);
      } on Object {
        /* unreferenced */
      }
      rethrow;
    }
    return previous;
  }

  Future<void> deleteGrantFile(DeviceGrantInfo info) async {
    try {
      await _vault.delete(info.storageName);
    } on Object {
      /* selector already removed */
    }
  }

  Future<void> clearGrant() async {
    final previous = await readGrantInfo();
    await _s.delete(key: _kGrantInfo);
    if (previous != null) await deleteGrantFile(previous);
  }

  // --- short-lived native Google OAuth transaction --------------------------
  // Stored so a browser callback still completes if iOS/Android evicts the app while Google is
  // open. The record contains no Google token/password and is deleted after success, error or logout.
  Future<PendingGoogleOAuth?> readPendingGoogleOAuth() async {
    final server = await _s.read(key: _kGoogleServer);
    final state = await _s.read(key: _kGoogleState);
    final verifier = await _s.read(key: _kGoogleVerifier);
    if (server == null || state == null || verifier == null) return null;
    return PendingGoogleOAuth(server: server, state: state, verifier: verifier);
  }

  Future<void> writePendingGoogleOAuth(PendingGoogleOAuth pending) async {
    await _s.write(key: _kGoogleServer, value: pending.server);
    await _s.write(key: _kGoogleState, value: pending.state);
    await _s.write(key: _kGoogleVerifier, value: pending.verifier);
  }

  Future<void> clearPendingGoogleOAuth() async {
    await _s.delete(key: _kGoogleServer);
    await _s.delete(key: _kGoogleState);
    await _s.delete(key: _kGoogleVerifier);
  }

  Future<PendingAppleOAuth?> readPendingAppleOAuth() async {
    final server = await _s.read(key: _kAppleServer);
    final state = await _s.read(key: _kAppleState);
    final verifier = await _s.read(key: _kAppleVerifier);
    if (server == null || state == null || verifier == null) return null;
    return PendingAppleOAuth(server: server, state: state, verifier: verifier);
  }

  Future<void> writePendingAppleOAuth(PendingAppleOAuth pending) async {
    await _s.write(key: _kAppleServer, value: pending.server);
    await _s.write(key: _kAppleState, value: pending.state);
    await _s.write(key: _kAppleVerifier, value: pending.verifier);
  }

  Future<void> clearPendingAppleOAuth() async {
    await _s.delete(key: _kAppleServer);
    await _s.delete(key: _kAppleState);
    await _s.delete(key: _kAppleVerifier);
  }

  /// Logout keeps the revocable biometric grant for the next explicit OS-authorized login.
  Future<void> clearSession() async {
    await clearSessionData();
    await _s.delete(key: _kRefresh);
    await clearPendingGoogleOAuth();
    await clearPendingAppleOAuth();
  }

  Future<void> clearAll() async {
    await clearSession();
    await clearGrant();
  }
}
