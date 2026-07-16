import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/models/followup.dart';
import '../../shared/widgets/mail_web_view.dart';

/// True-to-recipient preview of the reminder: the full email as it will arrive
/// (signature and inline images included), composed server-side by the SAME path as
/// the .eml / direct send — never a client-side copy. Rendered on the same browser
/// engine as the email reader, at the recipient's own width — see
/// [buildPreviewDocument] for why that width is fixed and not the phone's.
class ReminderPreviewScreen extends ConsumerStatefulWidget {
  const ReminderPreviewScreen({
    super.key,
    required this.followupId,
    required this.item,
    required this.subject,
    required this.body,
    required this.bodyHtml,
    required this.includeOriginal,
  });

  final String followupId;
  final FollowupItem item;
  final String subject;
  final String body;
  final String bodyHtml;
  final bool? includeOriginal;

  @override
  ConsumerState<ReminderPreviewScreen> createState() =>
      _ReminderPreviewScreenState();
}

class _ReminderPreviewScreenState extends ConsumerState<ReminderPreviewScreen> {
  ReminderPreview? _preview;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await ref
          .read(followupApiProvider)
          .reminderPreview(
            widget.followupId,
            subject: widget.subject,
            body: widget.body,
            bodyHtml: widget.bodyHtml,
            includeOriginal: widget.includeOriginal,
          );
      if (!mounted) return;
      setState(() {
        _preview = preview;
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
      appBar: AppBar(title: Text(l.reminderPreviewTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorBody(l)
          : _previewBody(l),
    );
  }

  Widget _errorBody(AppLocalizations l) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(localizeApiError(l, _error!)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: Text(l.actionRetry)),
      ],
    ),
  );

  Widget _previewBody(AppLocalizations l) {
    final preview = _preview!;
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${l.emailTo}: ${item.counterpartLabel}'),
              Text(
                preview.subject,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // The engine brings its own white surface and its own scrolling (hence the Expanded:
        // it needs a bounded height, not a list to grow inside). The signature's images arrive
        // as inline data: URIs, so nothing here reaches the network — and the document's CSP
        // makes sure of it even if the quoted original smuggled a tracking pixel through.
        Expanded(
          child: MailWebView(document: buildPreviewDocument(preview.html)),
        ),
      ],
    );
  }
}
