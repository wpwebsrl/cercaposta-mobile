import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import 'home_tab.dart';
import 'update_check.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _tabs = <Widget>[
    SearchScreen(),
    ChatScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // One-shot biometric offer raised by a manual login: shown HERE, after the
    // auth-driven redirect (a dialog on the login screen would be torn down).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferBiometric());
  }

  Future<void> _maybeOfferBiometric() async {
    if (!ref.read(biometricOfferProvider)) return;
    ref.read(biometricOfferProvider.notifier).state = false; // consume the flag
    final supported = await LocalAuthentication().isDeviceSupported();
    if (!supported || !mounted) return;
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.loginEnableBiometricTitle),
        content: Text(l.loginEnableBiometricBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.unlockEnableBiometricNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.unlockEnableBiometricYes),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(authProvider.notifier).enableBiometricFromSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final index = ref.watch(homeTabProvider);
    final unread = ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;
    final updateNeeded = ref.watch(updateRequiredProvider).valueOrNull ?? false;
    if (updateNeeded) {
      // Below the server's feature floor: mobile can't auto-update, so hard-block to the
      // store instead of running incompatible (a state change routes to UpdateRequiredScreen).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authProvider.notifier).enterUpdateRequired();
      });
    }
    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).state = i,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l.navSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum),
            label: l.navChat,
          ),
          NavigationDestination(
            icon: unread > 0
                ? Badge(
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: l.navNotifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}

/// Thin, always-visible bar telling the user the app is below the server's
/// minimum version (docs/mobile-apps.md §4.1). Not dismissible: it reflects a
/// standing requirement, and there's no in-app store link (multi-instance).
