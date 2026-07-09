import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/auth.dart';
import '../../shared/widgets/snack.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  List<SessionInfo> _sessions = const <SessionInfo>[];
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
      final list = await ref.read(sessionApiProvider).list();
      if (mounted) {
        setState(() {
          _sessions = list;
          _loading = false;
        });
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

  Future<void> _revoke(SessionInfo s) async {
    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(sessionApiProvider).revoke(s.id);
      await _load();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  Future<void> _revokeAll() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.sessionsRevokeAll),
        content: Text(l.sessionsRevokeAllConfirm),
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
      await ref.read(sessionApiProvider).revokeAll();
      // revoking all includes this device → forced re-auth.
      await ref.read(authProvider.notifier).forceLogout();
    } on Object catch (e) {
      if (mounted) showSnack(context, localizeApiError(l, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = ref.watch(authProvider).user?.locale ?? 'it-IT';
    return Scaffold(
      appBar: AppBar(
        title: Text(l.sessionsTitle),
        actions: <Widget>[
          if (_sessions.isNotEmpty)
            TextButton(onPressed: _revokeAll, child: Text(l.sessionsRevokeAll)),
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
          : _sessions.isEmpty
          ? Center(child: Text(l.sessionsEmpty))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _sessions[i];
                  return ListTile(
                    leading: Icon(_iconFor(s.client)),
                    title: Text(s.deviceName ?? s.client ?? '—'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (s.appVersion != null)
                          Text('${s.client ?? ''} ${s.appVersion}'.trim()),
                        if (s.lastSeenAt != null)
                          Text(
                            l.sessionsLastSeen(
                              formatDateTime(s.lastSeenAt, locale),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (s.createdAt != null)
                          Text(
                            l.sessionsCreated(
                              formatDateTime(s.createdAt, locale),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (s.lastIp != null && s.lastIp!.isNotEmpty)
                          Text(
                            l.sessionsIp(s.lastIp!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (s.current)
                          Text(
                            l.sessionsCurrent,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    trailing: s.current
                        ? null
                        : TextButton(
                            onPressed: () => _revoke(s),
                            child: Text(l.sessionsRevoke),
                          ),
                  );
                },
              ),
            ),
    );
  }

  IconData _iconFor(String? client) => switch (client) {
    'ios' => Icons.phone_iphone,
    'android' => Icons.phone_android,
    'web' => Icons.language,
    _ => Icons.devices_other,
  };
}
