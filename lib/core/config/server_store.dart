import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the list of known servers and the active one (non-sensitive → prefs).
class ServerStore {
  ServerStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kServers = 'servers';
  static const _kActive = 'active_server';

  List<String> servers() => _prefs.getStringList(_kServers) ?? const <String>[];

  String? activeServer() => _prefs.getString(_kActive);

  Future<void> setActive(String url) async {
    final list = servers();
    if (!list.contains(url)) {
      await _prefs.setStringList(_kServers, [...list, url]);
    }
    await _prefs.setString(_kActive, url);
  }

  Future<void> clearActive() => _prefs.remove(_kActive);

  Future<void> remove(String url) async {
    await _prefs.setStringList(
      _kServers,
      servers().where((s) => s != url).toList(),
    );
    if (activeServer() == url) await _prefs.remove(_kActive);
  }

  /// Normalize a user-entered URL: add https:// if missing, lowercase the
  /// scheme (mobile autocapitalize types "Https://…"), strip trailing slash.
  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    final m = RegExp(
      r'^(https?)://(.*)$',
      caseSensitive: false,
    ).firstMatch(url);
    if (m != null) {
      url = '${m.group(1)!.toLowerCase()}://${m.group(2)}';
    } else {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Whether a (normalized) server URL may be used over cleartext http.
  /// HTTPS is mandatory (docs/mobile-apps.md §10: "rifiuto esplicito di http://"):
  /// dart:io sockets bypass Android's cleartext block and iOS ATS, so the app
  /// must enforce it itself. Plain http is tolerated ONLY in debug builds and
  /// only toward loopback / the Android-emulator host, for local development.
  static bool allowsCleartext(String url) {
    if (!url.startsWith('http://')) return true;
    if (!kDebugMode) return false;
    final host = Uri.tryParse(url)?.host ?? '';
    return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
  }
}
