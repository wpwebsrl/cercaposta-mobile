import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/keepalive.dart';
import 'core/config/app_info.dart';
import 'core/live/live_refresh.dart';
import 'core/i18n/app_localizations.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  final info = await AppInfo.load();
  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        appInfoProvider.overrideWithValue(info),
      ],
      child: const CercaPostaApp(),
    ),
  );
}

class CercaPostaApp extends ConsumerStatefulWidget {
  const CercaPostaApp({super.key});

  @override
  ConsumerState<CercaPostaApp> createState() => _CercaPostaAppState();
}

class _CercaPostaAppState extends ConsumerState<CercaPostaApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(authProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    // Foreground keepalive (session + DEK stay alive while the app is open).
    ref.watch(sessionKeepaliveProvider);
    // Foreground live refresh: folders, shares and the notification badge update on their own
    // (docs/eventi-live.md) — poll + resume tick, no persistent stream.
    ref.watch(liveRefreshProvider);
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
