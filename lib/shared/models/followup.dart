import '../../core/api/json.dart';

/// Reply expectations (docs/followup.md in the server repo). A record extracted
/// from one message: "someone owes someone a reply, by a certain date". The
/// sensitive fields (name/address/summary) are decrypted server-side with the
/// session DEK; the client only renders them.
class FollowupItem {
  const FollowupItem({
    required this.id,
    required this.direction,
    required this.state,
    required this.counterpartName,
    required this.counterpartAddress,
    required this.summary,
    required this.dueAt,
    required this.snoozeUntil,
    required this.origin,
    required this.threadId,
    required this.messageId,
    required this.createdAt,
    required this.reminderCount,
    required this.lastReminderAt,
  });

  final String id;
  final String direction; // their_turn | my_turn
  final String state; // open|answered|expired|reminded|dismissed|snoozed
  final String counterpartName;
  final String counterpartAddress;
  final String summary;
  final DateTime? dueAt;
  final DateTime? snoozeUntil;
  final String origin; // llm | manual
  final String threadId;
  final String messageId;
  final DateTime? createdAt;
  final int reminderCount;
  final DateTime? lastReminderAt; // drives the «Sollecitato il …» row chip

  static const activeStates = <String>{
    'open',
    'expired',
    'reminded',
    'snoozed',
  };

  bool get isActive => activeStates.contains(state);
  String get counterpartLabel =>
      counterpartName.isNotEmpty ? counterpartName : counterpartAddress;

  /// A their_turn we're still waiting on can be chased with a reminder.
  bool get canRemind =>
      direction == 'their_turn' && (state == 'expired' || state == 'reminded');

  factory FollowupItem.fromJson(Map<String, dynamic> j) => FollowupItem(
    id: jsonStr(j, 'id'),
    direction: jsonStr(j, 'direction', 'their_turn'),
    state: jsonStr(j, 'state', 'open'),
    counterpartName: jsonStr(j, 'counterpart_name'),
    counterpartAddress: jsonStr(j, 'counterpart_address'),
    summary: jsonStr(j, 'summary'),
    dueAt: jsonDate(j, 'due_at'),
    snoozeUntil: jsonDate(j, 'snooze_until'),
    origin: jsonStr(j, 'origin', 'llm'),
    threadId: jsonStr(j, 'thread_id'),
    messageId: jsonStr(j, 'message_id'),
    createdAt: jsonDate(j, 'created_at'),
    reminderCount: jsonInt(j, 'reminder_count'),
    lastReminderAt: jsonDate(j, 'last_reminder_at'),
  );
}

class FollowupList {
  const FollowupList({required this.total, required this.items});

  final int total;
  final List<FollowupItem> items;

  factory FollowupList.fromJson(Map<String, dynamic> j) => FollowupList(
    total: jsonInt(j, 'total'),
    items: jsonObjList(j, 'items').map(FollowupItem.fromJson).toList(),
  );
}

/// The LLM-drafted reminder (POST /followups/{id}/draft-reminder). `body` is the
/// editable CORE without the signature (the server appends signature / AI-disclosure
/// / quoted original). `reminderPrefix`/`reminderSuffix` are the plain-text fragments
/// the client wraps around the edited core to rebuild the mailto body.
class ReminderDraft {
  const ReminderDraft({
    required this.subject,
    required this.body,
    required this.reminderPrefix,
    required this.reminderSuffix,
    required this.registerUsed,
    required this.registerSource,
    required this.language,
    required this.includeOriginal,
    required this.sendAvailable,
    required this.sendFrom,
  });

  final String subject;
  final String body;
  final String reminderPrefix;
  final String reminderSuffix;
  final String registerUsed; // tu | lei | ''
  final String registerSource; // manual | contact | detected | default
  final String language;
  final bool includeOriginal;
  final bool sendAvailable; // the origin account can send directly
  final String sendFrom; // the From a direct send would use

  factory ReminderDraft.fromJson(Map<String, dynamic> j) => ReminderDraft(
    subject: jsonStr(j, 'subject'),
    body: jsonStr(j, 'body'),
    reminderPrefix: jsonStr(j, 'reminder_prefix'),
    reminderSuffix: jsonStr(j, 'reminder_suffix'),
    registerUsed: jsonStr(j, 'register_used'),
    registerSource: jsonStr(j, 'register_source'),
    language: jsonStr(j, 'language', 'it'),
    includeOriginal: jsonBool(j, 'include_original'),
    sendAvailable: jsonBool(j, 'send_available'),
    sendFrom: jsonStr(j, 'send_from'),
  );
}

/// True-to-recipient preview composed server-side (POST /followups/{id}/reminder-preview):
/// the full email with signature and inline images, as it will arrive.
class ReminderPreview {
  const ReminderPreview({
    required this.subject,
    required this.html,
    required this.text,
  });

  final String subject;
  final String html;
  final String text;

  factory ReminderPreview.fromJson(Map<String, dynamic> j) => ReminderPreview(
    subject: jsonStr(j, 'subject'),
    html: jsonStr(j, 'html'),
    text: jsonStr(j, 'text'),
  );
}

/// Feature status (GET /followups/status): drives the page's empty/paused states.
class FollowupStatus {
  const FollowupStatus({
    required this.configured,
    required this.enabled,
    required this.paused,
  });

  final bool configured; // ai.analysis.* card filled
  final bool enabled; // per-user opt-in
  final String? paused; // endpoint_error | daily_cap | billing | null

  bool get available => configured && enabled;

  factory FollowupStatus.fromJson(Map<String, dynamic> j) => FollowupStatus(
    configured: jsonBool(j, 'configured'),
    enabled: jsonBool(j, 'enabled'),
    paused: jsonStrOrNull(j, 'paused'),
  );
}
