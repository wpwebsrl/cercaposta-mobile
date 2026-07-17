import '../../core/api/json.dart';

class AttachmentInfo {
  const AttachmentInfo({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.extension,
    required this.sizeBytes,
    required this.isInline,
  });

  final String id;
  final String filename;
  final String contentType;
  final String extension;
  final int sizeBytes;
  final bool isInline;

  factory AttachmentInfo.fromJson(Map<String, dynamic> j) => AttachmentInfo(
    id: jsonStr(j, 'id'),
    filename: jsonStr(j, 'filename'),
    contentType: jsonStr(j, 'content_type'),
    extension: jsonStr(j, 'extension'),
    sizeBytes: jsonInt(j, 'size_bytes'),
    isInline: jsonBool(j, 'is_inline'),
  );
}

class TagRef {
  const TagRef({required this.id, required this.name, required this.color});
  final String id;
  final String name;
  final String color;

  factory TagRef.fromJson(Map<String, dynamic> j) => TagRef(
    id: jsonStr(j, 'id'),
    name: jsonStr(j, 'name'),
    color: jsonStr(j, 'color', 'gray'),
  );
}

/// PEC "busta di trasporto" metadata, present when the message was unwrapped to
/// its certified inner content. Shown as a small panel in the email detail.
class PecInfo {
  const PecInfo({
    required this.transportFrom,
    required this.transportSubject,
    required this.transportDate,
    required this.hasDaticert,
  });

  final String transportFrom;
  final String transportSubject;
  final DateTime? transportDate;
  final bool hasDaticert;

  bool get hasAny =>
      transportFrom.isNotEmpty ||
      transportSubject.isNotEmpty ||
      transportDate != null ||
      hasDaticert;

  factory PecInfo.fromJson(Map<String, dynamic> j) => PecInfo(
    transportFrom: jsonStr(j, 'transport_from'),
    transportSubject: jsonStr(j, 'transport_subject'),
    transportDate: jsonDate(j, 'transport_date'),
    hasDaticert: jsonBool(j, 'has_daticert'),
  );
}

/// One entry of the `recipients` map returned by `GET /messages/{id}`, which the
/// server sends as `{"to": [{"name": …, "address": …}], "cc": […], "bcc": […]}`.
///
/// Kept as a pair rather than a preformatted string: `name` is often empty and the
/// address alone must then stand on its own, exactly as the web reader does.
class Recipient {
  const Recipient({required this.name, required this.address});

  final String name;
  final String address;

  /// `Name <address>` when both are known, otherwise whichever is there — parity
  /// with `personLabel` on the web and `Recipient.display()` on the desktop.
  String get display {
    if (name.isEmpty) return address;
    if (address.isEmpty) return name;
    return '$name <$address>';
  }

  factory Recipient.fromJson(Map<String, dynamic> j) =>
      Recipient(name: jsonStr(j, 'name'), address: jsonStr(j, 'address'));

  /// Parses one recipients bucket. The server always sends the three keys, but a
  /// bucket may legitimately be empty (`bcc` is only ever filled on sent copies:
  /// received mail carries no Bcc header at all).
  static List<Recipient> listFrom(
    Map<String, dynamic> recipients,
    String key,
  ) => jsonObjList(recipients, key).map(Recipient.fromJson).toList();
}

class MessageDetail {
  const MessageDetail({
    required this.id,
    required this.subject,
    required this.fromName,
    required this.fromAddress,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.dateSent,
    required this.threadId,
    required this.bodyHtml,
    required this.bodyText,
    required this.hasRemoteImages,
    required this.rawMissing,
    required this.isPec,
    required this.pec,
    required this.attachments,
    required this.folders,
    required this.tags,
    this.sharedOwnerName,
  });

  final String id;
  final String subject;
  final String fromName;
  final String fromAddress;
  final List<Recipient> to;
  final List<Recipient> cc;
  final List<Recipient> bcc;
  final DateTime? dateSent;
  final String? threadId;
  final String? bodyHtml;
  final String bodyText;
  final bool hasRemoteImages;
  final bool rawMissing;
  final bool isPec;
  final PecInfo? pec;
  final List<AttachmentInfo> attachments;
  final List<String> folders;
  final List<TagRef> tags;

  /// Display name of the archive owner when the message is read through a
  /// folder share (docs/condivisione.md); null for the user's own mail.
  final String? sharedOwnerName;

  String get fromLabel => fromName.isNotEmpty ? fromName : fromAddress;
  bool get hasBody =>
      (bodyHtml != null && bodyHtml!.isNotEmpty) || bodyText.isNotEmpty;

  factory MessageDetail.fromJson(Map<String, dynamic> j) {
    final recipients = jsonMap(j, 'recipients');
    return MessageDetail(
      id: jsonStr(j, 'id'),
      subject: jsonStr(j, 'subject'),
      fromName: jsonStr(j, 'from_name'),
      fromAddress: jsonStr(j, 'from_address'),
      // NOT jsonStrList: the buckets hold {name, address} objects, and whereType<String>
      // silently dropped every one of them — the To/Cc/Bcc rows have never rendered.
      to: Recipient.listFrom(recipients, 'to'),
      cc: Recipient.listFrom(recipients, 'cc'),
      bcc: Recipient.listFrom(recipients, 'bcc'),
      dateSent: jsonDate(j, 'date_sent'),
      threadId: jsonStrOrNull(j, 'thread_id'),
      bodyHtml: jsonStrOrNull(j, 'body_html'),
      bodyText: jsonStr(j, 'body_text'),
      hasRemoteImages: jsonBool(j, 'has_remote_images'),
      rawMissing: jsonBool(j, 'raw_missing'),
      isPec: jsonBool(j, 'is_pec'),
      pec: j['pec'] is Map<String, dynamic>
          ? PecInfo.fromJson(j['pec'] as Map<String, dynamic>)
          : null,
      attachments: jsonObjList(
        j,
        'attachments',
      ).map(AttachmentInfo.fromJson).toList(),
      folders: jsonStrList(j, 'folders'),
      tags: jsonObjList(j, 'tags').map(TagRef.fromJson).toList(),
      sharedOwnerName: j['shared_owner'] is Map<String, dynamic>
          ? jsonStr(j['shared_owner'] as Map<String, dynamic>, 'display_name')
          : null,
    );
  }
}

class ThreadEntry {
  const ThreadEntry({
    required this.id,
    required this.subject,
    required this.fromName,
    required this.fromAddress,
    required this.dateSent,
    required this.snippet,
  });

  final String id;
  final String subject;
  final String fromName;
  final String fromAddress;
  final DateTime? dateSent;
  final String snippet;

  String get fromLabel => fromName.isNotEmpty ? fromName : fromAddress;

  factory ThreadEntry.fromJson(Map<String, dynamic> j) => ThreadEntry(
    id: jsonStr(j, 'id'),
    subject: jsonStr(j, 'subject'),
    fromName: jsonStr(j, 'from_name'),
    fromAddress: jsonStr(j, 'from_address'),
    dateSent: jsonDate(j, 'date_sent'),
    snippet: jsonStr(j, 'snippet'),
  );
}
