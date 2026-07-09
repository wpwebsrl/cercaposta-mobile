import 'dart:convert';

import 'package:dio/dio.dart';

/// Machine-readable API error. The backend returns `{error:{code,params}}`;
/// the UI translates `code` (see error_messages.dart). Network/timeout failures
/// map to the synthetic code `common.network`.
class ApiException implements Exception {
  ApiException(
    this.code, {
    this.statusCode,
    this.params = const <String, dynamic>{},
  });

  final String code;
  final int? statusCode;
  final Map<String, dynamic> params;

  bool get isDekLocked => code == 'enc.dek_locked';
  bool get isAuthExpired =>
      code == 'auth.invalid_token' || code == 'auth.missing_token';

  String? get detail {
    final d = params['detail'];
    return d is String ? d : null;
  }

  /// Extract `{error:{code,params}}` from a response body that may arrive as a
  /// decoded Map, raw bytes (responseType.bytes) or a JSON string.
  static ApiException? _fromBody(Object? data, int? status) {
    Object? decoded = data;
    try {
      if (data is List<int>) {
        decoded = jsonDecode(utf8.decode(data, allowMalformed: true));
      } else if (data is String && data.isNotEmpty) {
        decoded = jsonDecode(data);
      }
    } on Object {
      return null;
    }
    if (decoded is Map) {
      final err = decoded['error'];
      if (err is Map && err['code'] is String) {
        final params = err['params'];
        return ApiException(
          err['code'] as String,
          statusCode: status,
          params: params is Map
              ? Map<String, dynamic>.from(params)
              : const <String, dynamic>{},
        );
      }
    }
    return null;
  }

  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final parsed = _fromBody(error.response?.data, status);
      if (parsed != null) return parsed;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ApiException('common.network', statusCode: status);
      }
      return ApiException('common.generic', statusCode: status);
    }
    return ApiException('common.generic');
  }

  /// Like [from], but able to drain a STREAMED error body (responseType.stream,
  /// e.g. a 409/423 raised before /chat/stream starts emitting events).
  static Future<ApiException> fromAsync(Object error) async {
    if (error is DioException && error.response?.data is ResponseBody) {
      final status = error.response?.statusCode;
      try {
        final body = error.response!.data as ResponseBody;
        final bytes = await body.stream.fold<List<int>>(
          <int>[],
          (acc, chunk) => acc..addAll(chunk),
        );
        final parsed = _fromBody(bytes, status);
        if (parsed != null) return parsed;
      } on Object {
        // fall through to the sync mapping
      }
    }
    return from(error);
  }

  @override
  String toString() => 'ApiException($code, status=$statusCode)';
}
