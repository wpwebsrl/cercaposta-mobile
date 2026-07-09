import '../../core/api/json.dart';

/// Public discovery payload from GET /api/v1/meta.
class MetaInfo {
  const MetaInfo({
    required this.name,
    required this.version,
    required this.apiPrefix,
    required this.aiEnabled,
    required this.chat,
    required this.encryption,
    required this.voice,
    required this.minIos,
    required this.minAndroid,
    required this.minFeatureIos,
    required this.minFeatureAndroid,
    required this.needsSetup,
  });

  final String name;
  final String version;
  final String apiPrefix;
  final bool aiEnabled;
  final bool chat;
  final bool encryption;
  final String voice;
  // AUTH floor: below it the app can't authenticate (docs/aggiornamenti.md).
  final String minIos;
  final String minAndroid;
  // FEATURE floor: below it the app must update (→ store). Admin `app.min_*_version` raises it.
  final String minFeatureIos;
  final String minFeatureAndroid;
  final bool needsSetup;

  factory MetaInfo.fromJson(Map<String, dynamic> j) {
    final features = jsonMap(j, 'features');
    final minVer = jsonMap(j, 'min_app_version');
    final minFeat = jsonMap(j, 'min_feature_version');
    return MetaInfo(
      name: jsonStr(j, 'name'),
      version: jsonStr(j, 'version'),
      apiPrefix: jsonStr(j, 'api_prefix', '/api/v1'),
      aiEnabled: jsonBool(features, 'ai_enabled'),
      chat: jsonBool(features, 'chat'),
      encryption: jsonBool(features, 'encryption'),
      voice: jsonStr(features, 'voice', 'on_device'),
      minIos: jsonStr(minVer, 'ios', '0.0.0'),
      minAndroid: jsonStr(minVer, 'android', '0.0.0'),
      minFeatureIos: jsonStr(minFeat, 'ios', '0.0.0'),
      minFeatureAndroid: jsonStr(minFeat, 'android', '0.0.0'),
      needsSetup: jsonBool(j, 'needs_setup'),
    );
  }

  /// A valid CercaPosta server exposes a name and the standard api prefix.
  bool get looksValid => name.isNotEmpty && apiPrefix == '/api/v1';

  /// Auth floor for this platform client (empty → not applicable / web).
  String authMinFor(String client) => client == 'ios'
      ? minIos
      : client == 'android'
      ? minAndroid
      : '';

  /// Feature floor for this platform client (empty → not applicable / web).
  String featureMinFor(String client) => client == 'ios'
      ? minFeatureIos
      : client == 'android'
      ? minFeatureAndroid
      : '';
}

/// True when [current] < [min] under MAJOR.MINOR.PATCH semantics — a plain
/// string compare would get "1.10.0" < "1.9.0" wrong (docs/mobile-apps.md §4.1).
bool versionBelow(String current, String min) {
  List<int> parse(String v) => v
      .split('.')
      .map(
        (p) =>
            int.tryParse(
              RegExp(r'^\d+').firstMatch(p.trim())?.group(0) ?? '',
            ) ??
            0,
      )
      .toList();
  final c = parse(current);
  final m = parse(min);
  for (var i = 0; i < 3; i++) {
    final a = i < c.length ? c[i] : 0;
    final b = i < m.length ? m[i] : 0;
    if (a != b) return a < b;
  }
  return false;
}
