import 'package:dio/dio.dart';

import '../../../shared/models/memory.dart';
import '../json.dart';

/// Chat memory management (`/me/memories`) — docs/memoria-utente.md.
///
/// One contract for every surface: the app reads and writes exactly what the web does, because
/// the effect of a memory is server-side and only its management needs a UI. A memory taught on
/// the desktop applies here the same afternoon, and can be undone from either.
class MemoryApi {
  MemoryApi(this._dio);
  final Dio _dio;

  Future<List<Memory>> list() async {
    final resp = await _dio.get<dynamic>('/me/memories');
    return listOf(resp.data).map(Memory.fromJson).toList();
  }

  Future<MemoryPolicy> policy() async {
    final resp = await _dio.get<dynamic>('/me/memories/policy');
    return MemoryPolicy.fromJson(mapOf(resp.data));
  }

  Future<MemoryPolicy> setPolicy(MemoryPolicy policy) async {
    final resp = await _dio.put<dynamic>(
      '/me/memories/policy',
      data: policy.toJson(),
    );
    return MemoryPolicy.fromJson(mapOf(resp.data));
  }

  /// `enabled` pauses a memory, `rejected` records a standing refusal: two different things,
  /// never collapsed into one control (docs/memoria-utente.md §7).
  Future<void> update(String id, {bool? enabled, bool? rejected}) async {
    final body = <String, dynamic>{
      if (enabled != null) 'enabled': enabled,
      if (rejected != null) 'rejected': rejected,
    };
    await _dio.patch<dynamic>('/me/memories/$id', data: body);
  }

  Future<void> delete(String id) => _dio.delete<dynamic>('/me/memories/$id');

  Future<List<AliasSuggestion>> suggestions() async {
    final resp = await _dio.get<dynamic>('/me/memories/suggestions');
    return listOf(resp.data).map(AliasSuggestion.fromJson).toList();
  }

  Future<void> acceptSuggestion(AliasSuggestion s) => _dio.post<dynamic>(
    '/me/memories/accept-suggestion',
    data: <String, dynamic>{'key': s.key, 'value': s.value},
  );
}
