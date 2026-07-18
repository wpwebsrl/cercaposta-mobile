import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/notifications_controller.dart';
import '../../features/search/folder_drawer.dart';
import '../api/api_providers.dart';
import '../auth/auth_controller.dart';
import '../background/bg_constants.dart';
import '../providers.dart';

/// The latest archive revision the server reported. The search screen watches this to offer a
/// discreet «new results» affordance — on mobile the list is never re-run under the user's thumb
/// (only the tree/counts/badge refresh on their own; the list refreshes on tap or pull-to-refresh).
final liveArchiveRevProvider = StateProvider<int>((ref) => 0);

/// Foreground live refresh (docs/eventi-live.md): while the app is visible and authenticated,
/// poll the change-state every [interval] (and immediately on resume), then re-fetch whatever
/// scope advanced — own folders, received shares, the notification badge. Deliberately a poll,
/// not a persistent SSE stream: on mobile the radio/battery cost of a kept-open socket isn't
/// worth ~40s of latency, and the OS tears streams down in background anyway.
class LiveRefresh with WidgetsBindingObserver {
  LiveRefresh(this._ref);

  static const Duration interval = Duration(seconds: 45);

  final Ref _ref;
  Timer? _timer;
  bool _seeded = false;
  Map<String, int> _revs = const {
    'archive': 0,
    'shares': 0,
    'notifications': 0,
  };

  void start() {
    WidgetsBinding.instance.addObserver(this);
    // A server/user switch resets the perimeter: drop the baseline so the next poll re-seeds
    // instead of diffing user B's revisions against user A's (and clear the chip signal).
    _ref.listen(sessionKeyProvider, (_, __) {
      _seeded = false;
      _revs = const {'archive': 0, 'shares': 0, 'notifications': 0};
      _ref.read(liveArchiveRevProvider.notifier).state = 0;
    });
    _restart();
    unawaited(_tick());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(_tick()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_tick()); // reconcile promptly after a background stint
      _restart();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> _tick() async {
    if (_ref.read(authProvider).accessToken == null) return;
    // Heartbeat: mark the foreground as active so the background notification isolate stands down
    // (it must not refresh tokens while we might too — reuse-detection guard, docs/notifiche.md).
    _ref
        .read(sharedPreferencesProvider)
        .setInt(kBgHeartbeatMs, DateTime.now().millisecondsSinceEpoch);
    try {
      final s = await _ref.read(eventsApiProvider).state();
      _apply(s.revs);
    } on Object {
      // transient — the next tick (or a pull-to-refresh) recovers
    }
  }

  void _apply(Map<String, int> next) {
    final a = next['archive'] ?? 0;
    final sh = next['shares'] ?? 0;
    final n = next['notifications'] ?? 0;
    if (!_seeded) {
      // First reading after (re)connect is the baseline, not a change: don't flash the chip or
      // refetch on app open — just record it and refresh the badge once so it's exact.
      _seeded = true;
      _revs = {'archive': a, 'shares': sh, 'notifications': n};
      _ref.invalidate(notificationUnreadCountProvider);
      return;
    }
    if (a != _revs['archive']) {
      _ref.invalidate(foldersTreeProvider);
      _ref.invalidate(shareTreeProvider);
      _ref.read(liveArchiveRevProvider.notifier).state =
          a; // → «new results» chip
    }
    if (sh != _revs['shares']) {
      _ref.invalidate(sharesReceivedProvider);
      _ref.invalidate(shareTreeProvider);
      _ref.invalidate(foldersTreeProvider);
    }
    if (n != _revs['notifications']) {
      _ref.invalidate(notificationUnreadCountProvider);
    }
    _revs = {'archive': a, 'shares': sh, 'notifications': n};
  }
}

/// Watch once from the app root; lives for the whole app.
final liveRefreshProvider = Provider<LiveRefresh>((ref) {
  final live = LiveRefresh(ref);
  ref.onDispose(live.dispose);
  live.start();
  return live;
});
