import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/memory.dart';
import '../../shared/widgets/snack.dart';

/// «Memoria della chat»: everything the assistant has learned, and the switches that govern
/// whether it keeps learning (docs/memoria-utente.md §7).
///
/// All four states are listed — not just the active ones — because «in prova» is a memory being
/// learned that is NOT yet in use and «rifiutato» is a recorded refusal. Without seeing those
/// two a user has no way to understand why something they once saw never came back, nor to
/// change their mind; with automatic learning on by default, that visibility is what makes the
/// default acceptable.
///
/// Deliberate asymmetry with the web: no form to compose a memory from scratch. It would add no
/// capability — the explicit channel is a sentence in the chat («ricordati che…»), which works
/// from this app too — while a form must mirror the machine vocabularies of `param` and
/// `render` exactly, or it builds memories the engine cannot apply.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  List<Memory> _memories = const <Memory>[];
  List<AliasSuggestion> _suggestions = const <AliasSuggestion>[];
  final Set<String> _dismissed = <String>{}; // waved away for this visit only
  MemoryPolicy _policy = const MemoryPolicy();
  String _filter = 'all';
  bool _loading = true;
  bool _savingPolicy = false;
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
      final api = ref.read(memoryApiProvider);
      final policy = await api.policy();
      final memories = await api.list();
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _memories = memories;
        _loading = false;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
    await _loadSuggestions();
  }

  /// Aliases the archive suggests — computed on demand, written only if the user accepts. A
  /// failure here is a missing hint, never a blocker.
  Future<void> _loadSuggestions() async {
    try {
      final list = await ref.read(memoryApiProvider).suggestions();
      if (mounted) setState(() => _suggestions = list);
    } on Object {
      if (mounted) setState(() => _suggestions = const <AliasSuggestion>[]);
    }
  }

  Future<void> _savePolicy(MemoryPolicy next) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _policy = next; // optimistic: the switch must not lag under the finger
      _savingPolicy = true;
    });
    try {
      final saved = await ref.read(memoryApiProvider).setPolicy(next);
      if (mounted) setState(() => _policy = saved);
    } on Object catch (e) {
      if (mounted) {
        showSnack(context, localizeApiError(l, e), error: true);
        await _load(); // the server said no: show what it actually holds
      }
    } finally {
      if (mounted) setState(() => _savingPolicy = false);
    }
  }

  Future<void> _patch(Memory m, {bool? enabled, bool? rejected}) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(memoryApiProvider)
          .update(m.id, enabled: enabled, rejected: rejected);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  Future<void> _delete(Memory m) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.memoryDelete),
        content: Text(l.memoryDeleteConfirm(m.key)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(memoryApiProvider).delete(m.id);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  Future<void> _accept(AliasSuggestion s) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(memoryApiProvider).acceptSuggestion(s);
      _dismissed.add(s.key);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.memoryTitle)),
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
    final theme = Theme.of(context);
    final rows = _memories
        .where((m) => _filter == 'all' || m.status == _filter)
        .toList();
    final counts = <String, int>{
      for (final s in memoryStatuses)
        s: _memories.where((m) => m.status == s).length,
    };
    return <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(l.memoryIntro, style: theme.textTheme.bodyMedium),
      ),
      // The two switches are NOT the same thing: `learn` stops the automatic channels,
      // `enabled` pauses the memories without losing any of them.
      SwitchListTile(
        secondary: const Icon(Icons.school_outlined),
        title: Text(l.memoryPolicyLearn),
        subtitle: Text(l.memoryPolicyLearnHint),
        isThreeLine: true,
        value: _policy.learn,
        onChanged: _savingPolicy
            ? null
            : (v) => _savePolicy(_policy.copyWith(learn: v)),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.psychology_outlined),
        title: Text(l.memoryPolicyEnabled),
        subtitle: Text(l.memoryPolicyEnabledHint),
        isThreeLine: true,
        value: _policy.enabled,
        onChanged: _savingPolicy
            ? null
            : (v) => _savePolicy(_policy.copyWith(enabled: v)),
      ),
      ..._suggestionSection(context, l),
      const Divider(),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            for (final status in <String>['all', ...memoryStatuses])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(
                    status == 'all' || counts[status] == 0
                        ? _filterLabel(l, status)
                        : '${_filterLabel(l, status)} ${counts[status]}',
                  ),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
              ),
          ],
        ),
      ),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _memories.isEmpty ? l.memoryListEmpty : l.memoryListEmptyFiltered,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      // Grouped by kind, in the order of the four levels: where a memory acts is the first
      // thing that explains its behaviour, so it is also how the list is read.
      for (final kind in memoryKinds)
        if (rows.any((m) => m.kind == kind)) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _kindLabel(l, kind),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final m in rows.where((m) => m.kind == kind)) _row(context, l, m),
        ],
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _suggestionSection(BuildContext context, AppLocalizations l) {
    final rows = _suggestions
        .where((s) => !_dismissed.contains(s.key))
        .toList();
    if (rows.isEmpty) return const <Widget>[];
    final theme = Theme.of(context);
    return <Widget>[
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.memorySuggestionsTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(l.memorySuggestionsHint, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      for (final s in rows)
        ListTile(
          dense: true,
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text('${s.key} → ${s.value}'),
          subtitle: Text('${s.name} · ${l.memorySuggestionsCount(s.count)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l.actionCancel,
                onPressed: () => setState(() => _dismissed.add(s.key)),
              ),
              TextButton(
                onPressed: () => _accept(s),
                child: Text(l.memorySuggestionsAccept),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _row(BuildContext context, AppLocalizations l, Memory m) {
    final theme = Theme.of(context);
    final locale = ref.watch(authProvider).user?.locale ?? 'it-IT';
    final details = <String>[
      _triggerLabel(l, m.trigger),
      _sourceLabel(l, m.source),
      if (m.uses > 0) l.memoryUsedTimes(m.uses),
      if (m.lastUsedAt != null) formatDateTime(m.lastUsedAt, locale),
    ];
    final rejected = m.status == 'rejected';
    return ListTile(
      title: Text('${m.key} → ${m.value}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(details.join(' · '), style: theme.textTheme.bodySmall),
          Text(
            _statusLabel(l, m.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _statusColor(theme, m.status),
            ),
          ),
          if (m.status == 'trial')
            Text(l.memoryStatusTrialHint, style: theme.textTheme.bodySmall),
          if (m.stale && m.status == 'active')
            Text(l.memoryStatusStaleHint, style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (action) => switch (action) {
          'pause' => _patch(m, enabled: m.status == 'disabled'),
          'reject' => _patch(m, rejected: !rejected),
          _ => _delete(m),
        },
        itemBuilder: (ctx) => <PopupMenuEntry<String>>[
          if (!rejected)
            PopupMenuItem<String>(
              value: 'pause',
              child: Text(
                m.status == 'disabled' ? l.memoryEnable : l.memoryDisable,
              ),
            ),
          // Two distinct actions on purpose: «metti in pausa» suspends this memory, «non
          // ricordare più» is a standing refusal that stops it being learned again.
          PopupMenuItem<String>(
            value: 'reject',
            child: Text(rejected ? l.memoryUnreject : l.memoryReject),
          ),
          PopupMenuItem<String>(value: 'delete', child: Text(l.memoryDelete)),
        ],
      ),
    );
  }

  Color? _statusColor(ThemeData theme, String status) => switch (status) {
    'trial' => theme.colorScheme.tertiary,
    'rejected' => theme.colorScheme.error,
    'disabled' => theme.colorScheme.outline,
    _ => theme.colorScheme.primary,
  };

  String _filterLabel(AppLocalizations l, String status) => switch (status) {
    'active' => l.memoryFilterActive,
    'trial' => l.memoryFilterTrial,
    'rejected' => l.memoryFilterRejected,
    'disabled' => l.memoryFilterDisabled,
    _ => l.memoryFilterAll,
  };

  String _statusLabel(AppLocalizations l, String status) => switch (status) {
    'trial' => l.memoryStatusTrial,
    'rejected' => l.memoryStatusRejected,
    'disabled' => l.memoryStatusDisabled,
    _ => l.memoryStatusActive,
  };

  String _kindLabel(AppLocalizations l, String kind) => switch (kind) {
    'alias' => l.memoryKindAlias,
    'param' => l.memoryKindParam,
    'render' => l.memoryKindRender,
    'shortcut' => l.memoryKindShortcut,
    _ => l.memoryKindFact,
  };

  String _triggerLabel(AppLocalizations l, String trigger) => switch (trigger) {
    'search' => l.memoryTriggerSearch,
    'listing' => l.memoryTriggerListing,
    'contact' => l.memoryTriggerContact,
    _ => l.memoryTriggerAlways,
  };

  String _sourceLabel(AppLocalizations l, String source) => switch (source) {
    'correction' => l.memorySourceCorrection,
    'recurrence' => l.memorySourceRecurrence,
    'suggested' => l.memorySourceSuggested,
    'inferred' => l.memorySourceInferred,
    _ => l.memorySourceExplicit,
  };
}
