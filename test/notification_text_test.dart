import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/notifications/notification_text.dart';
import 'package:cercaposta/shared/models/notification.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationItem _n(String type, Map<String, dynamic> params) =>
    NotificationItem(id: 'x', type: type, params: params, createdAt: DateTime.utc(2026));

void main() {
  final l = lookupAppLocalizations(const Locale('it'));

  test('reprocess title/body come from the catalog (shared with the screen)', () {
    final n = _n('reprocess_recommended', const <String, dynamic>{});
    expect(notifTitle(l, n, 'it'), l.notifReprocessTitle);
    expect(notifBody(l, n, 'it'), l.notifReprocessBody);
  });

  test('follow-up no_reply interpolates the counterpart name and days', () {
    final n = _n('followup.no_reply', const <String, dynamic>{
      'name': 'Mario Rossi',
      'summary': 'costi del computer',
      'days': 4,
    });
    expect(notifTitle(l, n, 'it'), contains('Mario Rossi'));
    expect(notifBody(l, n, 'it'), contains('costi del computer'));
  });

  test('unknown type falls back to a generic title and an empty body', () {
    final n = _n('something_new', const <String, dynamic>{});
    expect(notifTitle(l, n, 'it'), l.notificationsTitle);
    expect(notifBody(l, n, 'it'), isEmpty);
  });

  test('summary + channel strings exist for the background task', () {
    expect(l.notifSummaryTitle(4), contains('4'));
    expect(l.notifSummaryBody, isNotEmpty);
    expect(l.notifChannelName, isNotEmpty);
  });
}
