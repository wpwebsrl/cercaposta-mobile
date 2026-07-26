import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/health.dart';
import '../../shared/widgets/snack.dart';

/// «Diagnostica»: is my archive complete, and if not, why.
///
/// Deliberately NOT a dashboard of numbers. It answers one question at the top and stays boring
/// when the answer is yes; the counters below are fractions, because a bare number says nothing
/// to someone who does not know the scale; and every cause carries the action that belongs to
/// it — «rimetti in coda» when a new attempt can work, «serve l'amministratore» when a configured
/// limit is in the way, nothing when the file type will never be readable.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  ArchiveHealth? _health;
  bool _loading = true;
  bool _retrying = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final ArchiveHealth health = await ref
          .read(healthApiProvider)
          .archiveHealth();
      if (!mounted) return;
      setState(() {
        _health = health;
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

  Future<void> _retry() async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    setState(() => _retrying = true);
    try {
      await ref.read(healthApiProvider).retryExtract();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
    // No confirmation snack: the screen IS the feedback — «da riprovare» drops to zero and «in
    // coda» rises by the same number, which is exactly what happened.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.diagnosticsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(localizeApiError(l, _error!)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: Text(l.actionRetry)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: _body(context, l),
              ),
            ),
    );
  }

  List<Widget> _body(BuildContext context, AppLocalizations l) {
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).languageCode;
    final ArchiveHealth h = _health ?? const ArchiveHealth();
    final MessageHealth msg = h.messages;
    final AttachmentHealth att = h.attachments;

    return <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(l.diagnosticsIntro, style: theme.textTheme.bodyMedium),
      ),
      // The single line that answers the only question worth asking. Green and silent when there
      // is nothing to say — a page that is always shouting stops being read.
      ListTile(
        leading: Icon(switch (h.status) {
          'ok' => Icons.check_circle_outline,
          'working' => Icons.hourglass_top_outlined,
          _ => Icons.warning_amber_outlined,
        }, color: _statusColor(theme, h.status)),
        title: Text(
          switch (h.status) {
            'ok' => l.diagnosticsStatusOk,
            'working' => l.diagnosticsStatusWorking,
            _ => l.diagnosticsStatusAttention,
          },
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _statusColor(theme, h.status),
          ),
        ),
      ),
      if (att.total > 0)
        _coverage(
          theme,
          l.diagnosticsAttachments,
          att.extracted,
          h.readableTotal,
          l,
          locale,
        ),
      _coverage(
        theme,
        l.diagnosticsMessages,
        msg.embedded,
        msg.total,
        l,
        locale,
      ),
      ..._queueNotes(theme, l, locale, msg, att),
      if (att.retryable > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _retrying ? null : _retry,
                icon: const Icon(Icons.refresh),
                label: Text(
                  l.diagnosticsRetryAll(formatCount(att.retryable, locale)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                att.exhausted > 0
                    ? l.diagnosticsRetryExhaustedHint(
                        formatCount(att.exhausted, locale),
                      )
                    : l.diagnosticsRetryHint,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      // Two lists, because they answer two different questions: «missing» is what the user
      // wanted and did not get, «not documents» is the noise of email itself.
      ..._reasonSection(
        theme,
        l,
        locale,
        l.diagnosticsReasonsTitle(formatCount(_sum(h.missing), locale)),
        h.missing,
      ),
      ..._reasonSection(
        theme,
        l,
        locale,
        l.diagnosticsExpectedTitle(formatCount(_sum(h.notDocuments), locale)),
        h.notDocuments,
      ),
      ..._reasonSection(
        theme,
        l,
        locale,
        l.diagnosticsEmbedReasonsTitle(formatCount(msg.errors, locale)),
        h.embedReasons,
      ),
    ];
  }

  static int _sum(List<HealthReason> reasons) =>
      reasons.fold<int>(0, (int n, HealthReason r) => n + r.count);

  Color? _statusColor(ThemeData theme, String status) => switch (status) {
    'ok' => Colors.green.shade700,
    'working' => theme.colorScheme.primary,
    _ => Colors.orange.shade800,
  };

  /// A count WITH its denominator and a bar. «17.644» is neither good nor bad until you know it
  /// is 17.644 of 17.783.
  Widget _coverage(
    ThemeData theme,
    String label,
    int done,
    int total,
    AppLocalizations l,
    String locale,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              l.diagnosticsOf(
                formatCount(done, locale),
                formatCount(total, locale),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: total > 0 ? (done / total).clamp(0, 1).toDouble() : 1,
            minHeight: 6,
          ),
        ),
      ],
    ),
  );

  /// Why the queue is not moving, most blocking first: a backlog waiting for a reason the user
  /// cannot see is indistinguishable from a broken one.
  List<Widget> _queueNotes(
    ThemeData theme,
    AppLocalizations l,
    String locale,
    MessageHealth msg,
    AttachmentHealth att,
  ) {
    final List<String> parts = <String>[
      if (att.pending > 0)
        l.diagnosticsAttachmentsPending(formatCount(att.pending, locale)),
      if (msg.pending > 0)
        l.diagnosticsMessagesPending(formatCount(msg.pending, locale)),
      if (!msg.configured)
        l.diagnosticsEmbeddingOff
      else if (msg.billingPaused)
        l.diagnosticsEmbeddingPaused
      else if (msg.lastErrorAt != null)
        l.diagnosticsEmbeddingLastError(
          formatDateTime(msg.lastErrorAt, locale),
          msg.lastErrorDetail,
        )
      else if (msg.active)
        l.diagnosticsEmbeddingActive,
    ];
    if (parts.isEmpty) return const <Widget>[];
    return <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(parts.join(' · '), style: theme.textTheme.bodySmall),
      ),
    ];
  }

  List<Widget> _reasonSection(
    ThemeData theme,
    AppLocalizations l,
    String locale,
    String title,
    List<HealthReason> reasons,
  ) {
    if (reasons.isEmpty) return const <Widget>[];
    return <Widget>[
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: theme.textTheme.titleSmall),
      ),
      ...reasons.map(
        (HealthReason r) => ListTile(
          dense: true,
          leading: SizedBox(
            width: 56,
            child: Text(
              formatCount(r.count, locale),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          title: Text(reasonLabel(l, r.reason)),
          subtitle: r.extensions.isEmpty
              ? null
              : Text(r.extensions.join(' · ')),
          trailing: Text(
            actionLabel(l, r.action),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    ];
  }
}

/// The generated localizations expose static getters, so a code→label lookup has to be written
/// out. No translation ⇒ the raw code: for an embedding fault that code IS the exception class,
/// and for a pipeline error we have not met yet it is something the user can quote to whoever
/// can act on it — better than a generic «unknown».
String reasonLabel(AppLocalizations l, String code) => switch (code) {
  'tika_http_error' => l.diagnosticsReasonTikaHttpError,
  'tika_timeout' => l.diagnosticsReasonTikaTimeout,
  'tika_server_error' => l.diagnosticsReasonTikaServerError,
  'tika_rejected' => l.diagnosticsReasonTikaRejected,
  'tika_unsupported' => l.diagnosticsReasonTikaUnsupported,
  'extract_backlog_error' => l.diagnosticsReasonExtractBacklogError,
  'unmatched_part' => l.diagnosticsReasonUnmatchedPart,
  'over_size_limit' => l.diagnosticsReasonOverSizeLimit,
  'empty' => l.diagnosticsReasonEmpty,
  'signature_file' => l.diagnosticsReasonSignatureFile,
  'inline_image' => l.diagnosticsReasonInlineImage,
  'unknown' => l.diagnosticsReasonUnknown,
  _ => code,
};

String actionLabel(AppLocalizations l, String action) => switch (action) {
  'retry' => l.diagnosticsActionRetry,
  'ask_admin' => l.diagnosticsActionAskAdmin,
  _ => l.diagnosticsActionNone,
};
