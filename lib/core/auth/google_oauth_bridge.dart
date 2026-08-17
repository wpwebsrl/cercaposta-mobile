import 'dart:async';

import 'package:app_links/app_links.dart';

/// Delivers only the private-use callback reserved to CercaPosta.
///
/// The authorization code in this URI is still harmless on its own: the backend also requires
/// the PKCE verifier kept in the OS secure store by [AuthController].
class GoogleOAuthBridge {
  GoogleOAuthBridge() : _links = AppLinks();

  final AppLinks _links;
  final StreamController<Uri> _callbacks = StreamController<Uri>.broadcast();
  StreamSubscription<Uri>? _subscription;
  Uri? _initial;

  static bool isGoogleCallback(Uri uri) =>
      uri.scheme == 'it.cercaposta.app' &&
      uri.host == 'oauth' &&
      uri.path == '/google';

  Future<void> initialize() async {
    try {
      final initial = await _links.getInitialLink();
      if (initial != null && isGoogleCallback(initial)) _initial = initial;
    } on Object {
      // A missing platform link service must not block ordinary password/passkey login.
    }
    _subscription = _links.uriLinkStream.listen((uri) {
      if (!isGoogleCallback(uri)) return;
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
