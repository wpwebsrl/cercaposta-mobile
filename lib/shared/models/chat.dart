import 'dart:convert';

import '../../core/api/json.dart';
import 'memory.dart';

/// A citation [n] that links to message `id`.
class Citation {
  const Citation({
    required this.n,
    required this.id,
    required this.subject,
    required this.fromName,
    required this.fromAddress,
    required this.date,
    required this.snippet,
    required this.folder,
    this.used = true,
  });

  final int n;
  final String id;
  final String subject;
  final String fromName;
  final String fromAddress;
  final DateTime? date;
  final String snippet;
  final String? folder;

  /// La risposta la cita davvero. `false` = letta e non usata: si mostra lo stesso, smorzata,
  /// altrimenti il suo numero mancherebbe dall'elenco mentre nella risposta si vede. Campo
  /// additivo: assente (server vecchio) vale «usata».
  final bool used;

  String get fromLabel => fromName.isNotEmpty ? fromName : fromAddress;

  factory Citation.fromJson(Map<String, dynamic> j) => Citation(
    n: jsonInt(j, 'n'),
    id: jsonStr(j, 'id'),
    subject: jsonStr(j, 'subject'),
    fromName: jsonStr(j, 'from_name'),
    fromAddress: jsonStr(j, 'from_address'),
    date: jsonDate(j, 'date'),
    snippet: jsonStr(j, 'snippet'),
    folder: jsonStrOrNull(j, 'folder'),
    used: j['used'] != false,
  );
}

enum ChatEventType { phase, activity, token, citations, memory, done, error }

/// One line of the live activity trail (a search / thread-read / stats the engine performed).
class ChatActivity {
  const ChatActivity({required this.kind, required this.label});
  final String kind; // search | thread | stats | contact | followups
  final String label;
}

/// One decoded frame of /chat/stream, NORMALIZED to a small internal vocabulary.
///
/// The wire speaks the Vercel AI SDK "UI Message Stream" protocol (see the backend
/// api/v1/chat.py): data-phase → phase, data-activity → activity, text-delta → token,
/// data-citations → citations, data-memory → memory, message-metadata → done (carrying the
/// RENUMBERED final_answer), error(errorText JSON) → error. Structural frames (start /
/// text-start / text-end / finish) return null and are skipped.
class ChatStreamEvent {
  const ChatStreamEvent({
    required this.type,
    this.phase,
    this.activityKind,
    this.activityLabel,
    this.text,
    this.answer,
    this.conversationId,
    this.title,
    this.citations = const <Citation>[],
    this.learned,
    this.applied = const <AppliedMemory>[],
    this.embeddingFailed = false,
    this.errorCode,
    this.errorDetail,
  });

  final ChatEventType type;
  final String? phase;
  final String? activityKind;
  final String? activityLabel;
  final String? text;
  final String? answer;
  final String? conversationId;
  final String? title;
  final List<Citation> citations;

  /// `memory`: one memory learned during this turn (data-memory).
  final LearnedMemory? learned;

  /// `done`: the memories the server applied to this very answer.
  final List<AppliedMemory> applied;
  final bool embeddingFailed;
  final String? errorCode;
  final String? errorDetail;

  static ChatStreamEvent? tryParse(Map<String, dynamic> j) {
    final data = jsonMap(j, 'data'); // data-* parts carry their payload here
    final meta = jsonMap(j, 'messageMetadata'); // message-metadata payload
    switch (jsonStr(j, 'type')) {
      case 'data-phase':
        return ChatStreamEvent(
          type: ChatEventType.phase,
          phase: jsonStrOrNull(data, 'phase'),
        );
      case 'data-activity':
        return ChatStreamEvent(
          type: ChatEventType.activity,
          activityKind: jsonStr(data, 'kind'),
          activityLabel: jsonStr(data, 'label'),
        );
      case 'text-delta':
        return ChatStreamEvent(
          type: ChatEventType.token,
          text: jsonStr(j, 'delta'),
        );
      case 'data-citations':
        return ChatStreamEvent(
          type: ChatEventType.citations,
          citations: jsonObjList(
            data,
            'citations',
          ).map(Citation.fromJson).toList(),
        );
      case 'data-memory':
        return ChatStreamEvent(
          type: ChatEventType.memory,
          learned: LearnedMemory.fromJson(data),
        );
      case 'message-metadata':
        return ChatStreamEvent(
          type: ChatEventType.done,
          answer: jsonStr(meta, 'final_answer'),
          conversationId: jsonStrOrNull(meta, 'conversation_id'),
          title: jsonStrOrNull(meta, 'title'),
          embeddingFailed: jsonBool(meta, 'embedding_failed'),
          applied: jsonObjList(
            meta,
            'applied_memories',
          ).map(AppliedMemory.fromJson).toList(),
        );
      case 'error':
        return _errorEvent(jsonStr(j, 'errorText'));
      default:
        // start / text-start / text-end / finish are structural — skip them.
        return null;
    }
  }

  /// The `error` frame's errorText is a JSON string `{code, error, detail}`; parse the machine
  /// code out so the UI can translate `errors.<code>` (falling back to the raw text as detail).
  static ChatStreamEvent _errorEvent(String raw) {
    var code = 'chat.llm_error';
    String? detail;
    try {
      final obj = jsonDecode(raw);
      if (obj is Map<String, dynamic>) {
        code = jsonStr(obj, 'code', 'chat.llm_error');
        detail = jsonStrOrNull(obj, 'detail');
      }
    } on FormatException {
      detail = raw.isEmpty ? null : raw;
    }
    return ChatStreamEvent(
      type: ChatEventType.error,
      errorCode: code,
      errorDetail: detail,
    );
  }
}

/// A saved conversation from GET /conversations (server-side history).
class ConversationInfo {
  const ConversationInfo({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.lastMessageAt,
    required this.pinned,
  });

  final String id;
  final String title;
  final int messageCount;
  final DateTime? lastMessageAt;
  final bool pinned;

  factory ConversationInfo.fromJson(Map<String, dynamic> j) => ConversationInfo(
    id: jsonStr(j, 'id'),
    title: jsonStr(j, 'title'),
    messageCount: jsonInt(j, 'message_count'),
    lastMessageAt: jsonDate(j, 'last_message_at'),
    pinned: jsonBool(j, 'pinned'),
  );
}

/// A message in the chat UI.
class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.citations = const <Citation>[],
    this.learned = const <LearnedMemory>[],
    this.applied = const <AppliedMemory>[],
  });

  final String role; // user | assistant
  String content;
  List<Citation> citations;

  /// Memories learned while producing THIS turn: the announcement stays with the bubble, so
  /// «annulla» and «non ricordare più» are still there when the user scrolls back to it.
  List<LearnedMemory> learned;

  /// Memories the server applied to this turn — why the answer isn't the one the archive
  /// alone would give.
  List<AppliedMemory> applied;
}
