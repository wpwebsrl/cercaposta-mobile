import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/message.dart';
import '../../shared/tag_colors.dart';
import '../../shared/widgets/mail_web_view.dart';
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
  bool _detailsOpen = false;
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

  /// Open a link tapped inside the email body. This is the single place that decides which
  /// schemes an archived email may send the user to: http/https/mailto only, matching the web and
  /// desktop readers. Anything else is dropped silently — the view never navigates regardless
  /// (see [MailWebView]), so a refused scheme simply does nothing.
  Future<void> _onTapUrl(String url) async {
    final l = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !<String>{'http', 'https', 'mailto'}.contains(uri.scheme)) {
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) showSnack(context, l.emailLinkError, error: true);
    } on Object {
      if (mounted) showSnack(context, l.emailLinkError, error: true);
    }
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
      bottomNavigationBar: d == null || _loading || _error != null
          ? null
          : _bottomBar(l, d, locale),
    );
  }

  /// The body owns the screen, as in a real mail client: a one-line header that opens on tap,
  /// the body filling everything below it with its own scrolling, and attachments/thread reachable
  /// from a bar at the bottom. The body CANNOT go in a scrolling list any more: the engine renders
  /// into its own viewport and has no measurable height, so it needs a bounded box — which is also
  /// why nesting it in a list would leave two scrollers fighting over the same finger.
  Widget _content(
    BuildContext context,
    AppLocalizations l,
    MessageDetail d,
    String locale,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Read through a folder share: say whose archive this is (read-only).
        if (d.sharedOwnerName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.surfaceContainerHigh,
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
        _headerStrip(context, l, d, locale),
        // Expanded details take their natural height, capped: a mail with thirty recipients must
        // not push the body off the screen.
        if (_detailsOpen)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _details(context, l, d, locale),
            ),
          ),
        const Divider(height: 1),
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
        Expanded(child: _body(context, d)),
      ],
    );
  }

  /// The email body itself. HTML goes to a real engine; plain text stays on a Flutter widget —
  /// two different renderers, so they are switched between rather than merged.
  Widget _body(BuildContext context, MessageDetail d) {
    if (d.bodyHtml != null && d.bodyHtml!.isNotEmpty) {
      return MailWebView(
        document: buildReaderDocument(d.bodyHtml!, allowRemote: _allowRemote),
        onTapUrl: _onTapUrl,
      );
    }
    if (d.bodyText.isNotEmpty) {
      return Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            d.bodyText,
            style: const TextStyle(color: Color(0xFF1B1F24), fontSize: 13.5),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// One line: who wrote it, when, and a chevron for everything else.
  Widget _headerStrip(
    BuildContext context,
    AppLocalizations l,
    MessageDetail d,
    String locale,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _detailsOpen = !_detailsOpen),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 14,
              child: Text(
                d.fromLabel.isNotEmpty
                    ? d.fromLabel.substring(0, 1).toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                d.fromLabel.isEmpty ? d.fromAddress : d.fromLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (d.isPec)
              Container(
                margin: const EdgeInsets.only(left: 6),
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
            if (d.dateSent != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  formatDateShort(d.dateSent, locale),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Icon(
              _detailsOpen ? Icons.expand_less : Icons.expand_more,
              size: 20,
              semanticLabel: l.emailDetails,
            ),
          ],
        ),
      ),
    );
  }

  /// Everything the one-line header leaves out — shown only when it is opened.
  Widget _details(
    BuildContext context,
    AppLocalizations l,
    MessageDetail d,
    String locale,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (d.fromAddress.isNotEmpty && d.fromAddress != d.fromLabel)
        _line(context, l.emailFrom, d.fromAddress),
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
    ],
  );

  /// Attachments and thread, one tap away instead of below a body that now never ends.
  Widget? _bottomBar(AppLocalizations l, MessageDetail d, String locale) {
    if (d.attachments.isEmpty && d.threadId == null) return null;
    return BottomAppBar(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          if (d.attachments.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showAttachments(l, d, locale),
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(l.attachmentsCount(d.attachments.length)),
            ),
          const Spacer(),
          if (d.threadId != null)
            TextButton.icon(
              onPressed: () => _showThread(l, locale),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: Text(l.emailThread),
            ),
        ],
      ),
    );
  }

  Future<void> _showAttachments(
    AppLocalizations l,
    MessageDetail d,
    String locale,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Text(l.emailAttachments, style: Theme.of(ctx).textTheme.titleSmall),
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
                  ctx,
                  ref.read(messageApiProvider),
                  d.id,
                  a.id,
                  a.filename,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(
                  '/message/${d.id}/attachment/${a.id}',
                  extra: a.filename,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showThread(AppLocalizations l, String locale) async {
    if (_thread.isEmpty) await _loadThread();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: _thread.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.emailThreadEmpty, textAlign: TextAlign.center),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: <Widget>[
                  Text(
                    l.emailThread,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
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
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                      onTap: t.id == widget.messageId
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              context.push('/message/${t.id}');
                            },
                    ),
                  ),
                ],
              ),
      ),
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
