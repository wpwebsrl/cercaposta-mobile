import 'package:dio/dio.dart';

import '../../../shared/models/search.dart';
import '../json.dart';

class SearchApi {
  SearchApi(this._dio);
  final Dio _dio;

  Future<SearchResult> search({
    required String text,
    Map<String, dynamic> filters = const <String, dynamic>{},
    String sort = 'relevance',
    int size = 25,
    List<dynamic>? searchAfter,
  }) async {
    final resp = await _dio.post<dynamic>(
      '/search',
      data: <String, dynamic>{
        'text': text,
        'filters': filters,
        'sort': sort,
        'size': size,
        if (searchAfter != null) 'search_after': searchAfter,
      },
    );
    return SearchResult.fromJson(mapOf(resp.data));
  }

  Future<ParsedQuery> parse(String q) async {
    final resp = await _dio.post<dynamic>(
      '/search/parse',
      data: <String, dynamic>{'q': q},
    );
    return ParsedQuery.fromJson(mapOf(resp.data));
  }

  Future<List<String>> suggest({
    required String kind,
    required String prefix,
  }) async {
    final resp = await _dio.get<dynamic>(
      '/search/suggest',
      queryParameters: <String, dynamic>{'kind': kind, 'prefix': prefix},
    );
    final values = mapOf(resp.data)['values'];
    return values is List
        ? values.whereType<String>().toList()
        : const <String>[];
  }
}
