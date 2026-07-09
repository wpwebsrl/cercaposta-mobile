import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/api_providers.dart';
import '../../core/auth/auth_controller.dart';
import '../../shared/models/chat.dart';

class ChatState {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.streaming = false,
    this.phase,
    this.error,
    this.available,
    this.aiEnabled,
    this.embeddingFailed = false,
    this.statusFailed = false,
  });

  final List<ChatMessage> messages;
  final bool streaming;
  final String? phase;
  final Object? error;
  final bool? available; // null = unknown (status not yet checked)
  final bool? aiEnabled; // to pick the right "unavailable" message
  final bool embeddingFailed;

  /// The chat status check failed on the network (not "server says disabled"):
  /// the UI offers a retry instead of the misleading "not configured" message.
  final bool statusFailed;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? streaming,
    String? phase,
    Object? error,
    bool? available,
    bool? aiEnabled,
    bool? embeddingFailed,
    bool? statusFailed,
  }) => ChatState(
    messages: messages ?? this.messages,
    streaming: streaming ?? this.streaming,
    phase: phase,
    error: error,
    available: available ?? this.available,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    embeddingFailed: embeddingFailed ?? this.embeddingFailed,
    statusFailed: statusFailed ?? this.statusFailed,
  );
}

class ChatController extends Notifier<ChatState> {
  String? _conversationId;
  CancelToken? _cancel;
  String? _lastSent;

  @override
  ChatState build() {
    // Reset on logout/user switch/server switch: the in-memory conversation
    // (and its id) belongs to the previous identity.
    ref.watch(sessionKeyProvider);
    _conversationId = null;
    return const ChatState();
  }

  Future<void> checkStatus() async {
    try {
      final s = await ref.read(chatApiProvider).status();
      state = state.copyWith(
        available: s.available,
        aiEnabled: s.aiEnabled,
        statusFailed: false,
      );
    } on Object {
      // Network failure (not "server says disabled"): keep `available` unknown
      // and flag it so the UI offers a retry rather than "not configured".
      state = state.copyWith(statusFailed: true);
    }
  }

  void newConversation() {
    _conversationId = null;
    state = ChatState(available: state.available, aiEnabled: state.aiEnabled);
  }

  /// Load a persisted conversation from the server-side history.
  Future<void> loadConversation(String id) async {
    if (state.streaming) return;
    try {
      final msgs = await ref.read(chatApiProvider).conversationMessages(id);
      _conversationId = id;
      state = state.copyWith(
        messages: msgs,
        error: null,
        embeddingFailed: false,
      );
    } on Object catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Drop a trailing still-empty assistant bubble (stream failed before any token).
  List<ChatMessage> _withoutEmptyTail(List<ChatMessage> msgs) {
    if (msgs.isNotEmpty &&
        msgs.last.role == 'assistant' &&
        msgs.last.content.isEmpty) {
      return msgs.sublist(0, msgs.length - 1);
    }
    return msgs;
  }

  Future<void> send(String text) async {
    if (state.streaming || text.trim().isEmpty) return;
    _lastSent = text;
    final prior = state.messages
        .where((m) => m.content.isNotEmpty)
        .map((m) => <String, String>{'role': m.role, 'content': m.content});
    final history = prior.length > 24
        ? prior.skip(prior.length - 24).toList()
        : prior.toList();

    final assistant = ChatMessage(role: 'assistant', content: '');
    final msgs = <ChatMessage>[
      ...state.messages,
      ChatMessage(role: 'user', content: text),
      assistant,
    ];
    state = state.copyWith(
      messages: msgs,
      streaming: true,
      error: null,
      embeddingFailed: false,
    );

    final cancel = CancelToken();
    _cancel = cancel;
    try {
      final stream = ref
          .read(chatApiProvider)
          .stream(
            message: text,
            history: history,
            conversationId: _conversationId,
            cancelToken: cancel,
          );
      await for (final ev in stream) {
        switch (ev.type) {
          case ChatEventType.phase:
            state = state.copyWith(phase: ev.phase);
          case ChatEventType.token:
            assistant.content += ev.text ?? '';
            // Keep the current phase visible while tokens accumulate.
            state = state.copyWith(
              messages: <ChatMessage>[...msgs],
              phase: state.phase,
            );
          case ChatEventType.done:
            final answer = ev.answer ?? '';
            if (answer.isNotEmpty) assistant.content = answer;
            assistant.citations = ev.citations;
            _conversationId = ev.conversationId ?? _conversationId;
            state = state.copyWith(
              messages: <ChatMessage>[...msgs],
              streaming: false,
              embeddingFailed: ev.embeddingFailed,
            );
          case ChatEventType.error:
            state = state.copyWith(
              messages: _withoutEmptyTail(msgs),
              streaming: false,
              error: ApiException(
                ev.errorCode ?? 'chat.llm_error',
                params: <String, dynamic>{'detail': ev.errorDetail},
              ),
            );
        }
      }
    } on Object catch (e) {
      final cancelled = e is DioException && e.type == DioExceptionType.cancel;
      state = state.copyWith(
        messages: _withoutEmptyTail(msgs),
        streaming: false,
        // A user-initiated stop is not an error: keep the partial answer, no bar.
        error: cancelled ? null : e,
      );
    } finally {
      _cancel = null;
      if (state.streaming) state = state.copyWith(streaming: false);
    }
  }

  /// Stop the in-flight stream (keeps whatever was received so far).
  void stop() => _cancel?.cancel('stopped by user');

  /// Resend the last user turn after an error: drop the trailing user bubble
  /// (its assistant reply failed) and re-stream it.
  Future<void> retryLast() async {
    if (state.streaming) return;
    final msgs = state.messages;
    if (msgs.isNotEmpty && msgs.last.role == 'user') {
      final text = msgs.last.content;
      state = state.copyWith(
        messages: msgs.sublist(0, msgs.length - 1),
        error: null,
      );
      await send(text);
    } else if (_lastSent != null) {
      state = state.copyWith(error: null);
      await send(_lastSent!);
    }
  }

  Future<void> deleteConversation(String id) async {
    await ref.read(chatApiProvider).deleteConversation(id);
    if (_conversationId == id) newConversation();
  }

  Future<void> renameConversation(String id, String title) async {
    await ref.read(chatApiProvider).renameConversation(id, title);
  }
}

final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
