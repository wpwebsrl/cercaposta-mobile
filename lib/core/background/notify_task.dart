import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/notifications/notification_text.dart';
import '../../shared/models/notification.dart';
import '../i18n/app_localizations.dart';
import '../notify/notify_service.dart';
import 'bg_constants.dart';

/// WorkManager entry point (docs/notifiche.md → mobile OS notifications). Runs in its OWN isolate,
/// so it shares NO memory with the app: it reads the session from secure storage / prefs, polls
/// the change-state, and turns genuinely-new unread notifications into local notifications.
///
/// EVERYTHING here is best-effort and silent (D10): it must NEVER log the user out, clear tokens,
/// or throw its way to a crash. Any failure just ends the round; the next run retries.
@pragma('vm:entry-point')
void notifyCallbackDispatcher() {
  Workmanager().executeTask((_, __) async {
    try {
      await runNotifyPoll();
    } on Object {
      // swallow — see D10
    }
    return true;
  });
}

const int _summaryNotifId = 0x7f000001;
const int _maxIndividual = 3;

/// Pure diff (unit-testable): the new, unread, post-baseline notifications not seen before.
List<NotificationItem> freshNotifications({
  required List<NotificationItem> items,
  required Set<String> seen,
  required int baselineMs,
}) {
  final out = <NotificationItem>[];
  for (final n in items) {
    final createdMs = n.createdAt?.millisecondsSinceEpoch ?? 0;
    if (n.readAt == null &&
        n.id.isNotEmpty &&
        !seen.contains(n.id) &&
        createdMs > baselineMs) {
      out.add(n);
    }
  }
  return out;
}

Future<void> runNotifyPoll() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs =
      await SharedPreferences.getInstance(); // fresh disk read in this isolate
  if (!(prefs.getBool(kPrefOsNotifications) ?? false)) return; // feature off

  // Heartbeat guard: if the foreground app was active recently it owns the session — do NOT poll
  // and above all do NOT refresh (a background rotation racing a foreground one risks a
  // reuse-detection logout). §4.6.
  final hb = prefs.getInt(kBgHeartbeatMs) ?? 0;
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  if (hb != 0 && nowMs - hb < kForegroundActiveWindow.inMilliseconds) return;

  final server = prefs.getString('active_server');
  if (server == null || server.isEmpty) return;

  const store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  final rt = await store.read(key: 'refresh_token');
  if (rt == null) return; // not logged in on this device

  final dio = Dio(
    BaseOptions(
      baseUrl: '$server/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );

  final access = await _refresh(dio, store, prefs, rt);
  if (access == null) return; // couldn't get a usable token — give up quietly
  dio.options.headers['Authorization'] = 'Bearer $access';

  // Cheap gate: only fetch the list when the notifications revision actually advanced.
  final state = await _getJson(dio, '/events/state');
  if (state == null) return;
  final revs = state['revs'];
  final notifRev = (revs is Map && revs['notifications'] is num)
      ? (revs['notifications'] as num).toInt()
      : 0;

  // First ever run: baseline. Record the current ids + rev and notify NOTHING (D1).
  if (prefs.getInt(kBgBaselineMs) == null) {
    final listJson = await _getJson(dio, '/notifications');
    final ids = listJson == null
        ? const <String>[]
        : NotificationList.fromJson(
            listJson,
          ).items.map((n) => n.id).where((s) => s.isNotEmpty).toList();
    await prefs.setStringList(kBgSeenIds, ids);
    await prefs.setInt(kBgBaselineMs, nowMs);
    await prefs.setInt(kBgLastRev, notifRev);
    return;
  }
  if (notifRev == (prefs.getInt(kBgLastRev) ?? -1)) return; // nothing new

  final listJson = await _getJson(dio, '/notifications');
  if (listJson == null) return;
  final list = NotificationList.fromJson(listJson);
  final seen = (prefs.getStringList(kBgSeenIds) ?? const <String>[]).toSet();
  final fresh = freshNotifications(
    items: list.items,
    seen: seen,
    baselineMs: prefs.getInt(kBgBaselineMs) ?? 0,
  );

  // Record every current id as seen (bounded) + advance the rev, whether or not we show.
  final merged = <String>{
    ...seen,
    ...list.items.map((n) => n.id).where((s) => s.isNotEmpty),
  }.toList();
  await prefs.setStringList(
    kBgSeenIds,
    merged.length > kBgSeenCap
        ? merged.sublist(merged.length - kBgSeenCap)
        : merged,
  );
  await prefs.setInt(kBgLastRev, notifRev);
  if (fresh.isEmpty) return;

  await NotifyService.init(handleTaps: false);
  final l = _localizations(prefs);
  final locale = l.localeName;
  if (fresh.length > _maxIndividual) {
    await NotifyService.show(
      _summaryNotifId,
      l.notifSummaryTitle(fresh.length),
      l.notifSummaryBody,
      channelName: l.notifChannelName,
    );
  } else {
    for (final n in fresh) {
      await NotifyService.show(
        n.id.hashCode & 0x7fffffff,
        notifTitle(l, n, locale),
        notifBody(l, n, locale),
        channelName: l.notifChannelName,
      );
    }
  }
}

/// Rotate the refresh token to obtain a usable access token. Marks the rotation so the foreground
/// adopts the new tokens on resume instead of refreshing again and racing this isolate (§4.6). The
/// backend's 60s reuse-detection grace makes a rare race benign (a normal 401, not a mass logout).
Future<String?> _refresh(
  Dio dio,
  FlutterSecureStorage store,
  SharedPreferences prefs,
  String rt,
) async {
  await prefs.setInt(
    kBgRefreshStartedMs,
    DateTime.now().millisecondsSinceEpoch,
  );
  try {
    final resp = await dio.post<dynamic>(
      '/auth/refresh',
      data: <String, dynamic>{'refresh_token': rt},
      // omit app_version: the server falls back to the session's stored value; a 426 here just
      // ends the round (the foreground handles the mandatory-update flow).
    );
    final data = resp.data;
    if (data is! Map) return null;
    final access = data['access_token'];
    final newRt = data['refresh_token'];
    if (access is! String ||
        access.isEmpty ||
        newRt is! String ||
        newRt.isEmpty) {
      return null;
    }
    // Persist the rotated pair, THEN raise the flag LAST, so the foreground never sees
    // bg_rotated=true before the tokens are on disk.
    await store.write(key: 'refresh_token', value: newRt);
    await store.write(key: kSecBgAccessToken, value: access);
    await prefs.setBool(kBgRotated, true);
    return access;
  } on DioException {
    return null; // 401 / 426 / network — never force a logout from here
  } finally {
    await prefs.remove(kBgRefreshStartedMs);
  }
}

Future<Map<String, dynamic>?> _getJson(Dio dio, String path) async {
  try {
    final resp = await dio.get<dynamic>(path);
    final data = resp.data;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  } on DioException {
    return null;
  }
}

AppLocalizations _localizations(SharedPreferences prefs) {
  final code = prefs.getString(kPrefLocale);
  final lang = code == 'en'
      ? 'en'
      : 'it'; // catalog only ships it/en; default it
  return lookupAppLocalizations(Locale(lang));
}
