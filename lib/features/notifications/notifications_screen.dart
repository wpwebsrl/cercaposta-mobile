import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
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
      appBar: AppBar(title: Text(l.notificationsTitle)),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              isReprocess ? Icons.build_outlined : Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _notifTitle(l, n.type),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _notifBody(l, n.type),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (isReprocess) ...<Widget>[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _openInWeb,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l.actionOpenInBrowser),
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

String _notifTitle(AppLocalizations l, String type) => switch (type) {
  'reprocess_recommended' => l.notifReprocessTitle,
  _ => l.notificationsTitle,
};

String _notifBody(AppLocalizations l, String type) => switch (type) {
  'reprocess_recommended' => l.notifReprocessBody,
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
