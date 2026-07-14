import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../shared/models/message.dart';
import '../json.dart';

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
}
