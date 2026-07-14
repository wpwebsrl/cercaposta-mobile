import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/api_providers.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/followup.dart';
import '../../shared/widgets/snack.dart';
import '../notifications/notifications_controller.dart';
import 'followups_controller.dart';

/// «In attesa» page (WP4.3, docs/followup.md): reply expectations in two direction
/// tabs with state actions and reminder composition. Query-only surface — the policy
/// and signature are configured on the web; here the user acts on expectations and,
/// when the origin account can send, fires «Invia da Cerca posta» from the reminder page.
class FollowupsScreen extends ConsumerStatefulWidget {
  const FollowupsScreen({super.key});

  @override
  ConsumerState<FollowupsScreen> createState() => _FollowupsScreenState();
}

enum _RowAction { open, reminder, done, snooze1, snooze3, dismiss }

class _FollowupsScreenState extends ConsumerState<FollowupsScreen> {
  List<FollowupItem> _items = const <FollowupItem>[];
  FollowupStatus? _status;
  bool _loading = true;
  Object? _error;
  bool _unavailable = false; // server too old (404/405 on /followups)
  String _tab = 'their_turn';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ref.read(followupApiProvider);
    try {
      final list = await api.list();
      FollowupStatus? status;
      try {
        status = await api.status();
      } on Object {
        status = null; // best-effort: the page still works without it
      }
      if (!mounted) return;
      setState(() {
        _items = list.items;
        _status = status;
        _unavailable = false;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      final code = ApiException.from(e).statusCode;
      setState(() {
        _loading = false;
        _unavailable = code == 404 || code == 405;
        _error = _unavailable ? null : e;
      });
    }
  }

  Future<void> _act(FollowupItem item, _RowAction action) async {
    final l = AppLocalizations.of(context)!;
    final api = ref.read(followupApiProvider);
    try {
      switch (action) {
        case _RowAction.open:
          context.push('/message/${item.messageId}');
          return;
        case _RowAction.reminder:
          final changed = await context.push<bool>(
            '/followups/reminder',
            extra: item,
          );
          if (changed == true) await _load();
          return;
        case _RowAction.done:
          await api.done(item.id);
        case _RowAction.snooze1:
          await api.snooze(
            item.id,
            DateTime.now().add(const Duration(days: 1)),
          );
        case _RowAction.snooze3:
          await api.snooze(
            item.id,
            DateTime.now().add(const Duration(days: 3)),
          );
        case _RowAction.dismiss:
          await api.dismiss(item.id);
      }
      // The overdue badge count may have changed (done/dismiss/snooze).
      ref.invalidate(notificationUnreadCountProvider);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, _errorText(l, e), error: true);
    }
  }

  String _errorText(AppLocalizations l, Object e) {
    final code = ApiException.from(e).code;
    return code == 'common.generic' ? l.followupsActionError : l.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.followupsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _unavailable
          ? _InfoState(
              icon: Icons.cloud_off_outlined,
              title: l.followupsUnavailableTitle,
              body: l.followupsUnavailableBody,
            )
          : _error != null
          ? _ErrorState(onRetry: _load)
          : _content(l),
    );
  }

  /// Full-width two-segment selector. Custom (not Material's SegmentedButton, which
  /// sizes to its content and left the labels centered with margins and touching the
  /// pill borders): Expanded segments split the width evenly, with real horizontal
  /// padding so the text breathes. Same look — rounded pill, selection fill, divider.
  Widget _tabs(AppLocalizations l, int theirCount, int myCount) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _segment(
                  l.followupsTabTheirTurn,
                  theirCount,
                  'their_turn',
                ),
              ),
              Container(width: 1, color: cs.outline),
              Expanded(
                child: _segment(l.followupsTabMyTurn, myCount, 'my_turn'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One segment: name on top, active count (bold) centered below.
  Widget _segment(String text, int count, String value) {
    final cs = Theme.of(context).colorScheme;
    final selected = _tab == value;
    final fg = selected ? cs.onSecondaryContainer : cs.onSurface;
    return Material(
      color: selected ? cs.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _tab = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, height: 1.15, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l) {
    final status = _status;
    final theirCount = _items
        .where((i) => i.direction == 'their_turn' && i.isActive)
        .length;
    final myCount = _items
        .where((i) => i.direction == 'my_turn' && i.isActive)
        .length;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: _tabs(l, theirCount, myCount),
        ),
        if (status?.paused != null) _PauseBanner(reason: status!.paused!),
        Expanded(
          child: RefreshIndicator(onRefresh: _load, child: _list(l, status)),
        ),
      ],
    );
  }

  Widget _list(AppLocalizations l, FollowupStatus? status) {
    final active = _items
        .where((i) => i.direction == _tab && i.isActive)
        .toList();
    final closed = _items
        .where((i) => i.direction == _tab && !i.isActive)
        .take(10)
        .toList();

    if (active.isEmpty && closed.isEmpty) {
      // Distinguish "feature off" (act on the web) from "nothing waiting".
      final disabled = status != null && !status.available;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          _InfoState(
            icon: disabled
                ? Icons.hourglass_disabled_outlined
                : Icons.hourglass_empty,
            title: disabled ? l.followupsDisabledTitle : l.followupsEmpty,
            body: disabled ? l.followupsDisabledBody : null,
            embedded: true,
          ),
        ],
      );
    }

    final locale =
        ref.watch(authProvider.select((s) => s.user?.locale)) ?? 'it';
    final now = DateTime.now();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: <Widget>[
        for (final item in active) _row(l, locale, now, item),
        if (closed.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              l.followupsRecentlyClosed.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (final item in closed) _row(l, locale, now, item, dimmed: true),
        ],
      ],
    );
  }

  Widget _row(
    AppLocalizations l,
    String locale,
    DateTime now,
    FollowupItem item, {
    bool dimmed = false,
  }) {
    final chip = followupChipFor(item, now);
    final tone = _toneColor(context, chip.tone);
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: InkWell(
        onTap: () => _act(item, _RowAction.open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(_stateIcon(item, now), size: 18, color: tone),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.counterpartLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (item.summary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          item.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _Chip(
                        text: _chipText(l, chip, locale),
                        color: tone,
                      ),
                    ),
                  ],
                ),
              ),
              if (!dimmed) _menu(l, item) else const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(AppLocalizations l, FollowupItem item) {
    return PopupMenuButton<_RowAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: '',
      onSelected: (a) => _act(item, a),
      itemBuilder: (context) => <PopupMenuEntry<_RowAction>>[
        PopupMenuItem<_RowAction>(
          value: _RowAction.open,
          child: _menuTile(Icons.open_in_new, l.followupsActionOpen),
        ),
        if (item.canRemind)
          PopupMenuItem<_RowAction>(
            value: _RowAction.reminder,
            child: _menuTile(Icons.send_outlined, l.followupsActionReminder),
          ),
        PopupMenuItem<_RowAction>(
          value: _RowAction.done,
          child: _menuTile(Icons.check, l.followupsActionDone),
        ),
        PopupMenuItem<_RowAction>(
          value: _RowAction.snooze1,
          child: _menuTile(Icons.snooze, l.followupsActionSnooze1),
        ),
        PopupMenuItem<_RowAction>(
          value: _RowAction.snooze3,
          child: _menuTile(Icons.snooze, l.followupsActionSnooze3),
        ),
        PopupMenuItem<_RowAction>(
          value: _RowAction.dismiss,
          child: _menuTile(Icons.block, l.followupsActionDismiss),
        ),
      ],
    );
  }

  Widget _menuTile(IconData icon, String label) => Row(
    children: <Widget>[
      Icon(icon, size: 18),
      const SizedBox(width: 10),
      Flexible(child: Text(label)),
    ],
  );

  String _chipText(AppLocalizations l, FollowupChip c, String locale) {
    switch (c.kind) {
      case FollowupChipKind.answered:
        return l.followupsChipAnswered;
      case FollowupChipKind.dismissed:
        return l.followupsChipDismissed;
      case FollowupChipKind.snoozed:
        return l.followupsChipSnoozed(formatDateShort(c.date, locale));
      case FollowupChipKind.remindedOnce:
        return l.followupsChipReminded(formatDateShort(c.date, locale));
      case FollowupChipKind.remindedMany:
        return l.followupsChipRemindedMany(
          formatDateShort(c.date, locale),
          c.days,
        );
      case FollowupChipKind.overdue:
        return l.followupsChipOverdue(c.days);
      case FollowupChipKind.dueToday:
        return l.followupsChipDueToday;
      case FollowupChipKind.dueTomorrow:
        return l.followupsChipDueTomorrow;
      case FollowupChipKind.dueOn:
        return l.followupsChipDueOn(formatDateShort(c.date, locale));
      case FollowupChipKind.none:
        return '';
    }
  }

  IconData _stateIcon(FollowupItem item, DateTime now) {
    switch (item.state) {
      case 'answered':
        return Icons.check_circle_outline;
      case 'dismissed':
        return Icons.block;
      case 'snoozed':
        return Icons.bedtime_outlined;
    }
    if (item.state == 'expired' ||
        (item.dueAt != null && item.dueAt!.isBefore(now))) {
      return Icons.error_outline;
    }
    return Icons.schedule;
  }

  Color _toneColor(BuildContext context, FollowupTone tone) {
    final cs = Theme.of(context).colorScheme;
    switch (tone) {
      case FollowupTone.danger:
        return cs.error;
      case FollowupTone.warn:
        return Colors.orange.shade800;
      case FollowupTone.ok:
        return Colors.green.shade700;
      case FollowupTone.neutral:
        return cs.onSurfaceVariant;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PauseBanner extends StatelessWidget {
  const _PauseBanner({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = switch (reason) {
      'daily_cap' => l.followupsPausedCap,
      'billing' => l.followupsPausedBilling,
      _ => l.followupsPausedEndpoint,
    };
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.pause_circle_outline,
            size: 18,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({
    required this.icon,
    required this.title,
    this.body,
    this.embedded = false,
  });
  final IconData icon;
  final String title;
  final String? body;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 44, color: cs.outline),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (body != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(32),
      child: embedded ? content : Center(child: content),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l.errorGeneric),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l.actionRetry)),
        ],
      ),
    );
  }
}
