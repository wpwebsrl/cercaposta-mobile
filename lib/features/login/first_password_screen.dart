import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../shared/widgets/snack.dart';

/// Forced first-login password change (must_change_password). For accounts with
/// pending encryption the server also bootstraps the DEK and returns the ONE-TIME
/// recovery kit: it is shown here and must be acknowledged before proceeding.
class FirstPasswordScreen extends ConsumerStatefulWidget {
  const FirstPasswordScreen({super.key});

  @override
  ConsumerState<FirstPasswordScreen> createState() =>
      _FirstPasswordScreenState();
}

class _FirstPasswordScreenState extends ConsumerState<FirstPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (_password.text.isEmpty) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = l.firstPasswordMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final kit = await ref
          .read(authProvider.notifier)
          .firstPassword(_password.text);
      if (!mounted) return;
      if (kit != null) await _showKit(kit);
      if (mounted) ref.read(authProvider.notifier).finishPasswordChange();
    } on Object catch (e) {
      if (mounted) setState(() => _error = localizeApiError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showKit(String kit) async {
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.kitTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.kitBody),
            const SizedBox(height: 12),
            SelectableText(
              kit,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: kit));
              if (ctx.mounted) showSnack(ctx, l.kitCopied);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.kitCopy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionContinue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.firstPasswordTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.settingsLogout,
            onPressed: _busy
                ? null
                : () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l.firstPasswordSubtitle),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.firstPasswordNew,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: true,
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: InputDecoration(
                labelText: l.firstPasswordConfirm,
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}
