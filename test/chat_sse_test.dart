import 'dart:convert';
import 'dart:typed_data';

import 'package:cercaposta/core/api/services/chat_api.dart';
import 'package:cercaposta/shared/models/chat.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dio adapter that replays fixed byte chunks as the response stream, so the
/// real SSE parsing in ChatApi.stream can be exercised without a server.
class _FakeStreamAdapter implements HttpClientAdapter {
  _FakeStreamAdapter(this.chunks);
  final List<List<int>> chunks;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      Stream<Uint8List>.fromIterable(chunks.map(Uint8List.fromList)),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatApi _api(List<List<int>> chunks) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = _FakeStreamAdapter(chunks);
  return ChatApi(dio);
}

/// Serialize objects as the AI SDK "UI Message Stream": one `data: <json>` line per chunk,
/// terminated by `data: [DONE]`. Mirror of the backend test_chat_stream_api.py fixtures.
String _sse(List<Map<String, dynamic>> chunks) =>
    '${chunks.map((c) => 'data: ${jsonEncode(c)}\n\n').join()}data: [DONE]\n\n';

Future<List<ChatStreamEvent>> _events(List<List<int>> chunks) => _api(
  chunks,
).stream(message: 'q', history: const <Map<String, String>>[]).toList();

void main() {
  test(
    'normalizes UI-message frames across split chunks and drops [DONE]',
    () async {
      // The wire speaks the AI SDK protocol; ChatApi normalizes it to our canonical events. The
      // streamed text ([nothing here]) and the settled final_answer both say "Ciao mondo".
      final body = _sse(<Map<String, dynamic>>[
        <String, dynamic>{'type': 'start'},
        <String, dynamic>{
          'type': 'data-phase',
          'transient': true,
          'data': <String, dynamic>{'phase': 'understanding', 'round': 1},
        },
        <String, dynamic>{
          'type': 'data-activity',
          'transient': true,
          'data': <String, dynamic>{
            'kind': 'search',
            'label': 'fattura 7',
            'round': 1,
          },
        },
        <String, dynamic>{'type': 'text-delta', 'id': 't1', 'delta': 'Ciao '},
        <String, dynamic>{'type': 'text-delta', 'id': 't1', 'delta': 'mondo'},
        <String, dynamic>{
          'type': 'data-citations',
          'data': <String, dynamic>{
            'citations': <Map<String, dynamic>>[
              <String, dynamic>{'n': 1, 'id': 'E1', 'subject': 'Fattura 7'},
            ],
          },
        },
        <String, dynamic>{
          'type': 'message-metadata',
          'messageMetadata': <String, dynamic>{
            'conversation_id': 'c1',
            'final_answer': 'Ciao mondo',
            'embedding_failed': false,
          },
        },
        <String, dynamic>{'type': 'finish'},
      ]);
      final bytes = utf8.encode(body);
      final n = bytes.length;
      // Split mid-frame to exercise the cross-chunk buffering.
      final chunks = <List<int>>[
        bytes.sublist(0, n ~/ 3),
        bytes.sublist(n ~/ 3, 2 * n ~/ 3),
        bytes.sublist(2 * n ~/ 3),
      ];
      final events = await _events(chunks);
      // start / finish are structural → dropped; the rest are canonical events.
      expect(events.map((e) => e.type).toList(), <ChatEventType>[
        ChatEventType.phase,
        ChatEventType.activity,
        ChatEventType.token,
        ChatEventType.token,
        ChatEventType.citations,
        ChatEventType.done,
      ]);
      expect(events[0].phase, 'understanding');
      expect(events[1].activityKind, 'search');
      expect(events[1].activityLabel, 'fattura 7');
      expect(events[2].text, 'Ciao ');
      final citations = events.firstWhere(
        (e) => e.type == ChatEventType.citations,
      );
      expect(citations.citations.single.n, 1);
      final done = events.last;
      expect(done.answer, 'Ciao mondo'); // renumbered final_answer
      expect(done.conversationId, 'c1');
      expect(done.embeddingFailed, false);
    },
  );

  test('decodes a multibyte char split across two chunks', () async {
    final body = _sse(<Map<String, dynamic>>[
      <String, dynamic>{'type': 'text-delta', 'id': 't1', 'delta': 'perché'},
    ]);
    final bytes = utf8.encode(body);
    final idx = bytes.indexOf(0xC3); // first byte of "é"
    final chunks = <List<int>>[
      bytes.sublist(0, idx + 1),
      bytes.sublist(idx + 1),
    ];
    final events = await _events(chunks);
    expect(events.single.text, 'perché');
  });

  test(
    'in-stream error frame surfaces as an error event with the machine code',
    () async {
      final body = _sse(<Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'error',
          'errorText': jsonEncode(<String, dynamic>{
            'code': 'chat.llm_error',
            'detail': 'boom',
          }),
        },
      ]);
      final events = await _events(<List<int>>[utf8.encode(body)]);
      expect(events.single.type, ChatEventType.error);
      expect(events.single.errorCode, 'chat.llm_error');
      expect(events.single.errorDetail, 'boom');
    },
  );
}
