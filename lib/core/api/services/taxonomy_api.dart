import 'package:dio/dio.dart';

import '../../../shared/models/taxonomy.dart';
import '../json.dart';

class TaxonomyApi {
  TaxonomyApi(this._dio);
  final Dio _dio;

  Future<List<TagInfo>> tags() async {
    final resp = await _dio.get<dynamic>('/tags');
    return listOf(resp.data).map(TagInfo.fromJson).toList();
  }

  Future<TagInfo> createTag(String name, String color) async {
    final resp = await _dio.post<dynamic>(
      '/tags',
      data: <String, dynamic>{'name': name, 'color': color},
    );
    return TagInfo.fromJson(mapOf(resp.data));
  }

  Future<TagInfo> updateTag(
    String id, {
    required String name,
    required String color,
  }) async {
    final resp = await _dio.patch<dynamic>(
      '/tags/$id',
      data: <String, dynamic>{'name': name, 'color': color},
    );
    return TagInfo.fromJson(mapOf(resp.data));
  }

  Future<void> deleteTag(String id) => _dio.delete<dynamic>('/tags/$id');

  Future<List<TagInfo>> addMessageTag(String messageId, String tagId) async {
    final resp = await _dio.post<dynamic>('/messages/$messageId/tags/$tagId');
    return listOf(resp.data).map(TagInfo.fromJson).toList();
  }

  Future<List<TagInfo>> removeMessageTag(String messageId, String tagId) async {
    final resp = await _dio.delete<dynamic>('/messages/$messageId/tags/$tagId');
    return listOf(resp.data).map(TagInfo.fromJson).toList();
  }

  Future<FolderTreeResult> folders() async {
    final resp = await _dio.get<dynamic>('/folders/tree');
    return FolderTreeResult.fromJson(mapOf(resp.data));
  }

  /// Folders other users shared with this account (docs/condivisione.md).
  Future<List<ShareInfo>> sharesReceived() async {
    final resp = await _dio.get<dynamic>('/shares/received');
    return listOf(resp.data).map(ShareInfo.fromJson).toList();
  }

  /// The shared subtree of one share (absolute owner paths, single root node).
  Future<FolderTreeResult> shareTree(String shareId) async {
    final resp = await _dio.get<dynamic>('/shares/$shareId/tree');
    return FolderTreeResult.fromJson(mapOf(resp.data));
  }
}
