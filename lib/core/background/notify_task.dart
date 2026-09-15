import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/notifications/notification_text.dart';
import '../../shared/models/notification.dart';
import '../i18n/app_localizations.dart';
import '../notify/notify_service.dart';
import '../auth/secure_store.dart';
import '../auth/session_coordinator.dart';
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

Future<void> runNotifyPoll({
  SharedPreferences? preferences,
  SessionCoordinator? coordinator,
  Dio? client,
  Future<void> Function(List<NotificationItem>, AppLocalizations)? publish,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = preferences ?? await SharedPreferences.getInstance();
  await prefs.reload();
  if (!(prefs.getBool(kPrefOsNotifications) ?? false)) return;
  final heartbeat = prefs.getInt(kBgHeartbeatMs) ?? 0;
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  if (heartbeat != 0 &&
      nowMs - heartbeat < kForegroundActiveWindow.inMilliseconds) {
    return;
  }
  final server = prefs.getString('active_server');
  if (server == null || server.isEmpty) return;
  final sessions = coordinator ?? SessionCoordinator(SecureStore());
  final lease = await sessions.acquire(server);
  if (lease == null) return;
  final dio =
      client ??
      Dio(
        BaseOptions(
          baseUrl: '$server/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: const <String, dynamic>{'Accept': 'application/json'},
        ),
      );
  try {
    final session = await _refresh(dio, sessions, lease);
    if (session == null) return;
    dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    final state = await _getJson(dio, '/events/state');
    if (state == null) return;
    final revs = state['revs'];
    final revision = (revs is Map && revs['notifications'] is num)
        ? (revs['notifications'] as num).toInt()
        : 0;
    await prefs.reload();
    if (prefs.getString(kBgSessionId) == session.id &&
        prefs.getInt(kBgLastRev) == revision &&
        prefs.getInt(kBgBaselineMs) != null) {
      return;
    }
    final data = await _getJson(dio, '/notifications');
    if (data == null) return;
    final list = NotificationList.fromJson(data);
    // Publication and baseline updates share the logout lock. A late worker may
    // neither overwrite B's baseline nor show A's notifications after logout.
    await sessions.whileCurrent(session, () async {
      await prefs.reload();
      if (!(prefs.getBool(kPrefOsNotifications) ?? false) ||
          prefs.getString('active_server') != session.server) {
        return;
      }
      final isNew =
          prefs.getString(kBgSessionId) != session.id ||
          prefs.getInt(kBgBaselineMs) == null;
      final seen = isNew
          ? <String>{}
          : (prefs.getStringList(kBgSeenIds) ?? <String>[]).toSet();
      final fresh = isNew
          ? <NotificationItem>[]
          : freshNotifications(
              items: list.items,
              seen: seen,
              baselineMs: prefs.getInt(kBgBaselineMs) ?? nowMs,
            );
      final merged = <String>{
        ...seen,
        ...list.items.map((item) => item.id).where((id) => id.isNotEmpty),
      }.toList();
      // Publish before acknowledging IDs: a failed OS call remains retryable.
      if (fresh.isNotEmpty) {
        await (publish ?? _publish)(fresh, _localizations(prefs));
      }
      await prefs.setStringList(
        kBgSeenIds,
        merged.length > kBgSeenCap
            ? merged.sublist(merged.length - kBgSeenCap)
            : merged,
      );
      await prefs.setInt(kBgLastRev, revision);
      if (isNew) await prefs.setInt(kBgBaselineMs, nowMs);
      await prefs.setString(kBgSessionId, session.id);
    });
  } finally {
    await sessions.release(lease);
    if (client == null) dio.close(force: true);
  }
}

Future<void> _publish(List<NotificationItem> fresh, AppLocalizations l) async {
  await NotifyService.init(handleTaps: false);
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
        notifTitle(l, n, l.localeName),
        notifBody(l, n, l.localeName),
        channelName: l.notifChannelName,
      );
    }
  }
}

Future<StoredSession?> _refresh(
  Dio dio,
  SessionCoordinator sessions,
  RefreshLease lease,
) async {
  final cancel = CancelToken();
  try {
    final response = await dio
        .post<dynamic>(
          '/auth/refresh',
          data: <String, dynamic>{'refresh_token': lease.session.refreshToken},
          cancelToken: cancel,
        )
        .timeout(const Duration(seconds: 45));
    final data = response.data;
    if (data is! Map) return null;
    final access = data['access_token'],
        refresh = data['refresh_token'],
        user = data['user'];
    if (access is! String ||
        refresh is! String ||
        user is! Map ||
        user['id'] is! String) {
      return null;
    }
    return await sessions.complete(
      lease,
      accessToken: access,
      refreshToken: refresh,
      userId: user['id'] as String,
    );
  } on Object {
    cancel.cancel('background refresh ended');
    return null; // A background error never logs the foreground out.
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
