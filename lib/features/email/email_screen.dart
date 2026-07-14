import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/message.dart';
import '../../shared/tag_colors.dart';
import '../../shared/widgets/snack.dart';
import 'share_actions.dart';

class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({required this.messageId, super.key});
  final String messageId;

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  MessageDetail? _detail;
  List<ThreadEntry> _thread = const <ThreadEntry>[];
  bool _loading = true;
  bool _allowRemote = false;
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
      final detail = await ref
          .read(messageApiProvider)
          .get(widget.messageId, allowRemote: _allowRemote);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _loadThread() async {
    try {
      final t = await ref.read(messageApiProvider).thread(widget.messageId);
      if (mounted) setState(() => _thread = t);
    } on Object {
      // thread optional
    }
  }

  /// Open a tapped link in the corpo email. Allowlist http/https/mailto (matching
  /// the desktop hardening); other schemes are ignored so the renderer doesn't act
  /// on them. Returning true means "handled by us" either way.
  Future<bool> _onTapUrl(String url) async {
    final l = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !<String>{'http', 'https', 'mailto'}.contains(uri.scheme)) {
      return false;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) showSnack(context, l.emailLinkError, error: true);
    } on Object {
      if (mounted) showSnack(context, l.emailLinkError, error: true);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(authProvider).user?.locale ?? 'it-IT';
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          d?.subject.isNotEmpty ?? false ? d!.subject : l.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: Text(l.actionRetry)),
                  ],
                ),
              ),
            )
          : _content(context, l, d!, locale),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l,
    MessageDetail d,
    String locale,
  ) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Read through a folder share: say whose archive this is (read-only).
        if (d.sharedOwnerName != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.people_outline,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.sharedReaderBanner(d.sharedOwnerName!),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                d.subject.isEmpty ? '—' : d.subject,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (d.isPec)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l.emailPecBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _kv(context, d.fromLabel, d.fromAddress),
        if (d.to.isNotEmpty) _line(context, l.emailTo, d.to.join(', ')),
        if (d.cc.isNotEmpty) _line(context, l.emailCc, d.cc.join(', ')),
        if (d.bcc.isNotEmpty) _line(context, l.emailBcc, d.bcc.join(', ')),
        if (d.dateSent != null)
          _line(context, l.emailDate, formatDateTime(d.dateSent, locale)),
        if (d.folders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: d.folders
                  .map(
                    (f) => Chip(
                      avatar: const Icon(Icons.folder_outlined, size: 14),
                      label: Text(f),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ),
        if (d.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: d.tags.map((t) => _tagChip(context, t)).toList(),
            ),
          ),
        if (d.isPec && (d.pec?.hasAny ?? false))
          _pecPanel(context, l, d.pec!, locale),
        const Divider(height: 24),
        if (d.rawMissing)
          _notice(context, l.emailRawMissing)
        else if (d.hasRemoteImages && !_allowRemote)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _allowRemote = true);
                _load();
              },
              icon: const Icon(Icons.image_outlined),
              label: Text(l.emailShowRemoteImages),
            ),
          ),
        if (!d.hasBody && !d.rawMissing) _notice(context, l.emailNoBody),
        if (d.bodyHtml != null && d.bodyHtml!.isNotEmpty)
          HtmlWidget(
            d.bodyHtml!,
            onTapUrl: _onTapUrl,
            textStyle: theme.textTheme.bodyMedium,
          )
        else if (d.bodyText.isNotEmpty)
          SelectableText(d.bodyText),
        if (d.attachments.isNotEmpty) ...<Widget>[
          const Divider(height: 24),
          Text(l.emailAttachments, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          ...d.attachments.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(
                a.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(formatSize(a.sizeBytes, locale)),
              trailing: IconButton(
                tooltip: l.attachmentShare,
                icon: const Icon(Icons.share_outlined),
                onPressed: () => shareAttachment(
                  context,
                  ref.read(messageApiProvider),
                  d.id,
                  a.id,
                  a.filename,
                ),
              ),
              onTap: () => context.push(
                '/message/${d.id}/attachment/${a.id}',
                extra: a.filename,
              ),
            ),
          ),
        ],
        if (d.threadId != null) ...<Widget>[
          const Divider(height: 24),
          if (_thread.isEmpty)
            OutlinedButton.icon(
              onPressed: _loadThread,
              icon: const Icon(Icons.forum_outlined),
              label: Text(l.emailThread),
            )
          else ...<Widget>[
            Text(l.emailThread, style: theme.textTheme.titleSmall),
            ..._thread.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  t.subject.isEmpty ? '—' : t.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  t.fromLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  formatDateShort(t.dateSent, locale),
                  style: theme.textTheme.bodySmall,
                ),
                onTap: t.id == widget.messageId
                    ? null
                    : () => context.push('/message/${t.id}'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _pecPanel(
    BuildContext context,
    AppLocalizations l,
    PecInfo pec,
    String locale,
  ) {
    final theme = Theme.of(context);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.verified_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(l.emailPecSection, style: theme.textTheme.labelLarge),
            ],
          ),
          if (pec.transportFrom.isNotEmpty)
            row(l.emailPecTransportFrom, pec.transportFrom),
          if (pec.transportSubject.isNotEmpty)
            row(l.emailPecTransportSubject, pec.transportSubject),
          if (pec.transportDate != null)
            row(
              l.emailPecTransportDate,
              formatDateTime(pec.transportDate, locale),
            ),
          if (pec.hasDaticert)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l.emailPecDaticert, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _tagChip(BuildContext context, TagRef t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: tagColor(t.color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(t.name, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );

  Widget _kv(BuildContext context, String name, String address) => Row(
    children: <Widget>[
      CircleAvatar(
        radius: 14,
        child: Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?'),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (address.isNotEmpty && address != name)
              Text(address, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );

  Widget _line(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );

  Widget _notice(BuildContext context, String text) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
