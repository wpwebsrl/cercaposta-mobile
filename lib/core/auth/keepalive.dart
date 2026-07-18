import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// Foreground session keepalive: while the app is visible and authenticated,
/// rotate the refresh token every [interval]. One rotation slides BOTH the
/// refresh-token window (60 days on mobile) and the server-side DEK vault TTL,
/// so a foregrounded app never hits "session expired" nor the lock screen from
/// idleness alone.
///
/// In background the OS suspends timers — by design: the mobile refresh window
/// is 60 days and reopening goes through the (biometric) unlock anyway. On
/// resume an immediate tick revives session + DEK before the first user action.
class SessionKeepalive with WidgetsBindingObserver {
  SessionKeepalive(this._ref);

  static const Duration interval = Duration(minutes: 10);

  final Ref _ref;
  Timer? _timer;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Resume goes through onResume (not a bare tick): it adopts any tokens the background
      // notification isolate rotated while we were away before doing its own refresh (§4.6).
      unawaited(_ref.read(authProvider.notifier).onResume());
      _restart();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  void _tick() {
    // No-op when logged out (keepaliveTick guards on the access token).
    unawaited(_ref.read(authProvider.notifier).keepaliveTick());
  }
}

/// Watch once from the app root; lives for the whole app.
final sessionKeepaliveProvider = Provider<SessionKeepalive>((ref) {
  final keepalive = SessionKeepalive(ref);
  ref.onDispose(keepalive.dispose);
  keepalive.start();
  return keepalive;
});
