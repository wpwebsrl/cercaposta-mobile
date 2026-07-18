import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../background/bg_constants.dart';

/// Thin wrapper over flutter_local_notifications for the OS-notification feature
/// (docs/notifiche.md). Used from BOTH isolates: the foreground (init with tap handling, request
/// permission, cancel) and the background poll isolate (init without taps, show). Statics are
/// per-isolate, so each isolate initializes its own plugin — that's fine, they share the OS
/// channel and pending-notification store.
class NotifyService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the app root: routes a notification tap to the notification centre tab.
  static void Function()? onOpenNotifications;

  static bool _coldOpen = false;

  /// Whether the app was cold-launched by tapping a notification (consume once).
  static bool consumeColdLaunch() {
    final v = _coldOpen;
    _coldOpen = false;
    return v;
  }

  /// [handleTaps] wires the tap → open-notifications routing and records a cold launch;
  /// the background isolate passes false (nothing to route to there).
  static Future<void> init({bool handleTaps = true}) async {
    const android = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const ios = DarwinInitializationSettings(
      // We ask for permission explicitly when the user turns the toggle on, not at first launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: handleTaps
          ? (NotificationResponse _) => onOpenNotifications?.call()
          : null,
    );
    if (handleTaps) {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      _coldOpen = launch?.didNotificationLaunchApp ?? false;
    }
  }

  /// Ask the OS for notification permission (Android 13+ runtime / iOS authorization).
  /// Returns true when granted. Safe to call repeatedly.
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  static Future<void> show(
    int id,
    String title,
    String body, {
    required String channelName,
  }) async {
    final android = AndroidNotificationDetails(
      kNotifChannelId,
      channelName, // channel label in system settings; fixed at creation (won't retranslate)
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
