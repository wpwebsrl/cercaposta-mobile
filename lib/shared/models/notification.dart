import '../../core/api/json.dart';

/// A per-user in-app notification. The backend sends a machine `type` + `params`;
/// the client renders the localized text (i18n rule — no user strings server-side).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.params,
    this.readAt,
    this.dismissedAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> params;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime? createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
    id: jsonStr(j, 'id'),
    type: jsonStr(j, 'type'),
    params: jsonMap(j, 'params'),
    readAt: jsonDate(j, 'read_at'),
    dismissedAt: jsonDate(j, 'dismissed_at'),
    createdAt: jsonDate(j, 'created_at'),
  );
}

class NotificationList {
  const NotificationList({required this.items, required this.unreadCount});

  final List<NotificationItem> items;
  final int unreadCount;

  factory NotificationList.fromJson(Map<String, dynamic> j) => NotificationList(
    items: jsonObjList(j, 'items').map(NotificationItem.fromJson).toList(),
    unreadCount: jsonInt(j, 'unread_count'),
  );
}
