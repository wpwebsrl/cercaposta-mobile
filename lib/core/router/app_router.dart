import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/email/attachment_viewer_screen.dart';
import '../../features/email/email_screen.dart';
import '../../features/followups/reminder_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/login/first_password_screen.dart';
import '../../features/login/login_screen.dart';
import '../../features/login/recovery_screen.dart';
import '../../features/login/totp_screen.dart';
import '../../features/login/unlock_screen.dart';
import '../../features/login/update_required_screen.dart';
import '../../features/server/server_screen.dart';
import '../../features/settings/sessions_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/models/followup.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';

/// Auth/server-driven routing: the access-token status and the active server
/// select the whole tree. Login/logout work by mutating state only (no navigate()).
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
    _ref.listen(activeServerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  /// Where the user was when the archive locked (423), to restore after unlock —
  /// so a lock mid-reading doesn't dump them back on the search tab.
  String? _returnTo;

  String? redirect(BuildContext context, GoRouterState state) {
    final status = _ref.read(authProvider).status;
    final hasServer = _ref.read(activeServerProvider) != null;
    final loc = state.matchedLocation;

    if (status == AuthStatus.unknown) return loc == '/' ? null : '/';
    if (!hasServer) return loc == '/server' ? null : '/server';

    switch (status) {
      case AuthStatus.loggedOut:
        _returnTo = null; // don't carry a stale return target across sessions
        return loc == '/login' ? null : '/login';
      case AuthStatus.needsTotp:
        return loc == '/totp' ? null : '/totp';
      case AuthStatus.needsPasswordChange:
        return loc == '/first-password' ? null : '/first-password';
      case AuthStatus.needsRecovery:
        return loc == '/recovery' ? null : '/recovery';
      case AuthStatus.locked:
        if (loc != '/unlock') {
          _returnTo = loc; // remember the page we're leaving
          return '/unlock';
        }
        return null;
      case AuthStatus.updateRequired:
        return loc == '/update' ? null : '/update';
      case AuthStatus.loggedIn:
        const gates = <String>{
          '/',
          '/server',
          '/login',
          '/totp',
          '/unlock',
          '/first-password',
          '/recovery',
          '/update',
        };
        if (gates.contains(loc)) {
          final target = _returnTo ?? '/home';
          _returnTo = null;
          return target;
        }
        return null;
      case AuthStatus.unknown:
        return '/';
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/server', builder: (_, __) => const ServerScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/totp', builder: (_, __) => const TotpScreen()),
      GoRoute(
        path: '/first-password',
        builder: (_, __) => const FirstPasswordScreen(),
      ),
      GoRoute(path: '/recovery', builder: (_, __) => const RecoveryScreen()),
      GoRoute(path: '/unlock', builder: (_, __) => const UnlockScreen()),
      GoRoute(
        path: '/update',
        builder: (_, __) => const UpdateRequiredScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(
        path: '/followups/reminder',
        builder: (_, state) {
          final item = state.extra;
          // Reached only from the «In attesa» page, which passes the item; a stray
          // deep-link without it falls back to the shell rather than crashing.
          return item is FollowupItem
              ? ReminderScreen(item: item)
              : const HomeShell();
        },
      ),
      GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
        path: '/message/:id',
        builder: (_, state) =>
            EmailScreen(messageId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/message/:id/attachment/:attId',
        builder: (_, state) {
          final extra = state.extra;
          return AttachmentViewerScreen(
            messageId: state.pathParameters['id'] ?? '',
            attachmentId: state.pathParameters['attId'] ?? '',
            filename: extra is String ? extra : '',
          );
        },
      ),
    ],
  );
});
