import '../../core/api/json.dart';
import 'user.dart';

/// Response of /auth/login and /auth/totp (single shape: tokens or 2FA challenge).
class LoginResult {
  const LoginResult({
    required this.requiresTotp,
    required this.totpToken,
    required this.totpSetupRequired,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.encStatus,
    required this.dekAvailable,
    required this.recoveryRequired,
  });

  final bool requiresTotp;
  final String? totpToken;
  // Admin enforces 2FA but the user hasn't enrolled yet (enrollment lives on the web).
  final bool totpSetupRequired;
  final String? accessToken;
  final String? refreshToken;
  final UserInfo? user;
  final String encStatus; // none | pending | active
  final bool dekAvailable;
  final bool recoveryRequired;

  bool get isEncrypted => encStatus == 'active';
  bool get needsUnlock => isEncrypted && !dekAvailable;

  factory LoginResult.fromJson(Map<String, dynamic> j) {
    final userJson = j['user'];
    return LoginResult(
      requiresTotp: jsonBool(j, 'requires_totp'),
      totpToken: jsonStrOrNull(j, 'totp_token'),
      totpSetupRequired: jsonBool(j, 'totp_setup_required'),
      accessToken: jsonStrOrNull(j, 'access_token'),
      refreshToken: jsonStrOrNull(j, 'refresh_token'),
      user: userJson is Map<String, dynamic>
          ? UserInfo.fromJson(userJson)
          : null,
      encStatus: jsonStr(j, 'enc_status', 'none'),
      dekAvailable: jsonBool(j, 'dek_available', true),
      recoveryRequired: jsonBool(j, 'recovery_required'),
    );
  }
}

/// Response of /auth/refresh.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserInfo? user;

  factory TokenPair.fromJson(Map<String, dynamic> j) {
    final userJson = j['user'];
    return TokenPair(
      accessToken: jsonStr(j, 'access_token'),
      refreshToken: jsonStr(j, 'refresh_token'),
      user: userJson is Map<String, dynamic>
          ? UserInfo.fromJson(userJson)
          : null,
    );
  }
}

/// EncryptionState from /me/encryption and /auth/unlock.
class EncryptionState {
  const EncryptionState({
    required this.encStatus,
    required this.dekAvailable,
    required this.recoveryRequired,
  });

  final String encStatus;
  final bool dekAvailable;
  final bool recoveryRequired;

  bool get isEncrypted => encStatus == 'active';
  bool get needsUnlock => isEncrypted && !dekAvailable;

  factory EncryptionState.fromJson(Map<String, dynamic> j) => EncryptionState(
    encStatus: jsonStr(j, 'enc_status', 'none'),
    dekAvailable: jsonBool(j, 'dek_available', true),
    recoveryRequired: jsonBool(j, 'recovery_required'),
  );
}

/// One device/session from GET /auth/sessions.
class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.client,
    required this.deviceName,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    required this.lastIp,
    required this.current,
  });

  final String id;
  final String? client;
  final String? deviceName;
  final String? appVersion;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final String? lastIp;
  final bool current;

  factory SessionInfo.fromJson(Map<String, dynamic> j) => SessionInfo(
    id: jsonStr(j, 'id'),
    client: jsonStrOrNull(j, 'client'),
    deviceName: jsonStrOrNull(j, 'device_name'),
    appVersion: jsonStrOrNull(j, 'app_version'),
    createdAt: jsonDate(j, 'created_at'),
    lastSeenAt: jsonDate(j, 'last_seen_at'),
    lastIp: jsonStrOrNull(j, 'last_ip'),
    current: jsonBool(j, 'current'),
  );
}
