import 'package:cercaposta/shared/models/followup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FollowupItem.fromJson maps every field', () {
    final item = FollowupItem.fromJson(<String, dynamic>{
      'id': 'f1',
      'direction': 'their_turn',
      'state': 'expired',
      'counterpart_name': 'Mario Rossi',
      'counterpart_address': 'mario@acme.it',
      'summary': 'costi del computer',
      'due_at': '2026-07-10T00:00:00Z',
      'snooze_until': null,
      'origin': 'llm',
      'thread_id': 't1',
      'message_id': 'm1',
      'created_at': '2026-07-05T09:00:00Z',
      'reminder_count': 2,
      'last_reminder_at': '2026-07-11T08:00:00Z',
    });
    expect(item.id, 'f1');
    expect(item.counterpartLabel, 'Mario Rossi');
    expect(item.dueAt, isNotNull);
    expect(item.reminderCount, 2);
    expect(item.lastReminderAt, isNotNull);
    expect(item.isActive, isTrue); // expired is active
    expect(item.canRemind, isTrue); // their_turn + expired
  });

  test('counterpartLabel falls back to the address', () {
    final item = FollowupItem.fromJson(<String, dynamic>{
      'id': 'f2',
      'counterpart_address': 'x@y.z',
    });
    expect(item.counterpartLabel, 'x@y.z');
  });

  test('isActive / canRemind by state and direction', () {
    FollowupItem it(String dir, String state) => FollowupItem.fromJson(
      <String, dynamic>{'direction': dir, 'state': state},
    );
    expect(it('their_turn', 'open').isActive, isTrue);
    expect(it('their_turn', 'snoozed').isActive, isTrue);
    expect(it('their_turn', 'answered').isActive, isFalse);
    expect(it('their_turn', 'dismissed').isActive, isFalse);
    // Only an alive their_turn can be reminded.
    expect(it('their_turn', 'reminded').canRemind, isTrue);
    expect(it('their_turn', 'open').canRemind, isFalse);
    expect(it('my_turn', 'expired').canRemind, isFalse);
  });

  test('FollowupList.fromJson tolerates an empty payload', () {
    final list = FollowupList.fromJson(<String, dynamic>{});
    expect(list.total, 0);
    expect(list.items, isEmpty);
  });

  test('ReminderDraft.fromJson maps the send capability', () {
    final draft = ReminderDraft.fromJson(<String, dynamic>{
      'subject': 'Re: preventivo',
      'body': 'Ciao, un promemoria…',
      'reminder_prefix': '',
      'reminder_suffix': '-- \nDavide',
      'register_used': 'lei',
      'register_source': 'detected',
      'language': 'it',
      'include_original': true,
      'send_available': true,
      'send_from': 'davide@studio.it',
    });
    expect(draft.subject, 'Re: preventivo');
    expect(draft.registerUsed, 'lei');
    expect(draft.includeOriginal, isTrue);
    expect(draft.sendAvailable, isTrue);
    expect(draft.sendFrom, 'davide@studio.it');
  });

  test('FollowupStatus.available needs configured AND enabled', () {
    FollowupStatus st(bool c, bool e) => FollowupStatus.fromJson(
      <String, dynamic>{'configured': c, 'enabled': e},
    );
    expect(st(true, true).available, isTrue);
    expect(st(true, false).available, isFalse);
    expect(st(false, true).available, isFalse);
    expect(
      FollowupStatus.fromJson(<String, dynamic>{'paused': 'billing'}).paused,
      'billing',
    );
  });
}
