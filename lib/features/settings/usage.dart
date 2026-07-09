import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/json.dart';
import '../../core/auth/auth_controller.dart';

/// Disk-space usage for the current user (GET /me/usage). `quotaBytes == 0` means
/// unlimited. Fetched per session; a transient failure resolves to null (hidden).
class UsageInfo {
  const UsageInfo({
    required this.usedBytes,
    required this.quotaBytes,
    required this.percent,
    required this.overQuota,
  });

  final int usedBytes;
  final int quotaBytes;
  final double percent;
  final bool overQuota;

  bool get unlimited => quotaBytes <= 0;

  factory UsageInfo.fromJson(Map<String, dynamic> j) => UsageInfo(
    usedBytes: jsonInt(j, 'used_bytes'),
    quotaBytes: jsonInt(j, 'quota_bytes'),
    percent: j['percent'] is num ? (j['percent'] as num).toDouble() : 0,
    overQuota: jsonBool(j, 'over_quota'),
  );
}

final usageProvider = FutureProvider<UsageInfo?>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    final resp = await ref.watch(apiDioProvider).get<dynamic>('/me/usage');
    return UsageInfo.fromJson(mapOf(resp.data));
  } on Object {
    return null; // don't surface a broken/absent usage endpoint
  }
});
