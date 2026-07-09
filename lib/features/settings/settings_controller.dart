import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class AppSettings {
  const AppSettings({required this.themeMode, required this.locale});
  final ThemeMode themeMode;
  final Locale? locale; // null = follow system

  AppSettings copyWith({ThemeMode? themeMode, Object? locale = _unset}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale == _unset ? this.locale : locale as Locale?,
      );
}

const Object _unset = Object();

class SettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'pref_theme_mode';
  static const _kLocale = 'pref_locale';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final theme = switch (prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final lang = prefs.getString(_kLocale);
    return AppSettings(
      themeMode: theme,
      locale: (lang == null || lang.isEmpty) ? null : Locale(lang),
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    final name = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await ref.read(sharedPreferencesProvider).setString(_kTheme, name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale? locale) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_kLocale, locale?.languageCode ?? '');
    state = state.copyWith(locale: locale);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
