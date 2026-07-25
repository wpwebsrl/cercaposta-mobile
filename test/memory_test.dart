import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/memory_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/chat/memory_announcement.dart';
import 'package:cercaposta/features/settings/memory_screen.dart';
import 'package:cercaposta/shared/models/chat.dart';
import 'package:cercaposta/shared/models/memory.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chat memory on mobile: stream normalization, the management screen and the inline
/// announcement (docs/memoria-utente.md §7).
///
/// The EFFECT of a memory is server-side, so what is worth testing is what the client owns:
/// that a `data-memory` frame stops being skipped, that the four states stay visible, and that
/// the two announcement actions stay two.

/// A canned MemoryApi. `calls` records what the widget asked for — the point of the
/// announcement test is WHICH call each action makes, not that something happened.
class _FakeMemoryApi extends MemoryApi {
  _FakeMemoryApi({
    List<Memory> memories = const <Memory>[],
    List<AliasSuggestion> suggestions = const <AliasSuggestion>[],
    MemoryPolicy policy = const MemoryPolicy(),
  }) : _memories = memories,
       _suggestions = suggestions,
       _policy = policy,
       super(Dio());

  final List<Memory> _memories;
  final List<AliasSuggestion> _suggestions;
  MemoryPolicy _policy;
  final List<String> calls = <String>[];

  @override
  Future<List<Memory>> list() async => _memories;

  @override
  Future<MemoryPolicy> policy() async => _policy;

  @override
  Future<MemoryPolicy> setPolicy(MemoryPolicy p) async {
    calls.add('policy learn=${p.learn} enabled=${p.enabled}');
    return _policy = p;
  }

  @override
  Future<void> update(String id, {bool? enabled, bool? rejected}) async {
    calls.add('patch $id enabled=$enabled rejected=$rejected');
  }

  @override
  Future<void> delete(String id) async => calls.add('delete $id');

  @override
  Future<List<AliasSuggestion>> suggestions() async => _suggestions;

  @override
  Future<void> acceptSuggestion(AliasSuggestion s) async =>
      calls.add('accept ${s.key}');
}

Memory _memory({
  String id = 'm1',
  String kind = 'alias',
  String trigger = 'search',
  String key = 'sara',
  String value = 'sara@acme.it',
  String status = 'active',
  bool stale = false,
  int uses = 0,
}) => Memory(
  id: id,
  kind: kind,
  trigger: trigger,
  key: key,
  value: value,
  source: 'correction',
  confidence: 0.8,
  status: status,
  stale: stale,
  uses: uses,
  lastUsedAt: null,
);

Future<void> _pump(WidgetTester tester, Widget home, _FakeMemoryApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[memoryApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('stream', () {
    test('a data-memory frame is normalized, not skipped', () {
      // Before this feature the app returned null for anything unknown — which is why no
      // version floor is needed, and also why forgetting this would fail silently.
      final ev = ChatStreamEvent.tryParse(<String, dynamic>{
        'type': 'data-memory',
        'data': <String, dynamic>{
          'id': 'm1',
          'kind': 'alias',
          'trigger': 'search',
          'key': 'giacomini',
          'value': 's.giacomini@acme.it',
          'source': 'correction',
          'status': 'candidate',
        },
      });
      expect(ev?.type, ChatEventType.memory);
      expect(ev?.learned?.value, 's.giacomini@acme.it');
      expect(ev?.learned?.candidate, isTrue);
    });

    test('the final frame carries the applied memories', () {
      final ev = ChatStreamEvent.tryParse(<String, dynamic>{
        'type': 'message-metadata',
        'messageMetadata': <String, dynamic>{
          'final_answer': '…',
          'applied_memories': <dynamic>[
            <String, dynamic>{'kind': 'alias', 'key': 'sara', 'value': 'sara@acme.it'},
          ],
        },
      });
      expect(ev?.type, ChatEventType.done);
      expect(ev?.applied.single.label, 'sara → sara@acme.it');
    });

    test('unknown frames are still skipped', () {
      expect(
        ChatStreamEvent.tryParse(<String, dynamic>{'type': 'data-something-new'}),
        isNull,
      );
    });
  });

  test('a server that answers with nothing does not switch learning off', () {
    expect(MemoryPolicy.fromJson(<String, dynamic>{}).learn, isTrue);
    expect(
      MemoryPolicy.fromJson(<String, dynamic>{
        'enabled': false,
        'learn': true,
        'max_items': 50,
      }).toJson(),
      <String, dynamic>{'enabled': false, 'learn': true, 'max_items': 50},
    );
  });

  testWidgets('the screen shows all four states, grouped by kind', (tester) async {
    final api = _FakeMemoryApi(
      memories: <Memory>[
        _memory(),
        _memory(id: 'm2', kind: 'fact', trigger: 'always', key: 'Levosil',
            value: 'è un cliente', status: 'trial'),
        _memory(id: 'm3', kind: 'render', trigger: 'listing', key: 'columns',
            value: 'sender, subject, date', status: 'rejected'),
        _memory(id: 'm4', kind: 'param', trigger: 'listing', key: 'list_page_size',
            value: '20', status: 'disabled'),
      ],
    );
    await _pump(tester, const MemoryScreen(), api);
    // The intro and the two switches take the first screenful; the list is below.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('sara → sara@acme.it'), findsOneWidget);
    expect(find.text('Levosil → è un cliente'), findsOneWidget);
    // «In prova» and «Rifiutato» must be visible: without them the user cannot tell why
    // something they once saw never came back.
    expect(find.text('In prova'), findsWidgets);
    expect(find.text('Rifiutato'), findsOneWidget);
    expect(find.text('In pausa'), findsWidgets);
    expect(find.text('Come chiami le persone'), findsOneWidget);
  });

  testWidgets('a filter narrows the list and says so when it is empty', (tester) async {
    final api = _FakeMemoryApi(memories: <Memory>[_memory()]);
    await _pump(tester, const MemoryScreen(), api);

    await tester.tap(find.widgetWithText(FilterChip, 'Rifiutati'));
    await tester.pumpAndSettle();
    expect(find.text('sara → sara@acme.it'), findsNothing);
    expect(find.text('Nessun ricordo in questo stato.'), findsOneWidget);
  });

  testWidgets('the learn switch writes the policy, not the other one', (tester) async {
    final api = _FakeMemoryApi();
    await _pump(tester, const MemoryScreen(), api);

    await tester.tap(find.text('Impara dalle mie conversazioni'));
    await tester.pumpAndSettle();
    expect(api.calls, <String>['policy learn=false enabled=true']);
  });

  testWidgets('pause and refusal stay two different calls', (tester) async {
    final api = _FakeMemoryApi(memories: <Memory>[_memory()]);
    await _pump(tester, const MemoryScreen(), api);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metti in pausa').last);
    await tester.pumpAndSettle();
    expect(api.calls.single, 'patch m1 enabled=false rejected=null');

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Non ricordare più').last);
    await tester.pumpAndSettle();
    expect(api.calls.last, 'patch m1 enabled=null rejected=true');
  });

  testWidgets('«annulla» deletes, «non ricordare più» refuses', (tester) async {
    // One button for both would give back the proposal that keeps coming back.
    final api = _FakeMemoryApi();
    await _pump(
      tester,
      const Scaffold(
        body: MemoryAnnouncement(
          memory: LearnedMemory(
            id: 'm9',
            kind: 'alias',
            key: 'sara',
            value: 'sara@acme.it',
            status: 'learned',
          ),
        ),
      ),
      api,
    );
    expect(find.textContaining('sara@acme.it'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(api.calls, <String>['delete m9']);
    expect(find.text("Annullato: non l'ho tenuto."), findsOneWidget);
    // The actions are gone once the choice is made — the outcome stays in the transcript.
    expect(find.text('Non ricordare più'), findsNothing);
  });

  testWidgets('a candidate says it is not being used yet', (tester) async {
    final api = _FakeMemoryApi();
    await _pump(
      tester,
      const Scaffold(
        body: MemoryAnnouncement(
          memory: LearnedMemory(
            id: 'm8',
            kind: 'fact',
            key: 'Levosil',
            value: 'è un cliente',
            status: 'candidate',
          ),
        ),
      ),
      api,
    );
    expect(find.textContaining('in prova'), findsOneWidget);

    await tester.tap(find.text('Non ricordare più'));
    await tester.pumpAndSettle();
    expect(api.calls, <String>['patch m8 enabled=null rejected=true']);
    expect(find.text('Va bene, non te lo riproporrò.'), findsOneWidget);
  });

  testWidgets('an accepted suggestion is written and disappears', (tester) async {
    final api = _FakeMemoryApi(
      suggestions: <AliasSuggestion>[
        const AliasSuggestion(
          key: 'falcone',
          value: 'alessandro.falcone@wpweb.com',
          name: 'Alessandro Falcone',
          count: 1603,
        ),
      ],
    );
    await _pump(tester, const MemoryScreen(), api);

    expect(find.text('falcone → alessandro.falcone@wpweb.com'), findsOneWidget);
    await tester.tap(find.text('Accetta'));
    await tester.pumpAndSettle();
    expect(api.calls, <String>['accept falcone']);
    expect(find.text('falcone → alessandro.falcone@wpweb.com'), findsNothing);
  });
}
