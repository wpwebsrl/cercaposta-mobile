import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/followup_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/followups/followups_screen.dart';
import 'package:cercaposta/shared/models/followup.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A canned FollowupApi: only list()/status() matter for a render test.
class _FakeFollowupApi extends FollowupApi {
  _FakeFollowupApi(this._list, this._status) : super(Dio());
  final FollowupList _list;
  final FollowupStatus _status;

  @override
  Future<FollowupList> list({int limit = 200}) async => _list;

  @override
  Future<FollowupStatus> status() async => _status;
}

Future<void> _pump(
  WidgetTester tester,
  FollowupList list,
  FollowupStatus status,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        followupApiProvider.overrideWithValue(_FakeFollowupApi(list, status)),
      ],
      child: const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FollowupsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders a their_turn row with its counterpart and summary', (
    tester,
  ) async {
    final list = FollowupList(
      total: 1,
      items: <FollowupItem>[
        FollowupItem.fromJson(<String, dynamic>{
          'id': 'f1',
          'direction': 'their_turn',
          'state': 'expired',
          'counterpart_name': 'Mario Rossi',
          'counterpart_address': 'mario@acme.it',
          'summary': 'costi del computer',
          'due_at': '2026-07-08T00:00:00Z',
          'message_id': 'm1',
        }),
      ],
    );
    await _pump(
      tester,
      list,
      const FollowupStatus(configured: true, enabled: true, paused: null),
    );

    expect(find.text('Mario Rossi'), findsOneWidget);
    expect(find.text('costi del computer'), findsOneWidget);
    // The tab label carries the active count.
    expect(find.textContaining('Aspetto risposta'), findsOneWidget);
  });

  testWidgets('shows the disabled empty-state when the feature is off', (
    tester,
  ) async {
    await _pump(
      tester,
      const FollowupList(total: 0, items: <FollowupItem>[]),
      const FollowupStatus(configured: false, enabled: false, paused: null),
    );
    expect(find.text('Funzione non attiva'), findsOneWidget);
  });
}
