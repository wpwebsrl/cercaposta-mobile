import '../../shared/models/followup.dart';

/// The deadline/state chip shown on a row, classified independently of i18n and
/// Material so it stays unit-testable. The screen maps [kind]/[tone] to localized
/// text, an icon and a color. Mirrors the desktop `_chip_for` / `_state_icon_name`.
enum FollowupChipKind {
  answered,
  dismissed,
  snoozed,
  remindedOnce,
  remindedMany,
  overdue,
  dueToday,
  dueTomorrow,
  dueOn,
  none,
}

enum FollowupTone { danger, warn, ok, neutral }

class FollowupChip {
  const FollowupChip(this.kind, this.tone, {this.days = 0, this.date});
  final FollowupChipKind kind;
  final FollowupTone tone;
  final int
  days; // overdue days elapsed, or the reminder count for remindedMany
  final DateTime? date; // reminded / snoozed / dueOn reference date
}

/// Classify a follow-up into its row chip. [now] is injected for testability.
FollowupChip followupChipFor(FollowupItem item, DateTime now) {
  switch (item.state) {
    case 'answered':
      return const FollowupChip(FollowupChipKind.answered, FollowupTone.ok);
    case 'dismissed':
      return const FollowupChip(
        FollowupChipKind.dismissed,
        FollowupTone.neutral,
      );
    case 'snoozed':
      return FollowupChip(
        FollowupChipKind.snoozed,
        FollowupTone.neutral,
        date: item.snoozeUntil ?? item.dueAt,
      );
    case 'reminded':
      final date = item.lastReminderAt ?? item.dueAt;
      if (item.reminderCount > 1) {
        return FollowupChip(
          FollowupChipKind.remindedMany,
          FollowupTone.warn,
          days: item.reminderCount,
          date: date,
        );
      }
      return FollowupChip(
        FollowupChipKind.remindedOnce,
        FollowupTone.warn,
        date: date,
      );
  }
  final due = item.dueAt;
  if (due == null) {
    return const FollowupChip(FollowupChipKind.none, FollowupTone.neutral);
  }
  if (item.state == 'expired' || due.isBefore(now)) {
    final days = (now.difference(due).inDays).clamp(1, 1 << 30);
    return FollowupChip(
      FollowupChipKind.overdue,
      FollowupTone.danger,
      days: days,
    );
  }
  final deltaDays = _dateOnly(due).difference(_dateOnly(now)).inDays;
  if (deltaDays <= 0) {
    return const FollowupChip(FollowupChipKind.dueToday, FollowupTone.warn);
  }
  if (deltaDays == 1) {
    return const FollowupChip(FollowupChipKind.dueTomorrow, FollowupTone.warn);
  }
  return FollowupChip(FollowupChipKind.dueOn, FollowupTone.neutral, date: due);
}

DateTime _dateOnly(DateTime dt) {
  final local = dt.toLocal();
  return DateTime(local.year, local.month, local.day);
}
