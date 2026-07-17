import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/widgets/snack.dart';

/// The message's raw RFC822 headers, as the sending mail system wrote them — the
/// mobile counterpart of the desktop source viewer.
///
/// Headers only, and named after what it shows rather than "source": the body and its
/// base64 attachments add nothing here (the reader renders the body, the attachments
/// have their own viewer) and would drag megabytes down a mobile connection. The fetch
/// stops at the blank line closing the header block — see `MessageApi.rawHeaders`.
class MessageHeadersScreen extends ConsumerStatefulWidget {
  const MessageHeadersScreen({super.key, required this.messageId});

  final String messageId;

  @override
  ConsumerState<MessageHeadersScreen> createState() =>
      _MessageHeadersScreenState();
}

class _MessageHeadersScreenState extends ConsumerState<MessageHeadersScreen> {
  String? _headers;
  Object? _error;
  bool _loading = true;

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
      final text = await ref
          .read(messageApiProvider)
          .rawHeaders(widget.messageId);
      if (!mounted) return;
      setState(() {
        _headers = text;
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

  Future<void> _copy() async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _headers ?? ''));
    if (mounted) showSnack(context, l.actionCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasText = (_headers ?? '').trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.emailHeadersTitle),
        actions: <Widget>[
          if (hasText)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: l.actionCopy,
              onPressed: _copy,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      localizeApiError(l, _error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(l.actionRetry),
                    ),
                  ],
                ),
              ),
            )
          : !hasText
          ? Center(child: Text(l.emailHeadersEmpty))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              // Soft-wrapped, unlike the desktop viewer which scrolls sideways: a
              // `Received:` chain is many times wider than a phone, and panning a wall
              // of monospace text to read one line would be worse than wrapping it.
              child: SelectableText(
                _headers!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ),
    );
  }
}
