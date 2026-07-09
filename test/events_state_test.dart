import 'package:cercaposta/core/api/services/events_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EventsState.fromJson parses the three revs + unread_count', () {
    final s = EventsState.fromJson(<String, dynamic>{
      'revs': <String, dynamic>{'archive': 5, 'shares': 2, 'notifications': 1},
      'unread_count': 3,
    });
    expect(s.revs['archive'], 5);
    expect(s.revs['shares'], 2);
    expect(s.revs['notifications'], 1);
    expect(s.unreadCount, 3);
  });

  test('EventsState.fromJson tolerates a missing/empty payload (all zero)', () {
    final s = EventsState.fromJson(<String, dynamic>{});
    expect(s.revs['archive'], 0);
    expect(s.revs['shares'], 0);
    expect(s.revs['notifications'], 0);
    expect(s.unreadCount, 0);
  });

  test('EventsState.fromJson defaults a partial revs map to zero', () {
    final s = EventsState.fromJson(<String, dynamic>{
      'revs': <String, dynamic>{'archive': 7},
    });
    expect(s.revs['archive'], 7);
    expect(s.revs['shares'], 0);
    expect(s.revs['notifications'], 0);
  });
}
