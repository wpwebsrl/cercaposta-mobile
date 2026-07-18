import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/auth.dart';
import '../../shared/models/user.dart';
import '../api/api_exception.dart';
import '../background/bg_constants.dart';
import '../providers.dart';
import 'secure_store.dart';

/// One-shot flag raised after a successful MANUAL login when biometric sign-in
/// isn't enabled yet: HomeShell shows the enable offer on its first frame (a
/// dialog on the login screen would be killed by the auth-driven redirect).
final biometricOfferProvider = StateProvider<bool>((ref) => false);

enum AuthStatus {
  unknown,
  loggedOut,
  needsTotp,
  needsPasswordChange, // must_change_password: forced first-password flow (§4.2)
  needsRecovery, // recovery_required: break-glass after an admin reset (§6)
  locked,
  updateRequired, // 426: this app version is below the server's supported floor
  loggedIn,
}

class AuthState {
  const AuthState({
    required this.status,
    this.accessToken,
    this.user,
    this.encStatus = 'none',
    this.dekAvailable = true,
    this.totpToken,
    this.updateMinVersion,
  });

  final AuthStatus status;
  final String? accessToken;
  final UserInfo? user;
  final String encStatus;
  final bool dekAvailable;
  final String? totpToken;
  final String?
  updateMinVersion; // minimum version the server requires (updateRequired state)

  bool get isEncrypted => encStatus == 'active';

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    UserInfo? user,
    String? encStatus,
    bool? dekAvailable,
    String? totpToken,
    String? updateMinVersion,
  }) => AuthState(
    status: status ?? this.status,
    accessToken: accessToken ?? this.accessToken,
    user: user ?? this.user,
    encStatus: encStatus ?? this.encStatus,
    dekAvailable: dekAvailable ?? this.dekAvailable,
    totpToken: totpToken ?? this.totpToken,
    updateMinVersion: updateMinVersion ?? this.updateMinVersion,
  );
}

Map<String, dynamic> _asMap(Object? data) =>
    data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

class AuthController extends Notifier<AuthState> {
  Future<String?>? _refreshing;
  Future<bool>? _autoUnlocking;

  /// Session credentials, RAM ONLY (never storage): the password powers the
  /// silent DEK re-unlock on 423 while the process lives; together with the
  /// username it also feeds the biometric enable flows. The biometric storage
  /// copy is separate (SecureStore), gated by the OS prompt.
  String? _sessionPassword;
  String? _sessionUsername;

  @override
  AuthState build() => const AuthState(status: AuthStatus.unknown);

  Dio get _dio => ref.read(authDioProvider);

  Map<String, dynamic> _deviceFields() {
    final info = ref.read(appInfoProvider);
    return <String, dynamic>{
      'client': info.client,
      'device_name': info.deviceName,
      'app_version': info.version,
    };
  }

  Options _bearer() => Options(
    headers: <String, dynamic>{'Authorization': 'Bearer ${state.accessToken}'},
  );

  /// Single place that decides the post-auth gate, in priority order:
  /// recovery > forced password change > encrypted-and-locked > in.
  AuthStatus _resolveStatus({
    required bool recoveryRequired,
    required bool needsUnlock,
    UserInfo? user,
  }) {
    if (recoveryRequired) return AuthStatus.needsRecovery;
    if (user?.mustChangePassword ?? false) {
      return AuthStatus.needsPasswordChange;
    }
    if (needsUnlock) return AuthStatus.locked;
    return AuthStatus.loggedIn;
  }

  /// Called once at startup: resume the session via the stored refresh token.
  Future<void> bootstrap() async {
    if (ref.read(activeServerProvider) == null) {
      state = const AuthState(status: AuthStatus.loggedOut);
      return;
    }
    final rt = await ref.read(secureStoreProvider).readRefreshToken();
    if (rt == null) {
      state = const AuthState(status: AuthStatus.loggedOut);
      return;
    }
    try {
      final token = await performRefresh();
      if (token == null) return; // 401: _doRefresh already forced the logout
      await _syncEncryption();
    } on Object {
      // Network error at cold start: KEEP the stored credentials (next launch
      // retries) and land on the login screen instead of nuking the session.
      state = const AuthState(status: AuthStatus.loggedOut);
    }
  }

  Future<LoginResult> login(String username, String password) async {
    final Response<dynamic> resp;
    try {
      resp = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, dynamic>{
          'username': username,
          'password': password,
          ..._deviceFields(),
        },
      );
    } on DioException catch (e) {
      // Too old for this server: switch to the mandatory-update screen (state change drives the
      // router) and return an empty result so the login screen shows no error before it unmounts.
      if (handleUpdateRequired(e)) {
        return LoginResult.fromJson(const <String, dynamic>{});
      }
      rethrow;
    }
    final result = LoginResult.fromJson(_asMap(resp.data));
    // Credentials verified (also when 2FA follows): keep them in RAM for silent
    // DEK re-unlocks and for the biometric enable/upgrade after _completeLogin.
    _sessionPassword = password;
    _sessionUsername = username;
    if (result.requiresTotp) {
      state = state.copyWith(
        status: AuthStatus.needsTotp,
        totpToken: result.totpToken,
      );
    } else {
      await _completeLogin(result);
    }
    return result;
  }

  Future<LoginResult> verifyTotp(String code) async {
    final Response<dynamic> resp;
    try {
      resp = await _dio.post<dynamic>(
        '/auth/totp',
        data: <String, dynamic>{
          'totp_token': state.totpToken,
          'code': code,
          ..._deviceFields(),
        },
      );
    } on DioException catch (e) {
      if (handleUpdateRequired(e)) {
        return LoginResult.fromJson(const <String, dynamic>{});
      }
      rethrow;
    }
    final result = LoginResult.fromJson(_asMap(resp.data));
    await _completeLogin(result);
    return result;
  }

  Future<void> _completeLogin(LoginResult r) async {
    if (r.totpSetupRequired) {
      // Admin enforces 2FA but it isn't enrolled yet: enrollment lives on the web.
      // Don't keep the session; the login screen surfaces the dedicated message.
      await forceLogout();
      return;
    }
    final store = ref.read(secureStoreProvider);
    final rt = r.refreshToken;
    if (rt != null) await store.writeRefreshToken(rt);
    // Biometric sign-in housekeeping (RAM credentials exist on manual/biometric
    // logins; a cold-start refresh resume skips all of this):
    // - already enabled → refresh the record (new password after a change, a
    //   different account on this device, legacy unlock-only key → full record);
    // - not enabled → raise the one-shot offer consumed by HomeShell.
    if (_sessionPassword != null && _sessionUsername != null) {
      final server = ref.read(activeServerProvider);
      if (server != null) {
        if (await store.hasSavedPassword) {
          await store.writeCredentials(
            SavedCredentials(
              server: server,
              username: _sessionUsername!,
              password: _sessionPassword!,
            ),
          );
        } else {
          ref.read(biometricOfferProvider.notifier).state = true;
        }
      }
    }
    state = AuthState(
      status: _resolveStatus(
        recoveryRequired: r.recoveryRequired,
        needsUnlock: r.needsUnlock,
        user: r.user,
      ),
      accessToken: r.accessToken,
      user: r.user,
      encStatus: r.encStatus,
      dekAvailable: r.dekAvailable,
    );
  }

  /// Credentials saved for biometric sign-in, but ONLY when they belong to the
  /// active server (multi-server app): elsewhere the button must not appear.
  Future<SavedCredentials?> savedCredentials() async {
    final creds = await ref.read(secureStoreProvider).readCredentials();
    final server = ref.read(activeServerProvider);
    if (creds == null || server == null || creds.server != server) return null;
    return creds;
  }

  /// Biometric sign-in: replay the saved credentials through the normal login.
  /// A rejected password (changed elsewhere) wipes the record so repeated
  /// attempts can never burn brute-force tries — the caller falls back to the
  /// manual form. The OS biometric prompt happens BEFORE this call (UI layer).
  Future<LoginResult> biometricLogin() async {
    final creds = await savedCredentials();
    if (creds == null) throw ApiException('auth.invalid_credentials');
    try {
      return await login(creds.username, creds.password);
    } on Object catch (e) {
      if (ApiException.from(e).code == 'auth.invalid_credentials') {
        await ref.read(secureStoreProvider).clearCredentials();
      }
      rethrow;
    }
  }

  /// Re-derive the DEK after a cold start / expiry. Returns true on success.
  /// A 401 from an EXPIRED access token is transparently retried after one
  /// refresh — only a wrong password surfaces as auth.invalid_credentials.
  Future<bool> unlock(String password, {bool saveForBiometric = false}) async {
    Future<Response<dynamic>> post() => _dio.post<dynamic>(
      '/auth/unlock',
      data: <String, dynamic>{'password': password},
      options: _bearer(),
    );
    Response<dynamic> resp;
    try {
      resp = await post();
    } on DioException catch (e) {
      final code = ApiException.from(e).code;
      if (e.response?.statusCode == 401 && code != 'auth.invalid_credentials') {
        final token = await performRefresh();
        if (token == null) rethrow;
        resp = await post();
      } else {
        rethrow;
      }
    }
    final enc = EncryptionState.fromJson(_asMap(resp.data));
    if (!enc.needsUnlock) {
      _sessionPassword = password; // valid: reuse for silent re-unlocks
      if (saveForBiometric) {
        await _saveBiometricCredentials(password);
      }
      state = state.copyWith(
        status: _resolveStatus(
          recoveryRequired: enc.recoveryRequired,
          needsUnlock: false,
          user: state.user,
        ),
        encStatus: enc.encStatus,
        dekAvailable: true,
      );
      return true;
    }
    return false;
  }

  /// Forced first-login password change (+ DEK bootstrap for pending accounts).
  /// Returns the one-time recovery kit when the server minted one. The status
  /// stays needsPasswordChange until [finishPasswordChange]: flipping it here
  /// would redirect away and kill the kit dialog before the user saved it.
  Future<String?> firstPassword(String newPassword) async {
    final resp = await _dio.post<dynamic>(
      '/auth/first-password',
      data: <String, dynamic>{'new_password': newPassword},
      options: _bearer(),
    );
    final j = _asMap(resp.data);
    final enc = EncryptionState.fromJson(j);
    final kit = j['recovery_secret'];
    _sessionPassword = newPassword; // freshly set: valid for silent unlocks
    state = state.copyWith(
      user: state.user?.copyWith(mustChangePassword: false),
      encStatus: enc.encStatus,
      dekAvailable: enc.dekAvailable,
    );
    return kit is String && kit.isNotEmpty ? kit : null;
  }

  void finishPasswordChange() {
    state = state.copyWith(
      status: _resolveStatus(
        recoveryRequired: false,
        needsUnlock: state.isEncrypted && !state.dekAvailable,
        user: state.user,
      ),
    );
  }

  /// Break-glass after an admin password reset: recovery secret + new password.
  Future<void> recover(String secret, String newPassword) async {
    final resp = await _dio.post<dynamic>(
      '/auth/recovery',
      data: <String, dynamic>{'secret': secret, 'new_password': newPassword},
      options: _bearer(),
    );
    final enc = EncryptionState.fromJson(_asMap(resp.data));
    // Any saved biometric credentials are now stale: drop them so auto-unlock
    // can't burn brute-force attempts with the old password.
    await ref.read(secureStoreProvider).clearCredentials();
    _sessionPassword = newPassword; // the DEK is re-wrapped under it
    state = state.copyWith(
      status: _resolveStatus(
        recoveryRequired: enc.recoveryRequired,
        needsUnlock: enc.needsUnlock,
        user: state.user,
      ),
      encStatus: enc.encStatus,
      dekAvailable: enc.dekAvailable,
    );
  }

  /// Persist the full biometric record (server + username + password). The
  /// username comes from the RAM copy or, for the Settings flow on a resumed
  /// session, from the logged-in user.
  Future<void> _saveBiometricCredentials(String password) async {
    final server = ref.read(activeServerProvider);
    final username = _sessionUsername ?? state.user?.username;
    if (server == null || username == null) return;
    await ref
        .read(secureStoreProvider)
        .writeCredentials(
          SavedCredentials(
            server: server,
            username: username,
            password: password,
          ),
        );
  }

  /// Post-login offer («use Face ID / fingerprint next time?»): the verified
  /// credentials are still in RAM, no re-typing needed.
  Future<void> enableBiometricFromSession() async {
    final pw = _sessionPassword;
    if (pw != null) await _saveBiometricCredentials(pw);
  }

  Future<void> disableBiometric() =>
      ref.read(secureStoreProvider).clearCredentials();

  Future<String?> savedPassword() =>
      ref.read(secureStoreProvider).readPassword();

  /// Serialized refresh: a single in-flight call is shared by concurrent callers.
  /// Returns null when the server REJECTED the token (forced logout already done);
  /// throws ApiException('common.network') on transport failures (session kept).
  Future<String?> performRefresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  /// Proactive keepalive tick (foreground timer / resume): one rotation slides the
  /// refresh-token window AND the server-side DEK TTL, so an open app never hits
  /// "session expired" nor the lock screen from idleness alone. Transport errors
  /// are swallowed (the next tick retries); a REJECTED token has already forced
  /// the logout inside [performRefresh].
  Future<void> keepaliveTick() async {
    if (state.accessToken == null) return;
    try {
      await performRefresh();
    } on Object {
      // network blip: ignore, the next tick retries
    }
  }

  /// Resume hook (docs/notifiche.md → §4.6): before doing our own keepalive refresh, adopt any
  /// tokens the background notification isolate rotated while we were away — otherwise we'd refresh
  /// with a token it already rotated and race it. The backend's 60s reuse grace keeps even a rare
  /// race benign, but adopting avoids it entirely (and a redundant rotation).
  Future<void> onResume() async {
    if (state.accessToken == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    // Mark the foreground active NOW so an about-to-fire background isolate stands down.
    await prefs.setInt(kBgHeartbeatMs, DateTime.now().millisecondsSinceEpoch);
    if (await _adoptBackgroundTokens(prefs)) return; // session already fresh → no refresh
    await keepaliveTick();
  }

  Future<bool> _adoptBackgroundTokens(SharedPreferences prefs) async {
    try {
      await prefs.reload(); // the flag/token were written from another isolate
    } on Object {
      return false;
    }
    if (!(prefs.getBool(kBgRotated) ?? false)) return false;
    final store = ref.read(secureStoreProvider);
    final access = await store.readBackgroundAccessToken();
    await store.clearBackgroundAccessToken();
    await prefs.setBool(kBgRotated, false);
    if (access == null || access.isEmpty) return false;
    // The refresh token on disk is already the fresh one the isolate wrote; adopt the matching
    // access token so the next request doesn't 401 into a redundant, racing refresh.
    state = state.copyWith(accessToken: access);
    return true;
  }

  /// Silent DEK re-unlock with the RAM-held session password (single-flight).
  /// Returns true when the vault holds the DEK again → the 423'd call can retry.
  /// A stale password (changed elsewhere) is forgotten immediately so repeated
  /// 423s can never hammer the failed-login counter and lock the account.
  Future<bool> tryAutoUnlock() {
    return _autoUnlocking ??= _doAutoUnlock().whenComplete(
      () => _autoUnlocking = null,
    );
  }

  Future<bool> _doAutoUnlock() async {
    final pw = _sessionPassword;
    if (pw == null || state.accessToken == null) return false;
    try {
      final ok = await unlock(pw);
      if (!ok) _sessionPassword = null; // accepted but wrap stale (recovery)
      return ok;
    } on DioException catch (e) {
      if (ApiException.from(e).code == 'auth.invalid_credentials') {
        _sessionPassword = null;
      }
      return false;
    } on ApiException {
      return false; // network during the embedded refresh: retry another time
    }
  }

  Future<String?> _doRefresh() async {
    final store = ref.read(secureStoreProvider);
    final rt = await store.readRefreshToken();
    if (rt == null) {
      await forceLogout();
      return null;
    }
    final Response<dynamic> resp;
    try {
      resp = await _dio.post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{
          'refresh_token': rt,
          // Re-declare the CURRENT version each refresh so the server re-checks it against the
          // compatibility floor (e.g. after a store update) and refreshes the stored value.
          'app_version': ref.read(appInfoProvider).version,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 426) {
        // Below the supported floor. The server rolled back the rotation, so the token is
        // intact: don't log out — route to the mandatory-update screen and keep the session.
        handleUpdateRequired(e);
        return null;
      }
      if (e.response?.statusCode == 401) {
        // The server rejected the token (rotated/revoked/expired): forced logout.
        await forceLogout();
        return null;
      }
      // Network / 5xx / captive portal: do NOT destroy the session — propagate.
      throw ApiException.from(e);
    }
    final pair = TokenPair.fromJson(_asMap(resp.data));
    if (pair.accessToken.isEmpty || pair.refreshToken.isEmpty) {
      // 200 with a non-token body (captive portal, misrouted proxy): keep the
      // stored token instead of overwriting it with garbage.
      throw ApiException('common.network');
    }
    await store.writeRefreshToken(pair.refreshToken);
    state = state.copyWith(
      status: state.status == AuthStatus.unknown
          ? _resolveStatus(
              recoveryRequired: false,
              needsUnlock: false,
              user: pair.user,
            )
          : null,
      accessToken: pair.accessToken,
      user: pair.user,
    );
    return pair.accessToken;
  }

  Future<void> _syncEncryption() async {
    if (state.accessToken == null) return;
    try {
      final resp = await _dio.get<dynamic>(
        '/me/encryption',
        options: _bearer(),
      );
      final enc = EncryptionState.fromJson(_asMap(resp.data));
      state = state.copyWith(
        status: _resolveStatus(
          recoveryRequired: enc.recoveryRequired,
          needsUnlock: enc.needsUnlock,
          user: state.user,
        ),
        encStatus: enc.encStatus,
        dekAvailable: enc.dekAvailable,
      );
    } on DioException {
      // Offline right after a successful refresh: optimistically resolved; a
      // later 423/401 re-routes via the interceptor.
      state = state.copyWith(
        status: _resolveStatus(
          recoveryRequired: false,
          needsUnlock: false,
          user: state.user,
        ),
      );
    }
  }

  /// A request returned 426: this app version is below the server's supported floor.
  /// Route to the mandatory-update screen (keeps the session; nothing to log out of).
  /// Returns true when [e] was a 426 (so callers can stop their normal flow).
  bool handleUpdateRequired(DioException e) {
    if (e.response?.statusCode != 426) return false;
    final data = _asMap(e.response?.data);
    final err = _asMap(data['error']);
    final params = _asMap(err['params']);
    final min = params['min'];
    enterUpdateRequired(min: min is String ? min : null);
    return true;
  }

  void enterUpdateRequired({String? min}) {
    if (state.status == AuthStatus.updateRequired) return;
    state = state.copyWith(
      status: AuthStatus.updateRequired,
      updateMinVersion: min,
    );
  }

  /// Content access returned 423: the DEK expired server-side. A 423 can only
  /// come from an encrypted account, so trust it even before /me/encryption ran.
  void markLocked() {
    if (state.accessToken != null) {
      state = state.copyWith(
        status: AuthStatus.locked,
        encStatus: 'active',
        dekAvailable: false,
      );
    }
  }

  Future<void> logout() async {
    final store = ref.read(secureStoreProvider);
    final rt = await store.readRefreshToken();
    if (rt != null) {
      try {
        await _dio.post<dynamic>(
          '/auth/logout',
          data: <String, dynamic>{'refresh_token': rt},
        );
      } on DioException {
        // best effort
      }
    }
    await forceLogout();
  }

  Future<void> forceLogout() async {
    _sessionPassword = null;
    _sessionUsername = null;
    // Drop the session only: the biometric credentials must SURVIVE logout,
    // revocation and expiry — those are exactly the moments the login screen
    // reappears and Face ID / fingerprint is supposed to help. They are wiped
    // by the Settings toggle, a rejected password, or the recovery flow.
    final store = ref.read(secureStoreProvider);
    await store.clearSession();
    // Reset the background notification state so the NEXT session re-baselines instead of diffing
    // against another user's ids. The periodic task keeps running but self-guards on the now-absent
    // refresh token (no-op), and resumes cleanly on the next login. Best-effort (D10).
    await _resetBackgroundNotifications(store);
    state = const AuthState(status: AuthStatus.loggedOut);
  }

  Future<void> _resetBackgroundNotifications(SecureStore store) async {
    try {
      await store.clearBackgroundAccessToken();
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(kBgRotated);
      await prefs.remove(kBgSeenIds);
      await prefs.remove(kBgBaselineMs);
      await prefs.remove(kBgLastRev);
      await prefs.remove(kBgRefreshStartedMs);
    } on Object {
      // ignore
    }
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Identity of the logged-in session: active server + user id (null when
/// logged out). Content caches (search results, folder tree/scope, chat)
/// MUST `ref.watch` this so they reset on logout/user switch/server switch —
/// otherwise user B sees user A's data on a shared device. Selecting only the
/// id keeps token refreshes (same user) from wiping state.
final sessionKeyProvider = Provider<String?>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  final server = ref.watch(activeServerProvider);
  return userId == null ? null : '$server::$userId';
});
