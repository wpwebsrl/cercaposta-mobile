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
