import 'package:dio/dio.dart';

import '../../../shared/models/health.dart';
import '../json.dart';

/// Archive diagnostics (`/maintenance/archive-health`) and the one action it offers.
///
/// Read-only except for «rimetti in coda», which is a USER action and not an administrator's for
/// the same reason «Rielabora archivio» is: re-running the extraction rewrites the text encrypted
/// with the owner's DEK, so only the owner can start it.
class HealthApi {
  HealthApi(this._dio);
  final Dio _dio;

  Future<ArchiveHealth> archiveHealth() async {
    final resp = await _dio.get<dynamic>('/maintenance/archive-health');
    return ArchiveHealth.fromJson(mapOf(resp.data));
  }

  /// Puts the transiently-failed attachments back in the queue; returns how many moved.
  Future<int> retryExtract() async {
    final resp = await _dio.post<dynamic>(
      '/maintenance/retry-extract',
      data: <String, dynamic>{},
    );
    return jsonInt(mapOf(resp.data), 'requeued');
  }
}
