/// Small strict-safe helpers to read dynamic JSON without implicit casts
/// (the analyzer runs with strict-casts/strict-inference). Tolerant to nulls
/// and wrong types: the API may legitimately send null for optional fields.
library;

String jsonStr(Map<String, dynamic> j, String key, [String def = '']) {
  final v = j[key];
  return v is String ? v : def;
}

String? jsonStrOrNull(Map<String, dynamic> j, String key) {
  final v = j[key];
  return v is String ? v : null;
}

int jsonInt(Map<String, dynamic> j, String key, [int def = 0]) {
  final v = j[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return def;
}

bool jsonBool(Map<String, dynamic> j, String key, [bool def = false]) {
  final v = j[key];
  return v is bool ? v : def;
}

DateTime? jsonDate(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

List<String> jsonStrList(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is List) return v.whereType<String>().toList();
  return const <String>[];
}

List<Map<String, dynamic>> jsonObjList(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is List) return v.whereType<Map<String, dynamic>>().toList();
  return const <Map<String, dynamic>>[];
}

Map<String, dynamic> jsonMap(Map<String, dynamic> j, String key) {
  final v = j[key];
  return v is Map<String, dynamic> ? v : <String, dynamic>{};
}

/// Decode a top-level response body that should be a JSON object.
Map<String, dynamic> mapOf(Object? data) =>
    data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

/// Decode a top-level response body that should be a JSON array of objects.
List<Map<String, dynamic>> listOf(Object? data) => data is List
    ? data.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];
