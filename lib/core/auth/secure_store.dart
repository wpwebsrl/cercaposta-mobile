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

  /// Logout / forced logout: drop the session but KEEP the biometric credentials
  /// — they exist precisely to survive the moments the login screen reappears
  /// (logout, revoked session, 60-day expiry). They are wiped only by the
  /// Settings toggle, a wrong saved password, or the recovery flow.
  Future<void> clearSession() async {
    await _s.delete(key: _kRefresh);
    await clearPendingGoogleOAuth();
    await clearPendingAppleOAuth();
  }

  Future<void> clearAll() async {
    await clearSession();
    await clearCredentials();
  }
}
