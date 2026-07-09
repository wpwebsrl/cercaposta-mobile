import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers.dart';
import '../about/animated_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _auth = LocalAuthentication();
  bool _busy = false;
  bool _obscure = true;
  bool _hasSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  /// Saved credentials for THIS server → show the biometric button, prefill the
  /// username and fire the OS prompt right away (same UX as the unlock screen).
  /// Cancelling falls back to the manual form without any error.
  Future<void> _initBiometric() async {
    final creds = await ref.read(authProvider.notifier).savedCredentials();
    if (!mounted || creds == null) return;
    setState(() {
      _hasSaved = true;
      if (_username.text.isEmpty) _username.text = creds.username;
    });
    await _biometricLogin();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _biometricLogin() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _error = null);
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return;
      final ok = await _auth.authenticate(
        localizedReason: l.loginBiometricReason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!ok || !mounted) return;
      setState(() => _busy = true);
      await ref.read(authProvider.notifier).biometricLogin();
    } on Object catch (e) {
      if (!mounted) return;
      // A rejected saved password was already wiped by the controller: hide the
      // button so the user re-types (and re-enables) instead of looping.
      if (ApiException.from(e).code == 'auth.invalid_credentials') {
        setState(() {
          _hasSaved = false;
          _error = localizeApiError(l, e);
        });
      } else if (e is! PlatformException) {
        // biometric cancelled/unavailable (PlatformException) → silent fallback
        setState(() => _error = localizeApiError(l, e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (_username.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authProvider.notifier)
          .login(_username.text.trim(), _password.text);
      // Let iOS/Android password managers offer to save the typed credentials
      // (they re-fill them later behind the OS biometric prompt).
      TextInput.finishAutofillContext();
      // Admin-enforced 2FA without enrollment: the session was NOT kept
      // (enrollment lives on the web) — explain why the login "failed".
      // The in-app biometric offer is shown by HomeShell after the redirect
      // (a dialog here would be killed by the auth-driven navigation).
      if (mounted && result.totpSetupRequired) {
        setState(() => _error = l.errorTotpSetupRequired);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = localizeApiError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final server = ref.watch(activeServerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              // Brand logo (as on the web/desktop login). The wordmark ink is
              // theme-aware (light in dark mode), so no white glow is needed.
              const Center(child: AnimatedLogo(width: 100)),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l.appName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (server != null)
                Center(
                  child: Text(
                    server,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _username,
                enabled: !_busy,
                autocorrect: false,
                autofillHints: const <String>[AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l.loginUsername,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscure,
                autofillHints: const <String>[AutofillHints.password],
                onSubmitted: (_) => _busy ? null : _submit(),
                decoration: InputDecoration(
                  labelText: l.loginPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
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
                    : Text(l.loginButton),
              ),
              if (_hasSaved) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _biometricLogin,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l.loginBiometric),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => ref.read(activeServerProvider.notifier).clear(),
                child: Text(l.loginChangeServer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
