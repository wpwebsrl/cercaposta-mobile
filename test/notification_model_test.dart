import 'package:cercaposta/shared/models/notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationList.fromJson parses items + unread_count', () {
    final list = NotificationList.fromJson(<String, dynamic>{
      'unread_count': 2,
      'items': <dynamic>[
        <String, dynamic>{
          'id': 'n1',
          'type': 'reprocess_recommended',
          'params': <String, dynamic>{'count': 5},
          'created_at': '2026-07-09T10:00:00Z',
        },
      ],
    });
    expect(list.unreadCount, 2);
    expect(list.items.single.type, 'reprocess_recommended');
    expect(list.items.single.params['count'], 5);
    expect(list.items.single.readAt, isNull);
    expect(list.items.single.createdAt, isNotNull);
  });

  test('NotificationList.fromJson tolerates missing/empty payload', () {
    final list = NotificationList.fromJson(<String, dynamic>{});
    expect(list.unreadCount, 0);
    expect(list.items, isEmpty);
  });
}
