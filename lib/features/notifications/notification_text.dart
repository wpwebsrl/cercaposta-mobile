import 'package:flutter/material.dart';

import '../../core/i18n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/models/notification.dart';

/// Localize a notification into its (title, body, icon) from the machine `type` + `params`.
/// Shared by the notifications screen and the background OS-notification task (notify_task.dart),
/// so both render identically (docs/notifiche.md). Pure — no BuildContext — so the background
/// isolate can call it with an [AppLocalizations] built via `lookupAppLocalizations`.

String _p(NotificationItem n, String key) {
  final v = n.params[key];
  return v is String ? v : '';
}

int _pi(NotificationItem n, String key) {
  final v = n.params[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}

/// Format an ISO date/datetime param with the profile locale, falling back to the raw string.
String _pDate(NotificationItem n, String key, String locale) {
  final raw = _p(n, key);
  final dt = DateTime.tryParse(raw);
  return dt == null ? raw : formatDateShort(dt, locale);
}

IconData notifIcon(String type) => switch (type) {
  'reprocess_recommended' => Icons.build_outlined,
  'followup.reminder_sent' => Icons.mark_email_read_outlined,
  'followup.digest' => Icons.summarize_outlined,
  _ when type.startsWith('followup.') => Icons.hourglass_bottom,
  _ when type.startsWith('sales.plan_change') => Icons.event_repeat_outlined,
  _ => Icons.notifications_outlined,
};

String notifTitle(AppLocalizations l, NotificationItem n, String locale) =>
    switch (n.type) {
      'reprocess_recommended' => l.notifReprocessTitle,
      'followup.no_reply' => l.notifFollowupNoReplyTitle(_p(n, 'name')),
      'followup.reply_due' => l.notifFollowupReplyDueTitle(_p(n, 'name')),
      'followup.due_soon' => l.notifFollowupDueSoonTitle,
      'followup.reminder_sent' => l.notifFollowupReminderSentTitle(
        _p(n, 'name'),
      ),
      'followup.digest' => l.notifFollowupDigestTitle,
      'sales.plan_change_proposal' => l.notifPlanChangeProposalTitle,
      'sales.plan_change_proposal_expiring' =>
        l.notifPlanChangeProposalExpiringTitle,
      'sales.plan_change_expired' => l.notifPlanChangeExpiredTitle,
      'sales.plan_change_scheduled' => l.notifPlanChangeScheduledTitle,
      'sales.plan_change_applied' => l.notifPlanChangeAppliedTitle,
      'sales.plan_change_canceled' => l.notifPlanChangeCanceledTitle,
      'sales.plan_change_payment_failed' =>
        l.notifPlanChangePaymentFailedTitle,
      'sales.plan_change_retry_started' => l.notifPlanChangeRetryTitle,
      'sales.plan_change_grace_expiring' =>
        l.notifPlanChangeGraceExpiringTitle,
      'sales.plan_change_grace_expired' => l.notifPlanChangeGraceExpiredTitle,
      'sales.plan_change_action_required' =>
        l.notifPlanChangeActionRequiredTitle,
      _ => l.notificationsTitle,
    };

String notifBody(AppLocalizations l, NotificationItem n, String locale) =>
    switch (n.type) {
      'reprocess_recommended' => l.notifReprocessBody,
      'followup.no_reply' => l.notifFollowupNoReplyBody(
        _p(n, 'summary'),
        _pi(n, 'days'),
      ),
      'followup.reply_due' => l.notifFollowupReplyDueBody(
        _p(n, 'summary'),
        _pi(n, 'days'),
      ),
      'followup.due_soon' => l.notifFollowupDueSoonBody(
        _p(n, 'summary'),
        _p(n, 'name'),
        _pDate(n, 'due_date', locale),
      ),
      'followup.reminder_sent' => l.notifFollowupReminderSentBody(
        _p(n, 'summary'),
      ),
      'followup.digest' => l.notifFollowupDigestBody(
        _pi(n, 'overdue'),
        _pi(n, 'due_today'),
        _pi(n, 'waiting_me'),
      ),
      'sales.plan_change_proposal' => l.notifPlanChangeProposalBody,
      'sales.plan_change_proposal_expiring' =>
        l.notifPlanChangeProposalExpiringBody(
          _pDate(n, 'proposal_expires_at', locale),
        ),
      'sales.plan_change_expired' => l.notifPlanChangeExpiredBody,
      'sales.plan_change_scheduled' => l.notifPlanChangeScheduledBody(
        _pDate(n, 'effective_at', locale),
      ),
      'sales.plan_change_applied' => l.notifPlanChangeAppliedBody,
      'sales.plan_change_canceled' => l.notifPlanChangeCanceledBody,
      'sales.plan_change_payment_failed' =>
        l.notifPlanChangePaymentFailedBody(
          _pDate(n, 'grace_until', locale),
        ),
      'sales.plan_change_retry_started' => l.notifPlanChangeRetryBody,
      'sales.plan_change_grace_expiring' =>
        l.notifPlanChangeGraceExpiringBody(
          _pDate(n, 'grace_until', locale),
        ),
      'sales.plan_change_grace_expired' => l.notifPlanChangeGraceExpiredBody,
      'sales.plan_change_action_required' =>
        l.notifPlanChangeActionRequiredBody,
      _ => '',
    };
