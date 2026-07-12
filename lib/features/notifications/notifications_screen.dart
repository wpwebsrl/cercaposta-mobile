import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
import '../../shared/format.dart';
import '../../shared/models/notification.dart';
import '../../shared/widgets/snack.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationItem> _items = const <NotificationItem>[];
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
      final data = await ref.read(notificationApiProvider).list();
      if (!mounted) return;
      setState(() {
        _items = data.items;
        _loading = false;
      });
      // Opening the center acknowledges everything → clears the nav badge.
      if (data.unreadCount > 0) {
        await ref.read(notificationApiProvider).markAllRead();
        ref.invalidate(notificationUnreadCountProvider);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _dismiss(NotificationItem n) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(notificationApiProvider).dismiss(n.id);
      ref.invalidate(notificationUnreadCountProvider);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  Future<void> _dismissAll() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.notificationsDismissAll),
        content: Text(l.notificationsDismissAllConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.notificationsDismissAll),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(notificationApiProvider).dismissAll();
      ref.invalidate(notificationUnreadCountProvider);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  // Query-only client: the reprocess is started from the web app. Open it there.
  Future<void> _openInWeb() async {
    final l = AppLocalizations.of(context)!;
    final origin = ref.read(activeServerProvider);
    if (origin == null) return;
    final ok = await launchUrl(
      Uri.parse('$origin/notifications'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) showSnack(context, l.errorGeneric, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: <Widget>[
          if (!_loading && _error == null && _items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l.notificationsDismissAll,
              onPressed: _dismissAll,
            ),
        ],
      ),
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
          : _items.isEmpty
          ? _EmptyState(text: l.notificationsEmpty)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (context, i) => _card(context, l, _items[i]),
              ),
            ),
    );
  }

  Widget _card(BuildContext context, AppLocalizations l, NotificationItem n) {
    final isReprocess = n.type == 'reprocess_recommended';
    final isFollowup = n.type.startsWith('followup.');
    final locale =
        ref.watch(authProvider.select((s) => s.user?.locale)) ?? 'it';
    // Deep-link to the conversation when the enriched params carry the origin id
    // (all followup.* except the digest, which is content-free counts only).
    final rawMessageId = n.params['message_id'];
    final messageId = rawMessageId is String ? rawMessageId : '';
    final canOpenConversation = isFollowup && messageId.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              _notifIcon(n.type),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _notifTitle(l, n, locale),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_notifBody(l, n, locale).isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      _notifBody(l, n, locale),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (isReprocess) ...<Widget>[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _openInWeb,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l.actionOpenInBrowser),
                    ),
                  ],
                  if (canOpenConversation) ...<Widget>[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/message/$messageId'),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l.notifOpenConversation),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l.notificationsDismiss,
              onPressed: () => _dismiss(n),
            ),
          ],
        ),
      ),
    );
  }
}

String _p(NotificationItem n, String key) {
  final v = n.params[key];
  return v is String ? v : '';
}

int _pi(NotificationItem n, String key) {
  final v = n.params[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}

/// Format an ISO date/datetime param with the profile locale, falling back to the
/// raw string (the server sends an ISO date for due_soon / a datetime for sent).
String _pDate(NotificationItem n, String key, String locale) {
  final raw = _p(n, key);
  final dt = DateTime.tryParse(raw);
  return dt == null ? raw : formatDateShort(dt, locale);
}

IconData _notifIcon(String type) => switch (type) {
  'reprocess_recommended' => Icons.build_outlined,
  'followup.reminder_sent' => Icons.mark_email_read_outlined,
  'followup.digest' => Icons.summarize_outlined,
  _ when type.startsWith('followup.') => Icons.hourglass_bottom,
  _ => Icons.notifications_outlined,
};

String _notifTitle(AppLocalizations l, NotificationItem n, String locale) =>
    switch (n.type) {
      'reprocess_recommended' => l.notifReprocessTitle,
      'followup.no_reply' => l.notifFollowupNoReplyTitle(_p(n, 'name')),
      'followup.reply_due' => l.notifFollowupReplyDueTitle(_p(n, 'name')),
      'followup.due_soon' => l.notifFollowupDueSoonTitle,
      'followup.reminder_sent' => l.notifFollowupReminderSentTitle(
        _p(n, 'name'),
      ),
      'followup.digest' => l.notifFollowupDigestTitle,
      _ => l.notificationsTitle,
    };

String _notifBody(AppLocalizations l, NotificationItem n, String locale) =>
    switch (n.type) {
      'reprocess_recommended' => l.notifReprocessBody,
      'followup.no_reply' => l.notifFollowupNoReplyBody(
        _p(n, 'summary'),
        _pi(n, 'days'),
      ),
      'followup.reply_due' => l.notifFollowupReplyDueBody(
        _p(n, 'summary'),
        _pi(n, 'days'),
      ),
      'followup.due_soon' => l.notifFollowupDueSoonBody(
        _p(n, 'summary'),
        _p(n, 'name'),
        _pDate(n, 'due_date', locale),
      ),
      'followup.reminder_sent' => l.notifFollowupReminderSentBody(
        _p(n, 'summary'),
      ),
      'followup.digest' => l.notifFollowupDigestBody(
        _pi(n, 'overdue'),
        _pi(n, 'due_today'),
        _pi(n, 'waiting_me'),
      ),
      _ => '',
    };

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
