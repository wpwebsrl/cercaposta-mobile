import 'package:dio/dio.dart';

/// A Dio configured for a server's `/api/v1` base, with sane timeouts.
/// HTTPS is expected; plain http is allowed only for local dev servers.
Dio buildDio(String baseUrl) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );
}
