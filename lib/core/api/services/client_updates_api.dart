import 'package:dio/dio.dart';

import '../json.dart';

class ClientUpdatesApi {
  ClientUpdatesApi(this._dio);

  final Dio _dio;

  Future<Uri?> storeUrl(String client) async {
    final response = await _dio.get<dynamic>('/client-updates/store/products');
    for (final product in jsonObjList(mapOf(response.data), 'products')) {
      if (jsonStr(product, 'id') != client) continue;
      final raw = jsonStrOrNull(product, 'url');
      final uri = raw == null ? null : Uri.tryParse(raw);
      if (uri != null && uri.scheme == 'https') return uri;
    }
    return null;
  }
}
