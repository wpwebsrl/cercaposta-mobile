import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/background/bg_constants.dart';
import '../../core/notify/notify_service.dart';
import '../../core/providers.dart';

/// Device-local "OS notifications" preference (default OFF — opt-in, since enabling asks for the
/// system notification permission). Owns the WorkManager background-poll registration too. Kept
/// apart from theme/locale (settings_controller) because it has side effects (permission + task).
class NotifySettings extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(kPrefOsNotifications) ??
      false;

  /// Turn the feature on/off. Enabling asks for the OS permission first and registers the periodic
  /// background poll; returns the effective state (false if the permission was denied).
  Future<bool> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!enabled) {
      await prefs.setBool(kPrefOsNotifications, false);
      try {
        await Workmanager().cancelByUniqueName(kBgTaskName);
      } on Object {
        // ignore
      }
      await NotifyService.cancelAll();
      state = false;
      return false;
    }
    final granted = await NotifyService.requestPermission();
    if (!granted) {
      await prefs.setBool(kPrefOsNotifications, false);
      state = false;
      return false;
    }
    // Baseline: forget any stale marks so the CURRENT backlog is recorded (not notified) on the
    // first background run (D1).
    await prefs.remove(kBgBaselineMs);
    await prefs.remove(kBgSeenIds);
    await prefs.remove(kBgLastRev);
    await prefs.setBool(kPrefOsNotifications, true);
    try {
      await Workmanager().registerPeriodicTask(
        kBgTaskName,
        kBgTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } on Object {
      // Registration can fail on some OS versions (e.g. iOS refusing the identifier): keep the
      // preference on — the app still checks in the foreground — and let a device test sort out
      // the platform specifics.
    }
    state = true;
    return true;
  }
}

final notifySettingsProvider = NotifierProvider<NotifySettings, bool>(
  NotifySettings.new,
);
