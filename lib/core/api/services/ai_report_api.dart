import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AiReportApi {
  AiReportApi(this._dio);

  final Dio _dio;

  Future<bool> create({
    required String messageId,
    required String reason,
    required String comment,
  }) async {
    final response = await _dio.post<dynamic>(
      '/ai-content-reports',
      data: <String, dynamic>{
        'message_id': messageId,
        'reason': reason,
        'comment': comment.trim(),
        'source_client': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      },
    );
    final data = response.data;
    return data is Map && data['created'] == true;
  }
}
