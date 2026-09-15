import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _hasSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    bool available;
    try {
      available = await ref
          .read(authProvider.notifier)
          .hasBiometricForCurrentUser();
    } on Object {
      return;
    }
    if (!mounted) return;
    setState(() => _hasSaved = available);
    if (available) await _biometricUnlock();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _biometricUnlock() async {
    final controller = ref.read(authProvider.notifier);
    final expected = controller.requestIdentity;
    final l = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await controller.biometricUnlock(
        reason: l.unlockReason,
        cancel: l.actionCancel,
      );
      if (!ok && mounted) setState(() => _error = l.errorDekLocked);
    } on Object catch (error) {
      if (mounted && controller.isCurrent(expected)) {
        setState(() => _error = localizeApiError(l, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlock(String password) async {
    final controller = ref.read(authProvider.notifier);
    final expected = controller.requestIdentity;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref.read(authProvider.notifier).unlock(password);
      if (!ok && mounted) setState(() => _error = l.errorDekLocked);
    } on Object catch (e) {
      if (!mounted || !controller.isCurrent(expected)) return;
      if (mounted) setState(() => _error = localizeApiError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.unlockTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.settingsLogout,
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 8),
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(l.unlockDescription, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autofocus: !_hasSaved,
              onSubmitted: (_) => _busy ? null : _unlock(_password.text),
              decoration: InputDecoration(
                labelText: l.unlockPassword,
                prefixIcon: const Icon(Icons.password),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : () => _unlock(_password.text),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.unlockButton),
            ),
            if (_hasSaved) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _biometricUnlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(l.unlockBiometric),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
