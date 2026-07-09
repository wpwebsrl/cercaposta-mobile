import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import 'share_actions.dart';

/// In-app attachment preview. Fetches the server-rendered preview (PDF/image;
/// Office → PDF) and renders it from memory — bytes are never written to disk.
class AttachmentViewerScreen extends ConsumerStatefulWidget {
  const AttachmentViewerScreen({
    required this.messageId,
    required this.attachmentId,
    required this.filename,
    super.key,
  });

  final String messageId;
  final String attachmentId;
  final String filename;

  @override
  ConsumerState<AttachmentViewerScreen> createState() =>
      _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState
    extends ConsumerState<AttachmentViewerScreen> {
  Uint8List? _bytes;
  String _contentType = '';
  bool _loading = true;
  Object? _error;
  PdfControllerPinch? _pdf;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(messageApiProvider)
          .previewBytes(widget.messageId, widget.attachmentId);
      PdfControllerPinch? pdf;
      if (data.contentType.startsWith('application/pdf')) {
        try {
          // Open eagerly so a corrupt/protected PDF surfaces here (fallback to the
          // "unsupported" message) instead of hanging the viewer.
          final doc = await PdfDocument.openData(data.bytes);
          pdf = PdfControllerPinch(document: Future<PdfDocument>.value(doc));
        } on Object {
          pdf = null;
        }
      }
      if (!mounted) {
        pdf?.dispose(); // widget left while fetching: don't leak the controller
        return;
      }
      setState(() {
        _bytes = data.bytes;
        _contentType = data.contentType;
        _pdf = pdf;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l.attachmentShare,
            icon: const Icon(Icons.share_outlined),
            // Shares the ORIGINAL attachment (fetched separately), not the
            // rendered preview — so the user gets the real file.
            onPressed: () => shareAttachment(
              context,
              ref.read(messageApiProvider),
              widget.messageId,
              widget.attachmentId,
              widget.filename,
            ),
          ),
        ],
      ),
      body: _build(context, l),
    );
  }

  Widget _build(BuildContext context, AppLocalizations l) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l.attachmentLoading),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(localizeApiError(l, _error!), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(l.actionRetry)),
            ],
          ),
        ),
      );
    }
    final bytes = _bytes;
    if (_pdf != null) {
      return PdfViewPinch(controller: _pdf!);
    }
    if (bytes != null && _contentType.startsWith('image/')) {
      return InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.memory(bytes)),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.description_outlined, size: 48),
            const SizedBox(height: 12),
            Text(l.attachmentUnsupported, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
