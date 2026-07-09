import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Credentials saved for biometric sign-in, bound to the server they belong to
/// (multi-server app: the button only shows when the active server matches).
class SavedCredentials {
  const SavedCredentials({
    required this.server,
    required this.username,
    required this.password,
  });

  final String server;
  final String username;
  final String password;
}

/// Hardware-backed storage for the refresh token and (optionally, behind the OS
/// biometric prompt) the login credentials. NEVER stores the DEK or the access
/// token. Single active session model: one refresh token at a time.
///
/// Biometric secret layout: the full (server, username, password) record powers
/// BOTH the biometric login and the DEK unlock. The legacy `unlock_password` key
/// (password only, pre-biometric-login builds) keeps working for the unlock and
/// is upgraded to the full record on the next successful manual login.
class SecureStore {
  SecureStore()
    : _s = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  final FlutterSecureStorage _s;

  static const _kRefresh = 'refresh_token';
  static const _kPassword = 'unlock_password'; // legacy, unlock-only
  static const _kCredServer = 'cred_server';
  static const _kCredUsername = 'cred_username';
  static const _kCredPassword = 'cred_password';

  Future<String?> readRefreshToken() => _s.read(key: _kRefresh);
  Future<void> writeRefreshToken(String token) =>
      _s.write(key: _kRefresh, value: token);
  Future<void> clearRefreshToken() => _s.delete(key: _kRefresh);

  // --- biometric credentials -------------------------------------------------
  Future<SavedCredentials?> readCredentials() async {
    final server = await _s.read(key: _kCredServer);
    final username = await _s.read(key: _kCredUsername);
    final password = await _s.read(key: _kCredPassword);
    if (server == null || username == null || password == null) return null;
    return SavedCredentials(
      server: server,
      username: username,
      password: password,
    );
  }

  Future<void> writeCredentials(SavedCredentials c) async {
    await _s.write(key: _kCredServer, value: c.server);
    await _s.write(key: _kCredUsername, value: c.username);
    await _s.write(key: _kCredPassword, value: c.password);
    // the full record supersedes the legacy unlock-only key
    await _s.delete(key: _kPassword);
  }

  Future<void> clearCredentials() async {
    await _s.delete(key: _kCredServer);
    await _s.delete(key: _kCredUsername);
    await _s.delete(key: _kCredPassword);
    await _s.delete(key: _kPassword);
  }

  /// Password for the biometric DEK unlock: the full record when present,
  /// otherwise the legacy unlock-only key.
  Future<String?> readPassword() async =>
      (await _s.read(key: _kCredPassword)) ?? await _s.read(key: _kPassword);

  Future<bool> get hasSavedPassword async => (await readPassword()) != null;

  /// Legacy unlock-only secret present but no full record yet: biometric login
  /// unavailable until the next manual login upgrades it.
  Future<bool> get hasLegacyPasswordOnly async =>
      (await _s.read(key: _kCredPassword)) == null &&
      (await _s.read(key: _kPassword)) != null;

  /// Logout / forced logout: drop the session but KEEP the biometric credentials
  /// — they exist precisely to survive the moments the login screen reappears
  /// (logout, revoked session, 60-day expiry). They are wiped only by the
  /// Settings toggle, a wrong saved password, or the recovery flow.
  Future<void> clearSession() => _s.delete(key: _kRefresh);

  Future<void> clearAll() async {
    await clearSession();
    await clearCredentials();
  }
}
