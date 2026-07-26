import '../../core/api/json.dart';

/// Archive diagnostics: is everything that was imported actually searchable, and if not, why.
///
/// Every number here is computed server-side by `/maintenance/archive-health`; the app only
/// renders it. That is deliberate — the same count derived independently on each surface is a
/// count that will eventually disagree with itself, and then the user believes none of them.

/// What the user can do about a cause. Decided by the server (which owns the pipeline's own
/// definition of «transient»); mirrored here only so the UI can branch on it.
const List<String> healthActions = <String>['retry', 'ask_admin', 'none'];

/// One word for the whole archive: nothing to say / still working / worth a look.
const List<String> healthStatuses = <String>['ok', 'working', 'attention'];

class HealthReason {
  const HealthReason({
    required this.reason,
    required this.count,
    required this.extensions,
    required this.action,
    required this.expected,
  });

  /// Stable code; the label lives in the ARB catalogues, never here.
  final String reason;
  final int count;
  final List<String> extensions;
  final String action;

  /// True when nothing went wrong: it was never a document (a logo inside a signature). On a
  /// real archive these are 109,677 of 110,200 attachments «without text» — shown together with
  /// the genuine ones they would bury them under a six-figure number that means nothing.
  final bool expected;

  factory HealthReason.fromJson(Map<String, dynamic> j) => HealthReason(
    reason: jsonStr(j, 'reason'),
    count: jsonInt(j, 'count'),
    extensions: jsonStrList(j, 'extensions'),
    action: jsonStr(j, 'action', 'none'),
    expected: jsonBool(j, 'expected'),
  );
}

class MessageHealth {
  const MessageHealth({
    this.total = 0,
    this.embedded = 0,
    this.pending = 0,
    this.errors = 0,
    this.configured = false,
    this.active = false,
    this.billingPaused = false,
    this.lastErrorAt,
    this.lastErrorDetail = '',
  });

  final int total;
  final int embedded;
  final int pending;
  final int errors;
  final bool configured;
  final bool active;
  final bool billingPaused;
  final DateTime? lastErrorAt;
  final String lastErrorDetail;

  factory MessageHealth.fromJson(Map<String, dynamic> j) {
    final last = jsonMap(j, 'last_error');
    return MessageHealth(
      total: jsonInt(j, 'total'),
      embedded: jsonInt(j, 'embedded'),
      pending: jsonInt(j, 'pending'),
      errors: jsonInt(j, 'errors'),
      configured: jsonBool(j, 'configured'),
      active: jsonBool(j, 'active'),
      billingPaused: jsonBool(j, 'billing_paused'),
      lastErrorAt: jsonDate(last, 'at'),
      lastErrorDetail: jsonStr(last, 'detail'),
    );
  }
}

class AttachmentHealth {
  const AttachmentHealth({
    this.total = 0,
    this.extracted = 0,
    this.pending = 0,
    this.failed = 0,
    this.skipped = 0,
    this.retryable = 0,
    this.exhausted = 0,
  });

  final int total;
  final int extracted;
  final int pending;
  final int failed;
  final int skipped;

  /// A new attempt could still succeed…
  final int retryable;

  /// …and of those, the ones that already burnt every automatic attempt.
  final int exhausted;

  factory AttachmentHealth.fromJson(Map<String, dynamic> j) => AttachmentHealth(
    total: jsonInt(j, 'total'),
    extracted: jsonInt(j, 'extracted'),
    pending: jsonInt(j, 'pending'),
    failed: jsonInt(j, 'failed'),
    skipped: jsonInt(j, 'skipped'),
    retryable: jsonInt(j, 'retryable'),
    exhausted: jsonInt(j, 'exhausted'),
  );
}

class ArchiveHealth {
  const ArchiveHealth({
    this.status = 'ok',
    this.messages = const MessageHealth(),
    this.attachments = const AttachmentHealth(),
    this.reasons = const <HealthReason>[],
    this.embedReasons = const <HealthReason>[],
  });

  final String status;
  final MessageHealth messages;
  final AttachmentHealth attachments;
  final List<HealthReason> reasons;
  final List<HealthReason> embedReasons;

  factory ArchiveHealth.fromJson(Map<String, dynamic> j) => ArchiveHealth(
    status: jsonStr(j, 'status', 'ok'),
    messages: MessageHealth.fromJson(jsonMap(j, 'messages')),
    attachments: AttachmentHealth.fromJson(jsonMap(j, 'attachments')),
    reasons: jsonObjList(j, 'reasons').map(HealthReason.fromJson).toList(),
    embedReasons: jsonObjList(
      j,
      'embed_reasons',
    ).map(HealthReason.fromJson).toList(),
  );

  /// Causes worth acting on: what the user wanted and did not get.
  List<HealthReason> get missing =>
      reasons.where((HealthReason r) => !r.expected).toList();

  /// The noise of email itself — every logo in every signature.
  List<HealthReason> get notDocuments =>
      reasons.where((HealthReason r) => r.expected).toList();

  /// Denominator of the attachment coverage: everything that SHOULD have text.
  ///
  /// Not «total minus skipped»: an attachment past the size limit is skipped too, and that one
  /// is genuinely missing — subtracting it would hide the very thing the user came to find,
  /// behind a reassuring 100%.
  int get readableTotal {
    final int notDocs = notDocuments.fold<int>(
      0,
      (int n, HealthReason r) => n + r.count,
    );
    final int left = attachments.total - notDocs;
    return left < 0 ? 0 : left;
  }
}
