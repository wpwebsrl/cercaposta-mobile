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

void main() {
  test('yields phase/token/done across split frames and drops [DONE]', () async {
    const body =
        'data: {"type":"phase","phase":"searching"}\n\n'
        'data: {"type":"token","text":"Ciao "}\n\n'
        'data: {"type":"token","text":"mondo"}\n\n'
        'data: {"type":"done","answer":"Ciao mondo","conversation_id":"c1"}\n\n'
        'data: [DONE]\n\n';
    final bytes = utf8.encode(body);
    // Split mid-frame to exercise the cross-chunk buffering.
    final chunks = <List<int>>[
      bytes.sublist(0, 25),
      bytes.sublist(25, 60),
      bytes.sublist(60),
    ];
    final events = await _api(
      chunks,
    ).stream(message: 'q', history: const <Map<String, String>>[]).toList();
    expect(events.map((e) => e.type).toList(), <ChatEventType>[
      ChatEventType.phase,
      ChatEventType.token,
      ChatEventType.token,
      ChatEventType.done,
    ]);
    expect(events[1].text, 'Ciao ');
    expect(events.last.answer, 'Ciao mondo');
    expect(events.last.conversationId, 'c1');
  });

  test('decodes a multibyte char split across two chunks', () async {
    const body = 'data: {"type":"token","text":"perché"}\n\n';
    final bytes = utf8.encode(body);
    final idx = bytes.indexOf(0xC3); // first byte of "é"
    final chunks = <List<int>>[
      bytes.sublist(0, idx + 1),
      bytes.sublist(idx + 1),
    ];
    final events = await _api(
      chunks,
    ).stream(message: 'q', history: const <Map<String, String>>[]).toList();
    expect(events.single.text, 'perché');
  });

  test('in-stream error frame surfaces as an error event', () async {
    const body =
        'data: {"type":"error","code":"chat.llm_error","detail":"boom"}\n\n';
    final events = await _api(<List<int>>[
      utf8.encode(body),
    ]).stream(message: 'q', history: const <Map<String, String>>[]).toList();
    expect(events.single.type, ChatEventType.error);
    expect(events.single.errorCode, 'chat.llm_error');
    expect(events.single.errorDetail, 'boom');
  });
}
