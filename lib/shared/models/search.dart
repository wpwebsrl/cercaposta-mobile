import '../../core/api/json.dart';

class AttachmentHit {
  const AttachmentHit({
    required this.attachmentId,
    required this.filename,
    required this.snippets,
  });

  final String? attachmentId;
  final String filename;
  final List<String> snippets;

  factory AttachmentHit.fromJson(Map<String, dynamic> j) => AttachmentHit(
    attachmentId: jsonStrOrNull(j, 'attachment_id'),
    filename: jsonStr(j, 'filename'),
    snippets: jsonStrList(j, 'snippets'),
  );
}

class SearchHit {
  const SearchHit({
    required this.id,
    required this.subject,
    required this.fromName,
    required this.fromAddress,
    required this.date,
    required this.snippet,
    required this.hasAttachments,
    required this.attachmentCount,
    required this.sizeBytes,
    required this.folders,
    required this.tags,
    required this.sort,
    this.sharedOwnerName,
  });

  final String id;
  final String subject;
  final String fromName;
  final String fromAddress;
  final DateTime? date;
  final String snippet;
  final bool hasAttachments;
  final int attachmentCount;
  final int sizeBytes;
  final List<String> folders;
  final List<String> tags;
  final List<dynamic>
  sort; // keyset cursor passed back verbatim as search_after

  /// Display name of the archive owner when the hit comes from a folder share
  /// (docs/condivisione.md); null for the user's own mail.
  final String? sharedOwnerName;

  String get fromLabel => fromName.isNotEmpty ? fromName : fromAddress;

  factory SearchHit.fromJson(Map<String, dynamic> j) {
    final sortVal = j['sort'];
    final sharedOwner = j['shared_owner'];
    return SearchHit(
      id: jsonStr(j, 'id'),
      subject: jsonStr(j, 'subject'),
      fromName: jsonStr(j, 'from_name'),
      fromAddress: jsonStr(j, 'from_address'),
      date: jsonDate(j, 'date'),
      snippet: jsonStr(j, 'snippet'),
      hasAttachments: jsonBool(j, 'has_attachments'),
      attachmentCount: jsonInt(j, 'attachment_count'),
      sizeBytes: jsonInt(j, 'size_bytes'),
      folders: jsonStrList(j, 'folders'),
      tags: jsonStrList(j, 'tags'),
      sort: sortVal is List ? sortVal : const <dynamic>[],
      sharedOwnerName: sharedOwner is Map<String, dynamic>
          ? jsonStr(sharedOwner, 'display_name')
          : null,
    );
  }
}

class SearchResult {
  const SearchResult({
    required this.total,
    required this.hits,
    required this.tookMs,
  });

  final int total;
  final List<SearchHit> hits;
  final int tookMs;

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
    total: jsonInt(j, 'total'),
    hits: jsonObjList(j, 'hits').map(SearchHit.fromJson).toList(),
    tookMs: jsonInt(j, 'took_ms'),
  );
}

/// Result of POST /search/parse.
class ParsedQuery {
  const ParsedQuery({required this.text, required this.filters});

  final String text;
  final Map<String, dynamic> filters;

  factory ParsedQuery.fromJson(Map<String, dynamic> j) =>
      ParsedQuery(text: jsonStr(j, 'text'), filters: jsonMap(j, 'filters'));
}
