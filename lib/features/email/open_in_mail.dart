import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/services/message_api.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/widgets/snack.dart';

/// Filesystem-safe file name: the `.eml` is created on disk named after the subject, so a subject
/// with `/ \ : * ? " < > |` must not break the path.
String _safeName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
  return cleaned.isEmpty ? 'email' : cleaned;
}

/// «Apri nell'app di posta»: download the message as a viewer-friendly `.eml` (composed by the
/// server with inline `cid:` images flattened to self-contained `data:` URIs, so embedded images
/// render outside the app) and hand it to the OS default handler for `.eml` via [OpenFilex]. When
/// no app can open it, fall back to the system share sheet so the user can still route it to a
/// mail app.
///
/// Disk hygiene (docs/mobile-apps.md §6 «regola ferrea»: no cleartext mail body kept on disk):
/// open_filex needs a real file path, so the `.eml` goes into a dedicated temp subdir that is
/// PURGED at the start of every call — at most one transient file exists between opens, and the OS
/// clears its cache dir on top. We never keep a persistent cleartext cache.
Future<void> openInMailApp(
  BuildContext context,
  MessageApi api,
  String messageId,
  String subject,
) async {
  final l = AppLocalizations.of(context)!;
  try {
    final bytes = await _fetchEml(api, messageId);
    final path = await _writeTempEml(bytes, subject);
    final result = await OpenFilex.open(path, type: 'message/rfc822');
    if (result.type == ResultType.done) return;
    // No handler (or the open failed) → share sheet fallback: the user picks a mail app there.
    if (context.mounted) {
      await _shareEmlFallback(bytes, subject);
    }
  } on Object {
    if (context.mounted) showSnack(context, l.openMailError, error: true);
  }
}

/// Prefer the viewer-friendly `.eml` (inline images flattened to `data:`); fall back to the raw
/// `.eml` when the server is older and doesn't expose the endpoint yet (404/405), so «apri
/// nell'app di posta» still works against a not-yet-updated server — just without the flattening.
Future<Uint8List> _fetchEml(MessageApi api, String messageId) async {
  try {
    return await api.viewerEml(messageId);
  } on Object catch (e) {
    final code = ApiException.from(e).statusCode;
    if (code == 404 || code == 405) return api.rawEml(messageId);
    rethrow;
  }
}

/// Write the `.eml` into a dedicated temp subdir, purging any previous file first so no cleartext
/// mail accumulates on disk (best-effort — a locked previous file must not block a new open).
Future<String> _writeTempEml(Uint8List bytes, String subject) async {
  final base = await getTemporaryDirectory();
  final dir = Directory('${base.path}/outgoing_eml');
  try {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  } on Object {
    // ignore: proceed to (re)create and overwrite
  }
  dir.createSync(recursive: true);
  final file = File('${dir.path}/${_safeName(subject)}.eml');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> _shareEmlFallback(Uint8List bytes, String subject) {
  final name = '${_safeName(subject)}.eml';
  return SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile.fromData(bytes, mimeType: 'message/rfc822', name: name),
      ],
      fileNameOverrides: <String>[name],
    ),
  );
}
