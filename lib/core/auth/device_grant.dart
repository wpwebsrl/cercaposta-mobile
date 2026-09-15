import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Non-secret selector. Knowing it never permits reading the native credential.
class DeviceGrantInfo {
  const DeviceGrantInfo({
    required this.server,
    required this.userId,
    required this.username,
    required this.deviceId,
  });
  final String server;
  final String userId;
  final String username;
  final String deviceId;

  Map<String, String> toJson() => {
    'server': server,
    'user_id': userId,
    'username': username,
    'device_id': deviceId,
  };

  static DeviceGrantInfo? parse(Object? value) {
    if (value is! Map) return null;
    for (final key in ['server', 'user_id', 'username', 'device_id']) {
      if (value[key] is! String ||
          (value[key] as String).isEmpty ||
          (value[key] as String).length > 2048) {
        return null;
      }
    }
    return DeviceGrantInfo(
      server: value['server'] as String,
      userId: value['user_id'] as String,
      username: value['username'] as String,
      deviceId: value['device_id'] as String,
    );
  }

  String get storageName =>
      'cp_native_v1_${sha256.convert(utf8.encode(jsonEncode([server, userId, deviceId])))}';

  bool matches(DeviceGrantInfo other) =>
      server == other.server &&
      userId == other.userId &&
      username == other.username &&
      deviceId == other.deviceId;
}

class DeviceGrant {
  const DeviceGrant(this.info, this.secret);
  final DeviceGrantInfo info;
  final String secret;
  Map<String, String> get credential => {
    'device_id': info.deviceId,
    'device_secret': secret,
  };
}
