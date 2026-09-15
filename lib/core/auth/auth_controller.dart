import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/models/auth.dart';
import '../../shared/models/passkey.dart';
import '../../shared/models/user.dart';
import '../api/api_exception.dart';
import '../background/bg_constants.dart';
import '../providers.dart';
import '../notify/notify_service.dart';
import 'secure_store.dart';
import 'device_grant.dart';
import 'passkey_policy.dart';

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
    this.sessionId = 0,
  });

  final AuthStatus status;
  final String? accessToken;
  final UserInfo? user;
  final String encStatus;
  final bool dekAvailable;
  final String? totpToken;
  final int sessionId;
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
    sessionId: sessionId,
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
  /// grant is separate and requires OS authorization for every secret read.
  String? _sessionPassword;
  String? _biometricLoginUserId;
  int _generation = 0;
  bool _disposed = false;
  Future<void> _storageTail = Future<void>.value();

  @override
  AuthState build() {
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    ref.listen(activeServerProvider, (previous, next) {
      if (previous != next) {
        _generation++;
        _sessionPassword = null;
        _biometricLoginUserId = null;
        _refreshing = null;
        _autoUnlocking = null;
        state = AuthState(status: AuthStatus.loggedOut, sessionId: _generation);
      }
    });
    return const AuthState(status: AuthStatus.unknown);
  }

  /// Stable across refresh; replaced on login/logout or server change.
  String get requestIdentity =>
      '$_generation::${ref.read(activeServerProvider)}';

  bool isCurrent(String expected) => !_disposed && requestIdentity == expected;

  void requireIdentity(String expected) {
    if (!isCurrent(expected)) throw ApiException('auth.session_changed');
  }

  String _beginLogin() {
    _generation++;
    _sessionPassword = null;
    _biometricLoginUserId = null;
    _refreshing = null;
    _autoUnlocking = null;
    state = AuthState(status: AuthStatus.loggedOut, sessionId: _generation);
    return requestIdentity;
  }

  Future<T> _guard<T>(String expected, Future<T> Function() operation) async {
    requireIdentity(expected);
    try {
      final result = await operation();
      requireIdentity(expected);
      return result;
    } on Object {
      requireIdentity(expected);
      rethrow;
    }
  }

  /// Serializes foreground storage mutations and revalidates before execution.
  Future<T> _persist<T>(String expected, Future<T> Function() operation) {
    final result = _storageTail.then((_) => _guard(expected, operation));
    _storageTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Dio get _dio => ref.read(authDioProvider);

  String _randomBase64Url(int byteCount) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteCount, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

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
    final expected = requestIdentity;
    final server = ref.read(activeServerProvider);
    await _persist(
      expected,
      () => ref.read(secureStoreProvider).purgeLegacyPasswords(),
    );
    if (server == null) {
      state = const AuthState(status: AuthStatus.loggedOut);
      return;
    }
    try {
      await _persist(
        expected,
        () => ref.read(sessionCoordinatorProvider).migrateLegacy(server),
      );
      final token = await performRefresh();
      if (token == null || !isCurrent(expected)) return;
      await _syncEncryption();
    } on Object {
      if (isCurrent(expected)) {
        state = const AuthState(status: AuthStatus.loggedOut);
      }
    }
  }

  Future<LoginResult> login(String username, String password) async {
    final expected = _beginLogin();
    await _persist(
      expected,
      () => ref
          .read(sessionCoordinatorProvider)
          .clear(
            afterClear: () =>
                _resetBackgroundNotifications(ref.read(secureStoreProvider)),
          ),
    );
    final Response<dynamic> resp;
    try {
      resp = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/login',
          data: <String, dynamic>{
            'username': username,
            'password': password,
            ..._deviceFields(),
          },
        ),
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

  /// Passwordless native login. The operating system selects a discoverable
  /// credential and proves user presence/verification; no private key leaves
  /// the device or its passkey provider.
  Future<LoginResult> passkeyLogin() async {
    requirePasskeyServer(
      ref.read(appInfoProvider).client,
      ref.read(activeServerProvider),
    );
    final expected = _beginLogin();
    await _persist(
      expected,
      () => ref
          .read(sessionCoordinatorProvider)
          .clear(
            afterClear: () =>
                _resetBackgroundNotifications(ref.read(secureStoreProvider)),
          ),
    );
    final optionsResponse = await _guard(
      expected,
      () => _dio.post<dynamic>('/auth/passkeys/options', data: _deviceFields()),
    );
    final options = _asMap(optionsResponse.data);
    requirePasskeyServer(
      ref.read(appInfoProvider).client,
      ref.read(activeServerProvider),
      rpId: _asMap(options['public_key'])['rpId'] as String? ?? '',
    );
    final request = AuthenticateRequestType.fromJsonString(
      jsonEncode(_asMap(options['public_key'])),
    );
    final authenticator = PasskeyAuthenticator();
    final assertion = await _guard(
      expected,
      () => authenticator.authenticate(request),
    );
    final verifyResponse = await _guard(
      expected,
      () => _dio.post<dynamic>(
        '/auth/passkeys/verify',
        data: <String, dynamic>{
          'flow_id': options['flow_id'],
          'credential': jsonDecode(assertion.toJsonString()),
        },
      ),
    );
    final result = LoginResult.fromJson(_asMap(verifyResponse.data));
    _sessionPassword = null;
    _biometricLoginUserId = null;
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

  /// Native Google sign-in via the system browser. The backend remains the sole OAuth client:
  /// Google credentials/tokens never enter this app. The one-shot CercaPosta code is protected by
  /// PKCE and the verifier is kept in Keychain/Keystore so a cold-start callback is recoverable.
  Future<LoginResult> googleLogin() async {
    final expected = _beginLogin();
    await _persist(
      expected,
      () => ref
          .read(sessionCoordinatorProvider)
          .clear(
            afterClear: () =>
                _resetBackgroundNotifications(ref.read(secureStoreProvider)),
          ),
    );
    final server = ref.read(activeServerProvider);
    if (server == null) throw ApiException('common.generic');
    final stateToken = _randomBase64Url(32);
    final verifier = _randomBase64Url(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final pending = PendingGoogleOAuth(
      server: server,
      state: stateToken,
      verifier: verifier,
    );
    final store = ref.read(secureStoreProvider);
    await _persist(expected, () => store.writePendingGoogleOAuth(pending));
    try {
      final response = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/google/native/start',
          data: <String, dynamic>{
            'callback_url': 'it.cercaposta.app://oauth/google',
            'state': stateToken,
            'code_challenge': challenge,
            'language': state.user?.language ?? 'it',
            ..._deviceFields(),
          },
        ),
      );
      final data = _asMap(response.data);
      final rawUrl = data['authorization_url'];
      if (rawUrl is! String || rawUrl.isEmpty) {
        throw ApiException('google.unavailable');
      }
      final opened = await _guard(
        expected,
        () =>
            launchUrl(Uri.parse(rawUrl), mode: LaunchMode.externalApplication),
      );
      if (!opened) throw ApiException('google.browser_open_failed');
      final callback = await _guard(
        expected,
        () => ref.read(googleOAuthBridgeProvider).waitForState(stateToken),
      );
      return await _completeGoogleCallback(callback, pending);
    } on Object {
      await _persist(expected, () => store.clearPendingGoogleOAuth());
      rethrow;
    }
  }

  /// Finish a callback that launched a fresh process after the OS evicted the app in the browser.
  Future<LoginResult?> resumeGoogleLogin() async {
    final expected = requestIdentity;
    final callback = ref.read(googleOAuthBridgeProvider).takeInitial();
    if (callback == null) return null;
    final pending = await _guard(
      expected,
      () => ref.read(secureStoreProvider).readPendingGoogleOAuth(),
    );
    if (pending == null || pending.server != ref.read(activeServerProvider)) {
      return null;
    }
    if (callback.queryParameters['state'] != pending.state) {
      await _persist(
        expected,
        () => ref.read(secureStoreProvider).clearPendingGoogleOAuth(),
      );
      throw ApiException('google.code_invalid');
    }
    return _completeGoogleCallback(callback, pending);
  }

  Future<LoginResult> _completeGoogleCallback(
    Uri callback,
    PendingGoogleOAuth pending,
  ) async {
    final expected = requestIdentity;
    final store = ref.read(secureStoreProvider);
    try {
      if (callback.queryParameters['state'] != pending.state) {
        throw ApiException('google.code_invalid');
      }
      final providerError = callback.queryParameters['oauth_error'];
      if (providerError != null && providerError.isNotEmpty) {
        throw ApiException('google.$providerError');
      }
      final code = callback.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw ApiException('google.code_invalid');
      }
      final Response<dynamic> response;
      try {
        response = await _guard(
          expected,
          () => _dio.post<dynamic>(
            '/auth/google/exchange',
            data: <String, dynamic>{
              'code': code,
              'code_verifier': pending.verifier,
            },
          ),
        );
      } on DioException catch (e) {
        if (handleUpdateRequired(e)) {
          return LoginResult.fromJson(const <String, dynamic>{});
        }
        rethrow;
      }
      final result = LoginResult.fromJson(_asMap(response.data));
      _sessionPassword = null;
      _biometricLoginUserId = null;
      if (result.requiresTotp) {
        state = state.copyWith(
          status: AuthStatus.needsTotp,
          totpToken: result.totpToken,
        );
      } else {
        await _completeLogin(result);
      }
      return result;
    } finally {
      await _persist(expected, () => store.clearPendingGoogleOAuth());
    }
  }

  /// Sign in with Apple is native on iOS and a system-browser PKCE flow on Android.
  Future<LoginResult> appleLogin() async {
    if (Platform.isIOS) return _appleNativeLogin();
    return _appleBrowserLogin();
  }

  Future<LoginResult> _appleNativeLogin() async {
    final expected = _beginLogin();
    await _persist(
      expected,
      () => ref
          .read(sessionCoordinatorProvider)
          .clear(
            afterClear: () =>
                _resetBackgroundNotifications(ref.read(secureStoreProvider)),
          ),
    );
    final stateToken = _randomBase64Url(32);
    final optionsResponse = await _guard(
      expected,
      () => _dio.post<dynamic>(
        '/auth/apple/native/options',
        data: <String, dynamic>{
          'state': stateToken,
          'language': state.user?.language ?? 'it',
          ..._deviceFields(),
        },
      ),
    );
    final options = _asMap(optionsResponse.data);
    final flowId = options['flow_id'];
    final rawNonce = options['nonce'];
    if (flowId is! String || rawNonce is! String) {
      throw ApiException('apple.unavailable');
    }
    try {
      final credential = await _guard(
        expected,
        () => SignInWithApple.getAppleIDCredential(
          scopes: const <AppleIDAuthorizationScopes>[
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
          state: stateToken,
        ),
      );
      if (credential.state != null && credential.state != stateToken) {
        throw ApiException('apple.state');
      }
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw ApiException('apple.identity');
      }
      final response = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/apple/native/verify',
          data: <String, dynamic>{
            'flow_id': flowId,
            'state': stateToken,
            'authorization_code': credential.authorizationCode,
            'identity_token': identityToken,
            'given_name': credential.givenName ?? '',
            'family_name': credential.familyName ?? '',
          },
        ),
      );
      final result = LoginResult.fromJson(_asMap(response.data));
      _sessionPassword = null;
      _biometricLoginUserId = null;
      if (result.requiresTotp) {
        state = state.copyWith(
          status: AuthStatus.needsTotp,
          totpToken: result.totpToken,
        );
      } else {
        await _completeLogin(result);
      }
      return result;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw ApiException('apple.cancelled');
      }
      throw ApiException('apple.unavailable');
    }
  }

  Future<LoginResult> _appleBrowserLogin() async {
    final expected = _beginLogin();
    await _persist(
      expected,
      () => ref
          .read(sessionCoordinatorProvider)
          .clear(
            afterClear: () =>
                _resetBackgroundNotifications(ref.read(secureStoreProvider)),
          ),
    );
    final server = ref.read(activeServerProvider);
    if (server == null) throw ApiException('common.generic');
    final stateToken = _randomBase64Url(32);
    final verifier = _randomBase64Url(64);
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    final pending = PendingAppleOAuth(
      server: server,
      state: stateToken,
      verifier: verifier,
    );
    final store = ref.read(secureStoreProvider);
    await _persist(expected, () => store.writePendingAppleOAuth(pending));
    try {
      final response = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/apple/native/start',
          data: <String, dynamic>{
            'callback_url': 'it.cercaposta.app://oauth/apple',
            'state': stateToken,
            'code_challenge': challenge,
            'language': state.user?.language ?? 'it',
            ..._deviceFields(),
          },
        ),
      );
      final rawUrl = _asMap(response.data)['authorization_url'];
      if (rawUrl is! String || rawUrl.isEmpty) {
        throw ApiException('apple.unavailable');
      }
      final opened = await _guard(
        expected,
        () =>
            launchUrl(Uri.parse(rawUrl), mode: LaunchMode.externalApplication),
      );
      if (!opened) throw ApiException('apple.browser_open_failed');
      final callback = await _guard(
        expected,
        () => ref.read(appleOAuthBridgeProvider).waitForState(stateToken),
      );
      return await _completeAppleCallback(callback, pending);
    } on Object {
      await _persist(expected, () => store.clearPendingAppleOAuth());
      rethrow;
    }
  }

  Future<LoginResult?> resumeAppleLogin() async {
    final expected = requestIdentity;
    if (Platform.isIOS) return null;
    final callback = ref.read(appleOAuthBridgeProvider).takeInitial();
    if (callback == null) return null;
    final pending = await _guard(
      expected,
      () => ref.read(secureStoreProvider).readPendingAppleOAuth(),
    );
    if (pending == null || pending.server != ref.read(activeServerProvider)) {
      return null;
    }
    if (callback.queryParameters['state'] != pending.state) {
      await _persist(
        expected,
        () => ref.read(secureStoreProvider).clearPendingAppleOAuth(),
      );
      throw ApiException('apple.code_invalid');
    }
    return _completeAppleCallback(callback, pending);
  }

  Future<LoginResult> _completeAppleCallback(
    Uri callback,
    PendingAppleOAuth pending,
  ) async {
    final expected = requestIdentity;
    final store = ref.read(secureStoreProvider);
    try {
      if (callback.queryParameters['state'] != pending.state) {
        throw ApiException('apple.code_invalid');
      }
      final providerError = callback.queryParameters['oauth_error'];
      if (providerError != null && providerError.isNotEmpty) {
        throw ApiException('apple.$providerError');
      }
      final code = callback.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw ApiException('apple.code_invalid');
      }
      final response = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/apple/exchange',
          data: <String, dynamic>{
            'code': code,
            'code_verifier': pending.verifier,
          },
        ),
      );
      final result = LoginResult.fromJson(_asMap(response.data));
      _sessionPassword = null;
      _biometricLoginUserId = null;
      if (result.requiresTotp) {
        state = state.copyWith(
          status: AuthStatus.needsTotp,
          totpToken: result.totpToken,
        );
      } else {
        await _completeLogin(result);
      }
      return result;
    } finally {
      await _persist(expected, () => store.clearPendingAppleOAuth());
    }
  }

  Future<List<PasskeyInfo>> listPasskeys() async {
    final expected = requestIdentity;
    final response = await _guard(
      expected,
      () => _dio.get<dynamic>('/me/passkeys', options: _bearer()),
    );
    final rows = response.data;
    if (rows is! List) return const <PasskeyInfo>[];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PasskeyInfo.fromJson)
        .toList(growable: false);
  }

  Future<PasskeyInfo> registerPasskey(String name) async {
    requirePasskeyServer(
      ref.read(appInfoProvider).client,
      ref.read(activeServerProvider),
    );
    final expected = requestIdentity;
    final optionsResponse = await _guard(
      expected,
      () => _dio.post<dynamic>(
        '/me/passkeys/options',
        data: _deviceFields(),
        options: _bearer(),
      ),
    );
    final options = _asMap(optionsResponse.data);
    requirePasskeyServer(
      ref.read(appInfoProvider).client,
      ref.read(activeServerProvider),
      rpId: _asMap(_asMap(options['public_key'])['rp'])['id'] as String? ?? '',
    );
    final request = RegisterRequestType.fromJsonString(
      jsonEncode(_asMap(options['public_key'])),
    );
    final authenticator = PasskeyAuthenticator();
    final attestation = await _guard(
      expected,
      () => authenticator.register(request),
    );
    final response = await _guard(
      expected,
      () => _dio.post<dynamic>(
        '/me/passkeys',
        data: <String, dynamic>{
          'flow_id': options['flow_id'],
          'credential': jsonDecode(attestation.toJsonString()),
          'name': name,
        },
        options: _bearer(),
      ),
    );
    return PasskeyInfo.fromJson(_asMap(response.data));
  }

  Future<PasskeyInfo> renamePasskey(String id, String name) async {
    final expected = requestIdentity;
    final response = await _guard(
      expected,
      () => _dio.patch<dynamic>(
        '/me/passkeys/$id',
        data: <String, dynamic>{'name': name},
        options: _bearer(),
      ),
    );
    return PasskeyInfo.fromJson(_asMap(response.data));
  }

  Future<void> deletePasskey(String id) async {
    final expected = requestIdentity;
    await _guard(
      expected,
      () => _dio.delete<dynamic>('/me/passkeys/$id', options: _bearer()),
    );
  }

  Future<LoginResult> verifyTotp(String code) async {
    final expected = requestIdentity;
    final Response<dynamic> resp;
    try {
      resp = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/totp',
          data: <String, dynamic>{
            'totp_token': state.totpToken,
            'code': code,
            ..._deviceFields(),
          },
        ),
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
    final expected = requestIdentity;
    if (r.totpSetupRequired) {
      // Admin enforces 2FA but it isn't enrolled yet: enrollment lives on the web.
      // Don't keep the session; the login screen surfaces the dedicated message.
      await forceLogout();
      return;
    }
    final store = ref.read(secureStoreProvider);
    if (_biometricLoginUserId != null && r.user?.id != _biometricLoginUserId) {
      throw ApiException('auth.session_changed');
    }
    final rt = r.refreshToken;
    if (rt == null ||
        rt.isEmpty ||
        r.accessToken == null ||
        r.accessToken!.isEmpty ||
        r.user == null ||
        r.user!.id.isEmpty) {
      throw ApiException('common.network');
    }
    await _persist(
      expected,
      () => ref
          .read(sessionCoordinatorProvider)
          .install(
            server: ref.read(activeServerProvider)!,
            userId: r.user!.id,
            refreshToken: rt,
            accessToken: r.accessToken!,
          ),
    );
    // Optional offer uses metadata only; storage failures cannot invalidate login.
    if (_sessionPassword != null) {
      try {
        final saved = await _guard(expected, () => store.readGrantInfo());
        if (saved?.server != ref.read(activeServerProvider) ||
            saved?.userId != r.user?.id) {
          ref.read(biometricOfferProvider.notifier).state = true;
        }
      } on Object {
        requireIdentity(expected);
      }
    }
    state = AuthState(
      status: _resolveStatus(
        recoveryRequired: r.recoveryRequired,
        needsUnlock: r.needsUnlock,
        user: r.user,
      ),
      accessToken: r.accessToken,
      sessionId: _generation,
      user: r.user,
      encStatus: r.encStatus,
      dekAvailable: r.dekAvailable,
    );
  }

  Future<DeviceGrantInfo?> savedGrantInfo() async {
    final expected = requestIdentity;
    final info = await _guard(
      expected,
      () => ref.read(secureStoreProvider).readGrantInfo(),
    );
    return info?.server == ref.read(activeServerProvider) ? info : null;
  }

  Future<bool> hasBiometricForCurrentUser() async {
    final expected = requestIdentity;
    final info = await savedGrantInfo();
    requireIdentity(expected);
    return info != null && info.userId == state.user?.id;
  }

  Future<DeviceGrant> _readBiometric({
    required String reason,
    required String cancel,
    required bool currentUser,
  }) async {
    final expected = requestIdentity;
    final info = await savedGrantInfo();
    requireIdentity(expected);
    if (info == null || (currentUser && info.userId != state.user?.id)) {
      throw ApiException('biometric.reenroll');
    }
    return _guard(
      expected,
      () => ref
          .read(secureStoreProvider)
          .readGrant(info, reason: reason, cancel: cancel),
    );
  }

  Future<void> _forgetRejectedGrant(Object error, String expected) async {
    final code = ApiException.from(error).code;
    if (isCurrent(expected) &&
        (code == 'trusted_device.not_available' ||
            code == 'biometric.reenroll')) {
      await _persist(
        expected,
        () => ref.read(secureStoreProvider).clearGrant(),
      );
    }
  }

  /// The native read performs the biometric operation. No UI-only boolean authorizes login.
  Future<LoginResult> biometricLogin({
    required String reason,
    required String cancel,
  }) async {
    var expected = requestIdentity;
    try {
      final grant = await _readBiometric(
        reason: reason,
        cancel: cancel,
        currentUser: false,
      );
      requireIdentity(expected);
      expected = _beginLogin();
      _biometricLoginUserId = grant.info.userId;
      await _persist(
        expected,
        () => ref
            .read(sessionCoordinatorProvider)
            .clear(
              afterClear: () =>
                  _resetBackgroundNotifications(ref.read(secureStoreProvider)),
            ),
      );
      final response = await _guard(
        expected,
        () => _dio.post<dynamic>(
          '/auth/mobile-device/login',
          data: <String, dynamic>{...grant.credential, ..._deviceFields()},
        ),
      );
      final result = LoginResult.fromJson(_asMap(response.data));
      if (result.requiresTotp) {
        state = state.copyWith(
          status: AuthStatus.needsTotp,
          totpToken: result.totpToken,
        );
      } else {
        await _completeLogin(result);
      }
      return result;
    } on Object catch (error) {
      if (error is DioException &&
          isCurrent(expected) &&
          handleUpdateRequired(error)) {
        return LoginResult.fromJson(const <String, dynamic>{});
      }
      await _forgetRejectedGrant(error, expected);
      rethrow;
    }
  }

  Future<bool> biometricUnlock({
    required String reason,
    required String cancel,
  }) async {
    final expected = requestIdentity;
    try {
      final grant = await _readBiometric(
        reason: reason,
        cancel: cancel,
        currentUser: true,
      );
      Future<Response<dynamic>> post() => _dio.post<dynamic>(
        '/auth/trusted-device/unlock',
        data: grant.credential,
        options: _bearer(),
      );
      Response<dynamic> response;
      try {
        response = await _guard(expected, post);
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) rethrow;
        if (await _guard(expected, performRefresh) == null) rethrow;
        response = await _guard(expected, post);
      }
      final enc = EncryptionState.fromJson(_asMap(response.data));
      state = state.copyWith(
        status: _resolveStatus(
          recoveryRequired: enc.recoveryRequired,
          needsUnlock: enc.needsUnlock,
          user: state.user,
        ),
        encStatus: enc.encStatus,
        dekAvailable: enc.dekAvailable,
      );
      return !enc.needsUnlock;
    } on Object catch (error) {
      await _forgetRejectedGrant(error, expected);
      rethrow;
    }
  }

  /// Re-derive the DEK after a cold start / expiry. Returns true on success.
  /// A 401 from an EXPIRED access token is transparently retried after one
  /// refresh — only a wrong password surfaces as auth.invalid_credentials.
  Future<bool> unlock(String password) async {
    final expected = requestIdentity;
    Future<Response<dynamic>> post() => _dio.post<dynamic>(
      '/auth/unlock',
      data: <String, dynamic>{'password': password},
      options: _bearer(),
    );
    Response<dynamic> resp;
    try {
      resp = await _guard(expected, () => post());
    } on DioException catch (e) {
      final code = ApiException.from(e).code;
      if (e.response?.statusCode == 401 && code != 'auth.invalid_credentials') {
        final token = await _guard(expected, () => performRefresh());
        if (token == null) rethrow;
        resp = await _guard(expected, () => post());
      } else {
        rethrow;
      }
    }
    final enc = EncryptionState.fromJson(_asMap(resp.data));
    if (!enc.needsUnlock) {
      _sessionPassword = password; // valid: reuse for silent re-unlocks
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
    final expected = requestIdentity;
    final resp = await _guard(
      expected,
      () => _dio.post<dynamic>(
        '/auth/first-password',
        data: <String, dynamic>{'new_password': newPassword},
        options: _bearer(),
      ),
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
    final expected = requestIdentity;
    final resp = await _guard(
      expected,
      () => _dio.post<dynamic>(
        '/auth/recovery',
        data: <String, dynamic>{'secret': secret, 'new_password': newPassword},
        options: _bearer(),
      ),
    );
    final enc = EncryptionState.fromJson(_asMap(resp.data));
    // Any saved biometric credentials are now stale: drop them so auto-unlock
    // can't burn brute-force attempts with the old password.
    await _persist(expected, () => ref.read(secureStoreProvider).clearGrant());
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

  Future<void> _saveBiometricGrant({
    String? password,
    required String reason,
    required String cancel,
  }) async {
    final expected = requestIdentity;
    final server = ref.read(activeServerProvider);
    final user = state.user;
    if (server == null || user == null) {
      throw ApiException('auth.reauthentication_required');
    }
    final store = ref.read(secureStoreProvider);
    final dio = _dio;
    final bearer = _bearer();
    final response = await dio.post<dynamic>(
      '/auth/mobile-device/enroll',
      data: <String, dynamic>{
        'name': ref.read(appInfoProvider).deviceName,
        'password': password,
      },
      options: bearer,
    );
    final value = _asMap(response.data);
    final id = value['id'];
    final secret = value['device_secret'];
    if (id is! String ||
        id.isEmpty ||
        secret is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(secret)) {
      throw ApiException('common.network');
    }
    final info = DeviceGrantInfo(
      server: server,
      userId: user.id,
      username: user.username,
      deviceId: id,
    );
    DeviceGrantInfo? previous;
    try {
      requireIdentity(expected);
      previous = await _persist(
        expected,
        () => store.writeGrant(
          DeviceGrant(info, secret),
          reason: reason,
          cancel: cancel,
          beforePublish: () => requireIdentity(expected),
        ),
      );
    } on Object {
      // Captured origin and bearer can clean up an interrupted enrollment after a server switch.
      try {
        await dio.delete<dynamic>('/me/trusted-devices/$id', options: bearer);
      } on Object {
        /* Unpublished opaque credential is inaccessible; expiry remains enforced. */
      }
      rethrow;
    }
    // New selector is already durable. Cleanup failures must not revoke the new grant.
    if (previous != null) {
      if (previous.server == server && previous.userId == user.id) {
        try {
          await dio.delete<dynamic>(
            '/me/trusted-devices/${previous.deviceId}',
            options: bearer,
          );
        } on Object {
          /* old grant remains visible in account security for explicit revocation */
        }
      }
      await store.deleteGrantFile(previous);
    }
  }

  Future<void> enableBiometricFromSession({
    required String reason,
    required String cancel,
  }) => _saveBiometricGrant(
    password: _sessionPassword,
    reason: reason,
    cancel: cancel,
  );

  Future<void> enableBiometricWithPassword(
    String password, {
    required String reason,
    required String cancel,
  }) async {
    if (state.isEncrypted) {
      if (!await unlock(password)) throw ApiException('enc.dek_locked');
    }
    await _saveBiometricGrant(
      password: password,
      reason: reason,
      cancel: cancel,
    );
  }

  Future<void> disableBiometric() async {
    final expected = requestIdentity;
    final info = await savedGrantInfo();
    requireIdentity(expected);
    if (info == null || info.userId != state.user?.id) return;
    try {
      await _guard(
        expected,
        () => _dio.delete<dynamic>(
          '/me/trusted-devices/${info.deviceId}',
          options: _bearer(),
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404 ||
          ApiException.from(error).code != 'trusted_device.not_found') {
        rethrow;
      }
    }
    await _persist(expected, () => ref.read(secureStoreProvider).clearGrant());
  }

  /// Serialized refresh: a single in-flight call is shared by concurrent callers.
  /// Returns null when the server REJECTED the token (forced logout already done);
  /// throws ApiException('common.network') on transport failures (session kept).
  Future<String?> performRefresh() {
    final expected = requestIdentity;
    return _refreshing ??= _doRefresh().whenComplete(() {
      if (isCurrent(expected)) _refreshing = null;
    });
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
    final expected = requestIdentity;
    if (state.accessToken == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await _persist(
      expected,
      () => prefs.setInt(kBgHeartbeatMs, DateTime.now().millisecondsSinceEpoch),
    );
    // The coordinator reads the latest pair under the same lock used by background work.
    await _guard(expected, () => keepaliveTick());
  }

  /// Silent DEK re-unlock with the RAM-held session password (single-flight).
  /// Returns true when the vault holds the DEK again → the 423'd call can retry.
  /// A stale password (changed elsewhere) is forgotten immediately so repeated
  /// 423s can never hammer the failed-login counter and lock the account.
  Future<bool> tryAutoUnlock() {
    final expected = requestIdentity;
    return _autoUnlocking ??= _doAutoUnlock().whenComplete(() {
      if (isCurrent(expected)) _autoUnlocking = null;
    });
  }

  Future<bool> _doAutoUnlock() async {
    final expected = requestIdentity;
    final pw = _sessionPassword;
    if (pw == null || state.accessToken == null) return false;
    try {
      final ok = await _guard(expected, () => unlock(pw));
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
    final expected = requestIdentity;
    final server = ref.read(activeServerProvider);
    if (server == null) return null;
    final coordinator = ref.read(sessionCoordinatorProvider);
    final saved = await _guard(expected, () => coordinator.read(server));
    if (saved == null) {
      await forceLogout();
      return null;
    }
    final lease = await coordinator.acquire(server);
    if (!isCurrent(expected)) {
      if (lease != null) await coordinator.release(lease);
      requireIdentity(expected);
    }
    if (lease == null) throw ApiException('common.network');
    try {
      final Response<dynamic> resp;
      try {
        resp = await _guard(
          expected,
          () => _dio.post<dynamic>(
            '/auth/refresh',
            data: <String, dynamic>{
              'refresh_token': lease.session.refreshToken,
              'app_version': ref.read(appInfoProvider).version,
            },
          ),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 426) {
          handleUpdateRequired(e);
          return null;
        }
        if (e.response?.statusCode == 401) {
          await forceLogout();
          return null;
        }
        throw ApiException.from(e);
      }
      final pair = TokenPair.fromJson(_asMap(resp.data));
      if (pair.accessToken.isEmpty ||
          pair.refreshToken.isEmpty ||
          pair.user == null ||
          pair.user!.id.isEmpty ||
          (state.user != null && pair.user!.id != state.user!.id)) {
        throw ApiException('common.network');
      }
      final stored = await _persist(
        expected,
        () => coordinator.complete(
          lease,
          refreshToken: pair.refreshToken,
          accessToken: pair.accessToken,
          userId: pair.user!.id,
        ),
      );
      if (stored == null) throw ApiException('common.network');
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
    } finally {
      await coordinator.release(lease);
    }
  }

  Future<void> _syncEncryption() async {
    final expected = requestIdentity;
    if (state.accessToken == null) return;
    try {
      final resp = await _guard(
        expected,
        () => _dio.get<dynamic>('/me/encryption', options: _bearer()),
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

  Future<void> logout() => _endSession(revoke: true);

  Future<void> forceLogout() => _endSession(revoke: false);

  Future<void> _endSession({required bool revoke}) async {
    final dio = _dio;
    final server = ref.read(activeServerProvider);
    final coordinator = ref.read(sessionCoordinatorProvider);
    final store = ref.read(secureStoreProvider);
    // Clearing is ordered before every later login write, even if a new login
    // starts before this asynchronous secure-storage transaction has finished.
    final clearing = _storageTail.then(
      (_) => coordinator.clear(
        afterClear: () => _resetBackgroundNotifications(store),
      ),
    );
    _storageTail = clearing.then<void>((_) {}, onError: (Object _) {});
    _generation++;
    _refreshing = null;
    _autoUnlocking = null;
    _sessionPassword = null;
    _biometricLoginUserId = null;
    state = AuthState(status: AuthStatus.loggedOut, sessionId: _generation);
    final previous = await clearing;
    if (revoke && previous != null && previous.server == server) {
      try {
        await dio.post<dynamic>(
          '/auth/logout',
          data: <String, dynamic>{'refresh_token': previous.refreshToken},
        );
      } on DioException {
        // Local logout is already complete; remote revocation is best effort.
      }
    }
  }

  Future<void> _resetBackgroundNotifications(SecureStore store) async {
    try {
      await store.clearBackgroundAccessToken();
      try {
        await NotifyService.cancelAll();
      } on Object {
        /* plugin unavailable */
      }
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(kBgRotated);
      await prefs.remove(kBgSeenIds);
      await prefs.remove(kBgSessionId);
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
  final identity = ref.watch(
    authProvider.select((s) => (s.user?.id, s.sessionId)),
  );
  final server = ref.watch(activeServerProvider);
  return identity.$1 == null ? null : '$server::${identity.$1}::${identity.$2}';
});
