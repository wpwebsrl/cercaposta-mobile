import 'dart:async';

import 'package:app_links/app_links.dart';

/// Delivers only the browser callback reserved to Sign in with Apple.
class AppleOAuthBridge {
  AppleOAuthBridge() : _links = AppLinks();

  final AppLinks _links;
  final StreamController<Uri> _callbacks = StreamController<Uri>.broadcast();
  StreamSubscription<Uri>? _subscription;
  Uri? _initial;

  static bool isAppleCallback(Uri uri) =>
      uri.scheme == 'it.cercaposta.app' &&
      uri.host == 'oauth' &&
      uri.path == '/apple';

  Future<void> initialize() async {
    try {
      final initial = await _links.getInitialLink();
      if (initial != null && isAppleCallback(initial)) _initial = initial;
    } on Object {
      // A missing platform link service must not block other sign-in methods.
    }
    _subscription = _links.uriLinkStream.listen((uri) {
      if (!isAppleCallback(uri)) return;
      _initial = uri;
      _callbacks.add(uri);
    });
  }

  Uri? takeInitial() {
    final value = _initial;
    _initial = null;
    return value;
  }

  Future<Uri> waitForState(String state) async {
    final initial = takeInitial();
    if (initial != null && initial.queryParameters['state'] == state) {
      return initial;
    }
    return _callbacks.stream
        .firstWhere((uri) => uri.queryParameters['state'] == state)
        .timeout(const Duration(minutes: 5));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _callbacks.close();
  }
}
