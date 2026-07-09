import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/dio_factory.dart';
import 'auth/secure_store.dart';
import 'config/app_info.dart';
import 'config/server_store.dart';

/// Overridden in main() after async startup loads.
final appInfoProvider = Provider<AppInfo>((ref) => throw UnimplementedError());
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final serverStoreProvider = Provider<ServerStore>(
  (ref) => ServerStore(ref.watch(sharedPreferencesProvider)),
);

/// Active server URL (origin, without /api/v1). Null ⇒ no server chosen yet.
class ActiveServer extends Notifier<String?> {
  @override
  String? build() => ref.watch(serverStoreProvider).activeServer();

  Future<void> select(String url) async {
    await ref.read(serverStoreProvider).setActive(url);
    state = url;
  }

  Future<void> clear() async {
    await ref.read(serverStoreProvider).clearActive();
    state = null;
  }
}

final activeServerProvider = NotifierProvider<ActiveServer, String?>(
  ActiveServer.new,
);

/// Base for the API: `<server>/api/v1` (empty until a server is chosen).
final apiBaseProvider = Provider<String>((ref) {
  final s = ref.watch(activeServerProvider);
  return s == null ? '' : '$s/api/v1';
});

/// Plain Dio (no auth interceptor) for discovery and the auth flow itself.
final authDioProvider = Provider<Dio>(
  (ref) => buildDio(ref.watch(apiBaseProvider)),
);
