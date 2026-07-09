import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Static facts about this install: the `client` claim value, the app version
/// (sent as app_version and compared against /meta.min_app_version) and a
/// human device name for the sessions list.
class AppInfo {
  const AppInfo({
    required this.client,
    required this.version,
    required this.deviceName,
  });

  final String client; // ios | android | web
  final String version;
  final String deviceName;

  /// Build identity, mirroring the web (Vite `__APP_BUILD__`): the last git short
  /// SHA and commit date, injected at build time via
  /// `--dart-define=APP_BUILD=<sha> --dart-define=APP_BUILD_DATE=<yyyy-mm-dd>`
  /// (see .github/workflows/mobile.yml). Defaults to "dev"/"" for local runs.
  static const String build = String.fromEnvironment(
    'APP_BUILD',
    defaultValue: 'dev',
  );
  static const String buildDate = String.fromEnvironment('APP_BUILD_DATE');

  /// Android application id (Play Store deep link + web fallback).
  static const String androidAppId = 'it.cercaposta.app';

  /// iOS store URL for the mandatory-update button. Empty until the app ships on
  /// the App Store; on TestFlight pass the public TestFlight link at build time:
  /// `--dart-define=STORE_URL_IOS=https://testflight.apple.com/join/xxxx`.
  static const String iosStoreUrl = String.fromEnvironment('STORE_URL_IOS');

  /// Where the mandatory-update button should send the user, most-preferred first
  /// (the store app, then a web fallback). Empty when no store URL is known.
  List<Uri> storeUpdateUris() {
    if (client == 'android') {
      return <Uri>[
        Uri.parse('market://details?id=$androidAppId'),
        Uri.parse(
          'https://play.google.com/store/apps/details?id=$androidAppId',
        ),
      ];
    }
    if (client == 'ios' && iosStoreUrl.isNotEmpty) {
      return <Uri>[Uri.parse(iosStoreUrl)];
    }
    return const <Uri>[];
  }

  static Future<AppInfo> load() async {
    final pkg = await PackageInfo.fromPlatform();
    final di = DeviceInfoPlugin();
    String client = 'web';
    String device = 'device';
    if (Platform.isIOS) {
      client = 'ios';
      device = (await di.iosInfo).name;
    } else if (Platform.isAndroid) {
      client = 'android';
      final info = await di.androidInfo;
      device = '${info.manufacturer} ${info.model}'.trim();
    }
    return AppInfo(
      client: client,
      version: pkg.version,
      deviceName: device.isEmpty ? client : device,
    );
  }
}
