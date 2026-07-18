import 'package:cercaposta/core/background/notify_task.dart';
import 'package:cercaposta/shared/models/notification.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationItem _n(String id, {DateTime? created, bool read = false}) =>
    NotificationItem(
      id: id,
      type: 'followup.due_soon',
      params: const <String, dynamic>{},
      readAt: read ? DateTime.utc(2026) : null,
      createdAt: created ?? DateTime.utc(2026, 7, 17, 12),
    );

void main() {
  final baseline = DateTime.utc(2026, 7, 17, 10).millisecondsSinceEpoch;

  test('returns new, unread, post-baseline ids not already seen', () {
    final fresh = freshNotifications(
      items: <NotificationItem>[_n('a'), _n('b')],
      seen: <String>{'a'},
      baselineMs: baseline,
    );
    expect(fresh.map((n) => n.id), <String>['b']);
  });

  test('excludes already-read notifications', () {
    final fresh = freshNotifications(
      items: <NotificationItem>[_n('a', read: true)],
      seen: const <String>{},
      baselineMs: baseline,
    );
    expect(fresh, isEmpty);
  });

  test(
    'excludes notifications created at/before the baseline (existing backlog)',
    () {
      final fresh = freshNotifications(
        items: <NotificationItem>[
          _n('old', created: DateTime.utc(2026, 7, 17, 9)),
        ],
        seen: const <String>{},
        baselineMs: baseline,
      );
      expect(fresh, isEmpty);
    },
  );

  test('excludes items with an empty id', () {
    final fresh = freshNotifications(
      items: <NotificationItem>[_n('')],
      seen: const <String>{},
      baselineMs: baseline,
    );
    expect(fresh, isEmpty);
  });
}
