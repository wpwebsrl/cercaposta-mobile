import 'dart:convert';

import 'package:dio/dio.dart';
// foundation re-exports @visibleForTesting; using it avoids declaring `meta` as a
// direct dependency just for one annotation.
import 'package:flutter/foundation.dart';

import '../../../shared/models/message.dart';
import '../json.dart';

/// Hard stop for the header read: a header block larger than this is pathological,
/// and without a ceiling a malformed message with no blank line would stream its
/// whole body into memory — the very thing the early cut-off exists to avoid.
const _headersCapBytes = 256 * 1024;

/// Bytes of an attachment preview kept in memory (never written to disk, per the
/// encryption posture in docs/mobile-apps.md §6).
typedef PreviewData = ({Uint8List bytes, String contentType});

class MessageApi {
  MessageApi(this._dio);
  final Dio _dio;

  Future<MessageDetail> get(String id, {bool allowRemote = false}) async {
    final resp = await _dio.get<dynamic>(
      '/messages/$id',
      queryParameters: allowRemote
          ? <String, dynamic>{'allow_remote': true}
          : null,
    );
    return MessageDetail.fromJson(mapOf(resp.data));
  }

  Future<List<ThreadEntry>> thread(String id) async {
    final resp = await _dio.get<dynamic>('/messages/$id/thread');
    return listOf(resp.data).map(ThreadEntry.fromJson).toList();
  }

  /// Fetch the rendered preview (PDF/image; Office → PDF server-side) as bytes.
  /// Auth is the Bearer added by the interceptor — never a presigned URL.
  Future<PreviewData> previewBytes(
    String messageId,
    String attachmentId,
  ) async {
    final resp = await _dio.get<List<int>>(
      '/messages/$messageId/attachments/$attachmentId/preview',
      options: Options(responseType: ResponseType.bytes),
    );
    final contentType =
        resp.headers.value('content-type') ?? 'application/octet-stream';
    return (
      bytes: Uint8List.fromList(resp.data ?? const <int>[]),
      contentType: contentType,
    );
  }

  /// Fetch the ORIGINAL attachment bytes (not the rendered preview): used for
  /// share/save, so the user gets the real file, whatever its type.
  Future<PreviewData> attachmentBytes(
    String messageId,
    String attachmentId,
  ) async {
    final resp = await _dio.get<List<int>>(
      '/messages/$messageId/attachments/$attachmentId',
      options: Options(responseType: ResponseType.bytes),
    );
    final contentType =
        resp.headers.value('content-type') ?? 'application/octet-stream';
    return (
      bytes: Uint8List.fromList(resp.data ?? const <int>[]),
      contentType: contentType,
    );
  }

  /// Fetch the raw `.eml` (RFC822) bytes, for "share email".
  Future<Uint8List> rawEml(String messageId) async {
    final resp = await _dio.get<List<int>>(
      '/messages/$messageId/raw',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(resp.data ?? const <int>[]);
  }

  /// The message's RFC822 header block: everything before the first blank line.
  ///
  /// Streamed and cut short on purpose. `/raw` returns the faithful `.eml`, which carries
  /// every attachment base64-encoded and can run to tens of megabytes, while the headers
  /// are a few KB — pulling all of it down a metered mobile connection to show a
  /// screenful of text would be wasteful.
  ///
  /// The abort goes through a [CancelToken], NOT through breaking the `await for`:
  /// leaving the loop does not propagate a cancel to the socket (measured — Dio hands
  /// out a wrapped stream, and the source subscription stays alive), so the server would
  /// happily keep pushing the attachments to a reader nobody drains. The token is what
  /// actually tears the request down.
  Future<String> rawHeaders(String messageId) async {
    final token = CancelToken();
    final resp = await _dio.get<ResponseBody>(
      '/messages/$messageId/raw',
      cancelToken: token,
      options: Options(responseType: ResponseType.stream),
    );

    final buf = <int>[];
    try {
      await for (final chunk in resp.data!.stream) {
        buf.addAll(chunk);
        if (headerEnd(buf) >= 0 || buf.length >= _headersCapBytes) break;
      }
    } on DioException catch (e) {
      // The cancel below can surface as an error on the stream we already left; the
      // headers are in hand by then, so only a genuine transport failure matters.
      if (!CancelToken.isCancel(e)) rethrow;
    } finally {
      token.cancel();
    }

    final end = headerEnd(buf);
    final headers = end >= 0
        ? buf.sublist(0, end)
        : buf.sublist(0, buf.length.clamp(0, _headersCapBytes));
    return decodeHeaderBytes(headers);
  }
}

/// Index of the blank line that closes the header block, or -1 while still inside it.
/// RFC 5322 mandates CRLF, but messages mangled by a gateway can carry bare LFs, and a
/// source view that showed nothing for those would be worse than useless.
@visibleForTesting
int headerEnd(List<int> b) {
  for (var i = 0; i + 1 < b.length; i++) {
    if (b[i] == 0x0A && b[i + 1] == 0x0A) return i; // \n\n
    if (i + 3 < b.length &&
        b[i] == 0x0D &&
        b[i + 1] == 0x0A &&
        b[i + 2] == 0x0D &&
        b[i + 3] == 0x0A) {
      return i; // \r\n\r\n
    }
  }
  return -1;
}

/// Headers are ASCII by spec, but legacy senders put raw 8-bit bytes in them. Same
/// ladder as the desktop source viewer: utf-8, then latin-1, never an exception.
@visibleForTesting
String decodeHeaderBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes, allowInvalid: true);
  }
}
