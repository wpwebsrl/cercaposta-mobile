import 'package:cercaposta/features/followups/followups_controller.dart';
import 'package:cercaposta/shared/models/followup.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local DateTimes throughout so the chip's toLocal() is a no-op and the
/// day-difference math is deterministic regardless of the test machine's zone.
FollowupItem _item({
  String state = 'open',
  String direction = 'their_turn',
  DateTime? dueAt,
  DateTime? snoozeUntil,
  DateTime? lastReminderAt,
  int reminderCount = 0,
}) => FollowupItem(
  id: 'f',
  direction: direction,
  state: state,
  counterpartName: 'X',
  counterpartAddress: 'x@y.z',
  summary: 's',
  dueAt: dueAt,
  snoozeUntil: snoozeUntil,
  origin: 'llm',
  threadId: 't',
  messageId: 'm',
  createdAt: null,
  reminderCount: reminderCount,
  lastReminderAt: lastReminderAt,
);

void main() {
  final now = DateTime(2026, 7, 12, 10, 0);

  test('answered → ok', () {
    final c = followupChipFor(_item(state: 'answered'), now);
    expect(c.kind, FollowupChipKind.answered);
    expect(c.tone, FollowupTone.ok);
  });

  test('dismissed → neutral', () {
    expect(
      followupChipFor(_item(state: 'dismissed'), now).kind,
      FollowupChipKind.dismissed,
    );
  });

  test('expired → overdue danger with elapsed days', () {
    final c = followupChipFor(
      _item(state: 'expired', dueAt: DateTime(2026, 7, 8, 10, 0)),
      now,
    );
    expect(c.kind, FollowupChipKind.overdue);
    expect(c.tone, FollowupTone.danger);
    expect(c.days, 4);
  });

  test('open but past due → overdue too', () {
    final c = followupChipFor(_item(dueAt: DateTime(2026, 7, 11, 10, 0)), now);
    expect(c.kind, FollowupChipKind.overdue);
    expect(c.days, 1);
  });

  test('due later today → dueToday warn', () {
    final c = followupChipFor(_item(dueAt: DateTime(2026, 7, 12, 18, 0)), now);
    expect(c.kind, FollowupChipKind.dueToday);
    expect(c.tone, FollowupTone.warn);
  });

  test('due tomorrow → dueTomorrow', () {
    final c = followupChipFor(_item(dueAt: DateTime(2026, 7, 13, 9, 0)), now);
    expect(c.kind, FollowupChipKind.dueTomorrow);
  });

  test('due in several days → dueOn neutral with the date', () {
    final due = DateTime(2026, 7, 17, 9, 0);
    final c = followupChipFor(_item(dueAt: due), now);
    expect(c.kind, FollowupChipKind.dueOn);
    expect(c.tone, FollowupTone.neutral);
    expect(c.date, due);
  });

  test('reminded once vs many carries the count and last-reminder date', () {
    final last = DateTime(2026, 7, 11, 8, 0);
    final once = followupChipFor(
      _item(state: 'reminded', reminderCount: 1, lastReminderAt: last),
      now,
    );
    expect(once.kind, FollowupChipKind.remindedOnce);
    expect(once.date, last);

    final many = followupChipFor(
      _item(state: 'reminded', reminderCount: 3, lastReminderAt: last),
      now,
    );
    expect(many.kind, FollowupChipKind.remindedMany);
    expect(many.days, 3); // count reused as `days`
  });

  test('snoozed → neutral with the snooze date', () {
    final until = DateTime(2026, 7, 20, 9, 0);
    final c = followupChipFor(_item(state: 'snoozed', snoozeUntil: until), now);
    expect(c.kind, FollowupChipKind.snoozed);
    expect(c.date, until);
  });

  test('no due date → none', () {
    expect(followupChipFor(_item(), now).kind, FollowupChipKind.none);
  });
}
