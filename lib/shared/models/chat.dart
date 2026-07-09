import '../../core/api/json.dart';

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
  });

  final int n;
  final String id;
  final String subject;
  final String fromName;
  final String fromAddress;
  final DateTime? date;
  final String snippet;
  final String? folder;

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
  );
}

enum ChatEventType { phase, token, done, error }

/// One decoded SSE frame from /chat/stream (discriminated by the `type` field).
class ChatStreamEvent {
  const ChatStreamEvent({
    required this.type,
    this.phase,
    this.text,
    this.answer,
    this.conversationId,
    this.title,
    this.citations = const <Citation>[],
    this.embeddingFailed = false,
    this.errorCode,
    this.errorDetail,
  });

  final ChatEventType type;
  final String? phase;
  final String? text;
  final String? answer;
  final String? conversationId;
  final String? title;
  final List<Citation> citations;
  final bool embeddingFailed;
  final String? errorCode;
  final String? errorDetail;

  static ChatStreamEvent? tryParse(Map<String, dynamic> j) {
    switch (jsonStr(j, 'type')) {
      case 'phase':
        return ChatStreamEvent(
          type: ChatEventType.phase,
          phase: jsonStrOrNull(j, 'phase'),
        );
      case 'token':
        return ChatStreamEvent(
          type: ChatEventType.token,
          text: jsonStr(j, 'text'),
        );
      case 'done':
        return ChatStreamEvent(
          type: ChatEventType.done,
          answer: jsonStr(j, 'answer'),
          conversationId: jsonStrOrNull(j, 'conversation_id'),
          title: jsonStrOrNull(j, 'title'),
          citations: jsonObjList(
            j,
            'citations',
          ).map(Citation.fromJson).toList(),
          embeddingFailed: jsonBool(j, 'embedding_failed'),
        );
      case 'error':
        return ChatStreamEvent(
          type: ChatEventType.error,
          errorCode: jsonStr(j, 'code', 'chat.llm_error'),
          errorDetail: jsonStrOrNull(j, 'detail') ?? jsonStrOrNull(j, 'error'),
        );
      default:
        return null;
    }
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
  });

  final String role; // user | assistant
  String content;
  List<Citation> citations;
}
