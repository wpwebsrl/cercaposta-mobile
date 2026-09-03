import 'package:dio/dio.dart';

import '../../../shared/models/capabilities.dart';
import '../json.dart';

class CapabilitiesApi {
  CapabilitiesApi(this._dio);

  final Dio _dio;

  Future<Capabilities> get() async {
    final response = await _dio.get<dynamic>('/me/capabilities');
    return Capabilities.fromJson(mapOf(response.data));
  }
}
