import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../shared/models/chat.dart';
import '../api_exception.dart';
import '../json.dart';

class ChatStatus {
  const ChatStatus({required this.aiEnabled, required this.llmConfigured});
  final bool aiEnabled;
  final bool llmConfigured;

  bool get available => aiEnabled && llmConfigured;

  factory ChatStatus.fromJson(Map<String, dynamic> j) => ChatStatus(
    aiEnabled: jsonBool(j, 'ai_enabled'),
    llmConfigured: jsonBool(j, 'llm_configured'),
  );
}

class ChatApi {
  ChatApi(this._dio);
  final Dio _dio;

  Future<ChatStatus> status() async {
    final resp = await _dio.get<dynamic>('/chat/status');
    return ChatStatus.fromJson(mapOf(resp.data));
  }

  Future<List<ConversationInfo>> conversations() async {
    final resp = await _dio.get<dynamic>('/conversations');
    return listOf(resp.data).map(ConversationInfo.fromJson).toList();
  }

  Future<void> deleteConversation(String id) async {
    await _dio.delete<dynamic>('/conversations/$id');
  }

  Future<void> renameConversation(String id, String title) async {
    await _dio.patch<dynamic>(
      '/conversations/$id',
      data: <String, dynamic>{'title': title},
    );
  }

  Future<List<ChatMessage>> conversationMessages(String id) async {
    final resp = await _dio.get<dynamic>('/conversations/$id/messages');
    return listOf(resp.data)
        .map(
          (j) => ChatMessage(
            role: jsonStr(j, 'role', 'assistant'),
            content: jsonStr(j, 'content'),
            citations: jsonObjList(
              j,
              'citations',
            ).map(Citation.fromJson).toList(),
          ),
        )
        .toList();
  }

  /// SSE stream of /chat/stream. Each frame is `data: {json}`; we buffer chunks
  /// (which may split a frame) and decode on `\n\n` boundaries, discriminating
  /// on the JSON `type` field. An in-stream {type:error} arrives with HTTP 200.
  Stream<ChatStreamEvent> stream({
    required String message,
    required List<Map<String, String>> history,
    String? conversationId,
    CancelToken? cancelToken,
  }) async* {
    final Response<ResponseBody> resp;
    try {
      resp = await _dio.post<ResponseBody>(
        '/chat/stream',
        data: <String, dynamic>{
          'message': message,
          'history': history,
          if (conversationId != null) 'conversation_id': conversationId,
        },
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero, // streaming: no idle timeout
          headers: <String, dynamic>{'Accept': 'text/event-stream'},
        ),
      );
    } on DioException catch (e) {
      // Pre-stream HTTP errors (409/422/423…) carry a STREAMED body: drain and
      // decode it so the UI gets the real error.code, not a generic message.
      throw await ApiException.fromAsync(e);
    }
    final body = resp.data;
    if (body == null) return;

    var buffer = '';
    // Streaming UTF-8 decode: a multibyte character split across two chunks must
    // not be corrupted (per-chunk utf8.decode would emit U+FFFD at the seam).
    final text = body.stream.cast<List<int>>().transform(
      const Utf8Decoder(allowMalformed: true),
    );
    await for (final chunk in text) {
      buffer += chunk.replaceAll(
        '\r',
        '',
      ); // tolerate CRLF framing from proxies
      var idx = buffer.indexOf('\n\n');
      while (idx != -1) {
        final block = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);
        final ev = _parseBlock(block);
        if (ev != null) yield ev;
        idx = buffer.indexOf('\n\n');
      }
    }
    final tail = _parseBlock(buffer);
    if (tail != null) yield tail;
  }

  ChatStreamEvent? _parseBlock(String block) {
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      final l = line.trimRight();
      if (l.startsWith('data:')) dataLines.add(l.substring(5).trimLeft());
    }
    if (dataLines.isEmpty) return null;
    final payload = dataLines.join('\n');
    if (payload.isEmpty || payload == '[DONE]') return null;
    try {
      final obj = jsonDecode(payload);
      if (obj is Map<String, dynamic>) return ChatStreamEvent.tryParse(obj);
    } on FormatException {
      return null;
    }
    return null;
  }
}
