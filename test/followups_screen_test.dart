import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/followup_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/followups/followups_screen.dart';
import 'package:cercaposta/shared/models/followup.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A canned FollowupApi: only list()/status() matter for a render test. The list
/// is offset-aware so pagination («Carica altre») can be exercised.
class _FakeFollowupApi extends FollowupApi {
  _FakeFollowupApi(this._pages, this._status) : super(Dio());
  final FollowupList Function(int offset) _pages;
  final FollowupStatus _status;

  @override
  Future<FollowupList> list({int limit = 200, int offset = 0}) async =>
      _pages(offset);

  @override
  Future<FollowupStatus> status() async => _status;
}

Future<void> _pump(
  WidgetTester tester,
  FollowupList Function(int offset) pages,
  FollowupStatus status,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        followupApiProvider.overrideWithValue(_FakeFollowupApi(pages, status)),
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
      (_) => list,
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
      (_) => const FollowupList(total: 0, items: <FollowupItem>[]),
      const FollowupStatus(configured: false, enabled: false, paused: null),
    );
    expect(find.text('Funzione non attiva'), findsOneWidget);
  });

  testWidgets('tab badges use the server counts, not the loaded rows', (
    tester,
  ) async {
    // One loaded row, 586 actives server-side: the badges must show the server
    // numbers. (Regression: derived counts never moved on «Fatto»/«Ignora» past
    // the 200-row window, and closing a my_turn row could bump the other tab.)
    final list = FollowupList(
      total: 1132,
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
      counts: const FollowupCounts(theirTurn: 301, myTurn: 285),
    );
    await _pump(
      tester,
      (_) => list,
      const FollowupStatus(configured: true, enabled: true, paused: null),
    );
    expect(find.text('301'), findsOneWidget);
    expect(find.text('285'), findsOneWidget);
  });

  testWidgets('a full page offers «Carica altre» and appends the next page', (
    tester,
  ) async {
    FollowupItem item(String id, String name) =>
        FollowupItem.fromJson(<String, dynamic>{
          'id': id,
          'direction': 'their_turn',
          'state': 'open',
          'counterpart_name': name,
          'counterpart_address': '$id@acme.it',
          'summary': 'pratica $id',
          'due_at': '2027-01-15T00:00:00Z',
          'message_id': 'm-$id',
        });
    FollowupList pages(int offset) => offset == 0
        ? FollowupList(
            total: 201,
            items: List<FollowupItem>.generate(
              200,
              (i) => item('p0-$i', 'Contatto $i'),
            ),
            counts: const FollowupCounts(theirTurn: 201, myTurn: 0),
          )
        : FollowupList(
            total: 201,
            items: <FollowupItem>[item('p1-0', 'Zeta Ultima')],
            counts: const FollowupCounts(theirTurn: 201, myTurn: 0),
          );
    await _pump(
      tester,
      pages,
      const FollowupStatus(configured: true, enabled: true, paused: null),
    );

    final button = find.text('Carica altre');
    await tester.scrollUntilVisible(button, 600);
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    // The short second page landed and ended the paging: row visible, button gone.
    await tester.scrollUntilVisible(find.text('Zeta Ultima'), 600);
    expect(find.text('Zeta Ultima'), findsOneWidget);
    expect(find.text('Carica altre'), findsNothing);
  });
}
