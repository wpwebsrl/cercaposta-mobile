import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cercaposta/core/api/services/message_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves the claim `rawHeaders` rests on: that the transfer is torn down once the
/// header block ends, instead of pulling the whole `.eml` — attachments and all — down
/// a mobile connection.
///
/// The fake transport honours `cancelFuture` exactly as Dio's real adapter does, and
/// pushes body chunks only while the request is alive. Measuring the returned text
/// alone would prove nothing: an earlier version of this code returned the right
/// headers while quietly downloading everything behind them, because leaving an
/// `await for` does NOT cancel the underlying request.
class _FakeTransport implements HttpClientAdapter {
  _FakeTransport({required this.headers});

  final String headers;

  /// ~12 MB queued behind the headers, standing in for a fat attachment.
  static const bodyChunks = 200;
  int chunksPushed = 0;
  bool cancelled = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    late StreamController<Uint8List> ctrl;
    // 64 KB per chunk, the size a base64 attachment really arrives in.
    final blob = Uint8List.fromList(List<int>.filled(64 * 1024, 0x41));

    cancelFuture?.then((_) {
      cancelled = true;
      if (!ctrl.isClosed) ctrl.close();
    });

    Future<void> pump() async {
      ctrl.add(Uint8List.fromList(utf8.encode(headers)));
      for (var i = 0; i < bodyChunks && !cancelled; i++) {
        await Future<void>.delayed(Duration.zero);
        if (cancelled || ctrl.isClosed) break;
        chunksPushed++;
        ctrl.add(blob);
      }
      if (!ctrl.isClosed) await ctrl.close();
    }

    ctrl = StreamController<Uint8List>(onListen: () => unawaited(pump()));
    return ResponseBody(ctrl.stream, 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('returns the headers and tears the transfer down', () async {
    final t = _FakeTransport(
      headers:
          'From: mario@example.it\r\n'
          'To: anna@example.it\r\n'
          'Subject: Preventivo\r\n'
          '\r\n',
    );
    final dio = Dio()..httpClientAdapter = t;

    final headers = await MessageApi(dio).rawHeaders('m1');
    // The cancel reaches the transport on a later microtask; give it that turn before
    // asking whether the request was torn down.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(headers, contains('Subject: Preventivo'));
    expect(headers, contains('To: anna@example.it'));
    expect(headers, isNot(contains('AAAA')), reason: 'body must not leak in');
    expect(t.cancelled, isTrue, reason: 'the request must be cancelled');
    // ~12 MB were queued behind the headers; next to none of it may be pushed.
    expect(
      t.chunksPushed,
      lessThan(5),
      reason: 'the attachments must not be transferred',
    );
  });

  test('headers that never close stop at the cap', () async {
    // Pathological message with no blank line: without the ceiling this would buffer
    // the whole thing into memory, the exact failure the cap exists to prevent.
    final t = _FakeTransport(headers: 'From: mario@example.it\r\n');
    final dio = Dio()..httpClientAdapter = t;

    final headers = await MessageApi(dio).rawHeaders('m1');
    // The cancel reaches the transport on a later microtask; give it that turn before
    // asking whether the request was torn down.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(headers.length, lessThanOrEqualTo(256 * 1024));
    expect(t.cancelled, isTrue);
    expect(t.chunksPushed, lessThan(10), reason: 'must stop at the cap');
  });
}
