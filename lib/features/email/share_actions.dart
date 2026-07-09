import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/services/message_api.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/widgets/snack.dart';

/// Filesystem-safe file name: the OS share sheet writes the shared bytes to a
/// temp file named after this, so a subject with `/ \ : * ? " < > |` must not
/// break the path.
String _safeName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  return cleaned.isEmpty ? 'file' : cleaned;
}

Future<void> _share(Uint8List bytes, String mimeType, String filename) {
  final name = _safeName(filename);
  return SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile.fromData(bytes, mimeType: mimeType, name: name)],
      // XFile.fromData ignores `name` for the shared file on some platforms;
      // fileNameOverrides forces the real filename (and extension) to survive.
      fileNameOverrides: <String>[name],
    ),
  );
}

/// Share an attachment via the OS share sheet (which also offers "Save to Files").
/// The bytes are fetched into memory and handed to share_plus; the OS writes them
/// to its own transient share cache — we never persist a decrypted file ourselves.
Future<void> shareAttachment(
  BuildContext context,
  MessageApi api,
  String messageId,
  String attachmentId,
  String filename,
) async {
  final l = AppLocalizations.of(context)!;
  try {
    final data = await api.attachmentBytes(messageId, attachmentId);
    await _share(data.bytes, data.contentType, filename);
  } on Object {
    if (context.mounted) {
      showSnack(context, l.attachmentShareError, error: true);
    }
  }
}

/// Share the raw `.eml` of a message.
Future<void> shareEml(
  BuildContext context,
  MessageApi api,
  String messageId,
  String subject,
) async {
  final l = AppLocalizations.of(context)!;
  try {
    final bytes = await api.rawEml(messageId);
    await _share(
      bytes,
      'message/rfc822',
      '${_safeName(subject.isEmpty ? messageId : subject)}.eml',
    );
  } on Object {
    if (context.mounted) {
      showSnack(context, l.attachmentShareError, error: true);
    }
  }
}
