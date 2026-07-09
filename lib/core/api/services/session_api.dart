import 'package:dio/dio.dart';

import '../../../shared/models/auth.dart';
import '../json.dart';

class SessionApi {
  SessionApi(this._dio);
  final Dio _dio;

  Future<List<SessionInfo>> list() async {
    final resp = await _dio.get<dynamic>('/auth/sessions');
    return listOf(resp.data).map(SessionInfo.fromJson).toList();
  }

  Future<void> revoke(String id) => _dio.post<dynamic>(
    '/auth/sessions/revoke',
    data: <String, dynamic>{'id': id},
  );

  Future<void> revokeAll() => _dio.post<dynamic>('/auth/sessions/revoke-all');
}
