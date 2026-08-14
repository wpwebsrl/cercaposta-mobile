class PasskeyInfo {
  const PasskeyInfo({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.backedUp,
    required this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String name;
  final String deviceType;
  final bool backedUp;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  factory PasskeyInfo.fromJson(Map<String, dynamic> json) => PasskeyInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    deviceType: json['device_type'] as String? ?? '',
    backedUp: json['backed_up'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
  );
}
