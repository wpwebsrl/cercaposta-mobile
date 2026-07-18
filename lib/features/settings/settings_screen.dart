import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
import '../../shared/format.dart';
import '../../shared/widgets/snack.dart';
import 'notify_settings.dart';
import 'settings_controller.dart';
import 'usage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final pwd = await ref.read(authProvider.notifier).savedPassword();
    if (mounted) setState(() => _hasBiometric = pwd != null);
  }

  /// Pull-to-refresh: re-fetch the live figures (storage usage) and the biometric
  /// flag without a logout/login round-trip. Invalidating the provider makes the
  /// FutureProvider refetch; we await the fresh value so the spinner lasts until
  /// the new number is on screen.
  Future<void> _refresh() async {
    ref.invalidate(usageProvider);
    await Future.wait<void>(<Future<void>>[
      ref.read(usageProvider.future).then((_) {}, onError: (_) {}),
      _loadBiometric(),
    ]);
  }

  /// Switch to a different server: this signs out of the current one first (the
  /// stored session belongs to it), then clears the active server so the router
  /// returns to the server-picker.
  Future<void> _changeServer() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsChangeServer),
        content: Text(l.settingsChangeServerConfirm),
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
    await ref.read(authProvider.notifier).logout();
    await ref.read(activeServerProvider.notifier).clear();
  }

  /// Enable biometric unlock: ask for the account password, verify it against
  /// the server (POST /auth/unlock also refreshes the DEK) and only then save
  /// it in the secure enclave. A wrong password never gets stored.
  Future<bool> _enableBiometricDialog() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var busy = false;
    String? errorText;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> confirm() async {
            if (controller.text.isEmpty || busy) return;
            setDialogState(() => busy = true);
            try {
              final ok = await ref
                  .read(authProvider.notifier)
                  .unlock(controller.text, saveForBiometric: true);
              if (ctx.mounted) Navigator.pop(ctx, ok);
            } on Object catch (e) {
              if (ctx.mounted) {
                setDialogState(() {
                  busy = false;
                  errorText = localizeApiError(l, e);
                });
              }
            }
          }

          return AlertDialog(
            title: Text(l.unlockEnableBiometricTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(l.settingsBiometricEnablePrompt),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  enabled: !busy,
                  onSubmitted: (_) => confirm(),
                  decoration: InputDecoration(
                    labelText: l.unlockPassword,
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx, false),
                child: Text(l.actionCancel),
              ),
              FilledButton(
                onPressed: busy ? null : confirm,
                child: Text(l.actionConfirm),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);
    final server = ref.watch(activeServerProvider);
    final info = ref.watch(appInfoProvider);
    final usage = ref.watch(usageProvider).valueOrNull;
    final locale = auth.user?.locale ?? 'it-IT';

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        // AlwaysScrollable so the pull gesture works even when the list is short.
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            if (auth.user != null)
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    auth.user!.label.isNotEmpty
                        ? auth.user!.label.substring(0, 1).toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(auth.user!.label),
                subtitle: Text(auth.user!.username),
              ),
            const Divider(),
            _sectionLabel(context, l.settingsServer),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(
                server ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.swap_horiz),
              onTap: _changeServer,
            ),
            if (usage != null) ...<Widget>[
              const Divider(),
              _sectionLabel(context, l.settingsStorage),
              _storageInfo(context, l, usage, locale),
            ],
            const Divider(),
            _sectionLabel(context, l.settingsLanguage),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<String>(
                segments: <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'system',
                    label: Text(l.settingsLanguageSystem),
                  ),
                  ButtonSegment<String>(
                    value: 'it',
                    label: Text(l.settingsLanguageIt),
                  ),
                  ButtonSegment<String>(
                    value: 'en',
                    label: Text(l.settingsLanguageEn),
                  ),
                ],
                selected: <String>{settings.locale?.languageCode ?? 'system'},
                showSelectedIcon: false,
                onSelectionChanged: (sel) {
                  final v = sel.first;
                  ref
                      .read(settingsProvider.notifier)
                      .setLocale(v == 'system' ? null : Locale(v));
                },
              ),
            ),
            const Divider(),
            _sectionLabel(context, l.settingsTheme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(l.settingsThemeAuto),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l.settingsThemeLight),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l.settingsThemeDark),
                  ),
                ],
                selected: <ThemeMode>{settings.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (sel) =>
                    ref.read(settingsProvider.notifier).setTheme(sel.first),
              ),
            ),
            const Divider(),
            _sectionLabel(context, l.settingsNotifications),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(l.settingsOsNotifications),
              subtitle: Text(l.settingsOsNotificationsHint),
              isThreeLine: true,
              value: ref.watch(notifySettingsProvider),
              onChanged: (v) async {
                final ok = await ref
                    .read(notifySettingsProvider.notifier)
                    .setEnabled(v);
                if (!context.mounted) return;
                // Turning it on but ending up off means the OS permission was denied.
                if (v && !ok) {
                  showSnack(
                    context,
                    l.settingsOsNotificationsDenied,
                    error: true,
                  );
                }
              },
            ),
            const Divider(),
            if (auth.isEncrypted)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(l.settingsBiometric),
                value: _hasBiometric,
                onChanged: (v) async {
                  if (!v) {
                    await ref.read(authProvider.notifier).disableBiometric();
                    if (mounted) setState(() => _hasBiometric = false);
                    return;
                  }
                  final ok = await _enableBiometricDialog();
                  if (ok && mounted) setState(() => _hasBiometric = true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(l.settingsSessions),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/sessions'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.aboutTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.settingsLogout),
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push('/about'),
                child: Text(
                  l.settingsVersion(info.version),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _storageInfo(
    BuildContext context,
    AppLocalizations l,
    UsageInfo u,
    String locale,
  ) {
    final used = formatSize(u.usedBytes, locale);
    final text = u.unlimited
        ? l.settingsStorageUnlimited(used)
        : l.settingsStorageValue(
            used,
            formatSize(u.quotaBytes, locale),
            u.percent.toStringAsFixed(0),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.storage_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
          if (!u.unlimited)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(
                value: (u.percent / 100).clamp(0.0, 1.0),
                color: u.overQuota ? Theme.of(context).colorScheme.error : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
