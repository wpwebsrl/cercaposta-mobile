import '../../core/api/json.dart';

class TagInfo {
  const TagInfo({required this.id, required this.name, required this.color});
  final String id;
  final String name;
  final String color;

  factory TagInfo.fromJson(Map<String, dynamic> j) => TagInfo(
    id: jsonStr(j, 'id'),
    name: jsonStr(j, 'name'),
    color: jsonStr(j, 'color', 'gray'),
  );
}

class FolderNode {
  const FolderNode({
    required this.id,
    required this.name,
    required this.path,
    required this.count,
    required this.children,
    this.direct = 0,
    this.isDestination = false,
  });

  final String id;
  final String name;
  final String path;
  final int count; // subtree: this folder + all descendants
  final int direct; // distinct messages directly in this exact folder
  final List<FolderNode> children;
  final bool isDestination;

  factory FolderNode.fromJson(Map<String, dynamic> j) {
    final id = jsonStr(j, 'id');
    if (id.isEmpty) {
      throw const FormatException('Folder node is missing its stable ID');
    }
    return FolderNode(
      id: id,
      name: jsonStr(j, 'name'),
      path: jsonStr(j, 'path'),
      count: jsonInt(j, 'count'),
      direct: jsonInt(j, 'direct'),
      children: jsonObjList(j, 'children').map(FolderNode.fromJson).toList(),
      isDestination: jsonBool(j, 'is_destination'),
    );
  }
}

/// One folder another user shared with this account (GET /shares/received,
/// docs/condivisione.md). The apps are read-only viewers: no management here.
class ShareInfo {
  const ShareInfo({
    required this.id,
    required this.folderId,
    required this.folderPath,
    required this.includeSubtree,
    required this.ownerUsername,
    required this.ownerDisplayName,
    this.count,
  });

  final String id;
  final String folderId;
  final String folderPath;
  final bool includeSubtree;
  final String ownerUsername;
  final String ownerDisplayName;

  /// Message count of the shared root (tree decoration; null = unavailable).
  final int? count;

  String get rootName {
    final parts = folderPath.split('/').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? folderPath : parts.last;
  }

  factory ShareInfo.fromJson(Map<String, dynamic> j) {
    final owner = jsonMap(j, 'owner');
    final username = jsonStr(owner, 'username');
    final folderId = jsonStr(j, 'folder_id');
    if (folderId.isEmpty) {
      throw const FormatException('Share is missing its folder ID');
    }
    return ShareInfo(
      id: jsonStr(j, 'id'),
      folderId: folderId,
      folderPath: jsonStr(j, 'folder_path'),
      includeSubtree: jsonBool(j, 'include_subtree'),
      ownerUsername: username,
      ownerDisplayName: jsonStr(owner, 'display_name', username),
      count: j['count'] is int ? j['count'] as int : null,
    );
  }
}

/// GET /folders/tree envelope: the archive-wide total feeds the
/// "all folders" row of the scope drawer.
class FolderTreeResult {
  const FolderTreeResult({required this.total, required this.roots});

  final int total;
  final List<FolderNode> roots;

  factory FolderTreeResult.fromJson(Map<String, dynamic> j) => FolderTreeResult(
    total: jsonInt(j, 'total'),
    roots: jsonObjList(j, 'roots').map(FolderNode.fromJson).toList(),
  );
}
