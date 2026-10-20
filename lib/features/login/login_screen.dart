import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/error_messages.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/passkey_policy.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/legal/legal_links.dart';
import '../../core/providers.dart';
import '../../shared/widgets/google_sign_in_mark.dart';
import '../../shared/widgets/passkey_icon.dart';
import '../about/animated_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _hasSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLoginMethods();
  }

  Future<void> _initLoginMethods() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    try {
      final resumed = await ref.read(authProvider.notifier).resumeGoogleLogin();
      if (resumed != null || !mounted) return;
      final appleResumed = await ref
          .read(authProvider.notifier)
          .resumeAppleLogin();
      if (appleResumed != null || !mounted) return;
    } on Object catch (e) {
      if (mounted) setState(() => _error = localizeApiError(l, e));
      return;
    }
    await _initBiometric();
  }

  /// Saved credentials for THIS server → show the biometric button, prefill the
  /// username and fire the OS prompt right away (same UX as the unlock screen).
  /// Cancelling falls back to the manual form without any error.
  Future<void> _initBiometric() async {
    final controller = ref.read(authProvider.notifier);
    final expected = controller.requestIdentity;
    final creds = await controller.savedGrantInfo().catchError(
      (Object _) => null,
    );
    if (!controller.isCurrent(expected)) return;
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
    final controller = ref.read(authProvider.notifier);
    final l = AppLocalizations.of(context)!;
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await controller.biometricLogin(
        reason: l.loginBiometricReason,
        cancel: l.actionCancel,
      );
    } on Object catch (e) {
      if (!mounted) return;
      final code = ApiException.from(e).code;
      if (code == 'trusted_device.not_available' ||
          code == 'biometric.reenroll') {
        setState(() {
          _hasSaved = false;
          _error = localizeApiError(l, e);
        });
      } else if (code != 'biometric.cancelled' &&
          code != 'auth.session_changed') {
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

  Future<void> _passkeyLogin() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).passkeyLogin();
      if (mounted && result.totpSetupRequired) {
        setState(() => _error = l.errorTotpSetupRequired);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = localizePasskeyError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleLogin() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).googleLogin();
      if (mounted && result.totpSetupRequired) {
        setState(() => _error = l.errorTotpSetupRequired);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = localizeApiError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _appleLogin() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(authProvider.notifier).appleLogin();
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
    final passkeySupported = passkeyServerSupported(
      ref.watch(appInfoProvider).client,
      server,
    );
    final theme = Theme.of(context);
    // The same muted text/icon colours as the Web and Desktop login.
    final mutedColor = theme.brightness == Brightness.dark
        ? const Color(0xFF9AA4AE)
        : const Color(0xFF5C6670);
    final secondaryStyle = OutlinedButton.styleFrom(
      foregroundColor: mutedColor,
      minimumSize: const Size.fromHeight(44),
      visualDensity: VisualDensity.standard,
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.loginTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/icons/cercaposta.svg',
                    width: 36,
                    height: 36,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            l.loginHeading,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.loginTagline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.375,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const ExcludeSemantics(child: AnimatedLogo(width: 56)),
                ],
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: secondaryStyle,
                onPressed: _busy || !passkeySupported ? null : _passkeyLogin,
                icon: const PasskeyIcon(size: 17),
                label: Text(l.loginPasskey),
              ),
              if (!passkeySupported) Text(l.passkeyUnsupportedServer),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: secondaryStyle,
                onPressed: _busy ? null : _googleLogin,
                icon: const GoogleSignInMark(),
                label: Text(l.loginGoogle),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: secondaryStyle,
                onPressed: _busy ? null : _appleLogin,
                icon: const AppleSignInMark(),
                label: Text(l.loginApple),
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
              Wrap(
                alignment: WrapAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () => openLegal(
                      LegalDestination.privacy,
                      Localizations.localeOf(context),
                    ),
                    child: Text(l.legalPrivacy),
                  ),
                  TextButton(
                    onPressed: () => openLegal(
                      LegalDestination.terms,
                      Localizations.localeOf(context),
                    ),
                    child: Text(l.legalTerms),
                  ),
                  TextButton(
                    onPressed: () => openLegal(
                      LegalDestination.support,
                      Localizations.localeOf(context),
                    ),
                    child: Text(l.legalSupport),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The same Apple silhouette and 20px box used by the Web and Desktop login.
class AppleSignInMark extends StatelessWidget {
  const AppleSignInMark({super.key});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final ink = iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/icons/apple-sign-in.svg',
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(
        ink.withValues(alpha: ink.a * (iconTheme.opacity ?? 1)),
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
    );
  }
}
