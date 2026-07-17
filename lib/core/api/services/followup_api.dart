import 'package:dio/dio.dart';

import '../../../shared/models/followup.dart';
import '../json.dart';

/// Reply expectations + reminder composition (docs/followup.md in the server repo).
///
/// The reminder is composed server-side (same path as the .eml / automatic reminder);
/// the user reviews it and either SENDS it directly from the origin account via
/// «Invia da Cerca posta» (send-reminder) or opens it in their own mail app (mailto).
/// The client never sends mail itself — «Invia da Cerca posta» is a user-triggered
/// action on a server-side channel (specifica §8.7).
class FollowupApi {
  FollowupApi(this._dio);
  final Dio _dio;

  Future<FollowupList> list({int limit = 200}) async {
    final resp = await _dio.get<dynamic>(
      '/followups',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    return FollowupList.fromJson(mapOf(resp.data));
  }

  Future<FollowupStatus> status() async {
    final resp = await _dio.get<dynamic>('/followups/status');
    return FollowupStatus.fromJson(mapOf(resp.data));
  }

  /// Mark a message as awaiting a reply. `direction` is `their_turn` (I wrote, I want
  /// an answer) or `my_turn` (they wrote, I owe one); `dueAt` null lets the server work
  /// the deadline out from the policy's working days.
  ///
  /// The server refuses a direction the message cannot support — asking `their_turn` on
  /// mail you received yields `followup.no_counterpart`, since there is no addressee to
  /// wait on — and rejects a second active expectation on the same thread and direction
  /// with `followup.already_active`. Both are surfaced to the user, not swallowed.
  Future<void> create(
    String messageId,
    String direction, {
    DateTime? dueAt,
  }) async {
    await _dio.post<dynamic>(
      '/followups',
      data: <String, dynamic>{
        'message_id': messageId,
        'direction': direction,
        if (dueAt != null) 'due_at': dueAt.toUtc().toIso8601String(),
      },
    );
  }

  /// The user's own addresses, used only to guess which direction to preselect.
  /// Never throws: a failed guess must not block marking a message (parity with the
  /// desktop, whose own_addresses() swallows errors for the same reason).
  Future<List<String>> ownAddresses() async {
    try {
      final resp = await _dio.get<dynamic>('/followups/policy');
      return jsonStrList(
        mapOf(resp.data),
        'own_addresses',
      ).map((a) => a.toLowerCase()).toList();
    } on Object {
      return const <String>[];
    }
  }

  Future<void> done(String id) => _dio.post<dynamic>('/followups/$id/done');

  Future<void> dismiss(String id) =>
      _dio.post<dynamic>('/followups/$id/dismiss');

  Future<void> snooze(String id, DateTime until) => _dio.post<dynamic>(
    '/followups/$id/snooze',
    data: <String, dynamic>{'until': until.toUtc().toIso8601String()},
  );

  /// Confirm «l'ho inviato» from one's own client: the expectation advances to
  /// `reminded` and the counters bump.
  Future<void> markReminded(String id) =>
      _dio.post<dynamic>('/followups/$id/reminded');

  /// LLM draft in the thread's language, matching the register/style used with this
  /// counterpart (solleciti v2). All options default, so an empty call is the base case.
  Future<ReminderDraft> draftReminder(
    String id, {
    String instructions = '',
    String register = '',
    String language = '',
    bool? includeOriginal,
  }) async {
    final resp = await _dio.post<dynamic>(
      '/followups/$id/draft-reminder',
      data: <String, dynamic>{
        'instructions': instructions,
        'register': register,
        'language': language,
        'include_original': includeOriginal,
      },
    );
    return ReminderDraft.fromJson(mapOf(resp.data));
  }

  /// Full composed preview (message + signature) via the SAME server compose path as
  /// the .eml / automatic reminder — never a client-side copy. `body` is the message
  /// plain text, `bodyHtml` the message HTML from the editor.
  Future<ReminderPreview> reminderPreview(
    String id, {
    required String subject,
    required String body,
    String bodyHtml = '',
    bool? includeOriginal,
  }) async {
    final resp = await _dio.post<dynamic>(
      '/followups/$id/reminder-preview',
      data: <String, dynamic>{
        'subject': subject,
        'body': body,
        'body_html': bodyHtml,
        'include_original': includeOriginal,
      },
    );
    return ReminderPreview.fromJson(mapOf(resp.data));
  }

  /// «Invia da Cerca posta»: send the composed reminder THROUGH THE ORIGIN ACCOUNT
  /// (per-source SMTP / Graph / EWS). On success the expectation advances like
  /// «l'ho inviato». Returns the From address the message went out from.
  Future<String> sendReminder(
    String id, {
    required String subject,
    required String body,
    String bodyHtml = '',
    bool? includeOriginal,
  }) async {
    final resp = await _dio.post<dynamic>(
      '/followups/$id/send-reminder',
      data: <String, dynamic>{
        'subject': subject,
        'body': body,
        'body_html': bodyHtml,
        'include_original': includeOriginal,
      },
    );
    return jsonStr(mapOf(resp.data), 'from_address');
  }

  /// «Ricorda per questo contatto» (solleciti v2): merge the tu/lei register into the
  /// policy's contact_overrides server-side (no full-policy round-trip).
  Future<void> contactRegister(String match, String register) =>
      _dio.post<dynamic>(
        '/followups/contact-register',
        data: <String, dynamic>{'match': match, 'register': register},
      );
}
