import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/health_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/settings/diagnostics_screen.dart';
import 'package:cercaposta/shared/models/health.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Diagnostica» sul mobile: lo stato dell'archivio, le frazioni e le cause con l'azione.
///
/// Ogni numero lo calcola il server; quello che il client possiede — e quindi l'unica cosa che
/// vale la pena provare qui — è come li SEPARA. La distinzione fra «manca» e «non era un
/// documento» non è cosmetica: sull'archivio vero 109.677 dei 110.200 allegati senza testo sono
/// loghi di firma, e mescolarli produce un allarme a sei cifre che non vuol dire niente.

/// Le proporzioni sono quelle misurate sull'archivio di sviluppo.
const Map<String, dynamic> _payload = <String, dynamic>{
  'status': 'attention',
  'messages': <String, dynamic>{
    'total': 232582,
    'embedded': 232582,
    'pending': 0,
    'errors': 0,
    'configured': true,
  },
  'attachments': <String, dynamic>{
    'total': 127844,
    'extracted': 17644,
    'failed': 139,
    'skipped': 110061,
    'retryable': 49,
    'exhausted': 49,
  },
  'reasons': <dynamic>[
    <String, dynamic>{
      'reason': 'inline_image',
      'count': 109677,
      'extensions': <dynamic>['png'],
      'action': 'none',
      'expected': true,
    },
    <String, dynamic>{
      'reason': 'signature_file',
      'count': 384,
      'extensions': <dynamic>['p7s'],
      'action': 'none',
      'expected': true,
    },
    <String, dynamic>{
      'reason': 'tika_unsupported',
      'count': 50,
      'extensions': <dynamic>['dwg'],
      'action': 'none',
      'expected': false,
    },
    <String, dynamic>{
      'reason': 'tika_http_error',
      'count': 46,
      'extensions': <dynamic>['pdf'],
      'action': 'retry',
      'expected': false,
    },
    <String, dynamic>{
      'reason': 'unmatched_part',
      'count': 40,
      'extensions': <dynamic>['txt'],
      'action': 'none',
      'expected': false,
    },
    <String, dynamic>{
      'reason': 'tika_timeout',
      'count': 3,
      'extensions': <dynamic>['pdf'],
      'action': 'retry',
      'expected': false,
    },
  ],
  'embed_reasons': <dynamic>[],
};

class _FakeHealthApi extends HealthApi {
  _FakeHealthApi(this._payload) : super(Dio());

  final Map<String, dynamic> _payload;
  int retries = 0;

  @override
  Future<ArchiveHealth> archiveHealth() async =>
      ArchiveHealth.fromJson(_payload);

  @override
  Future<int> retryExtract() async {
    retries += 1;
    return 49;
  }
}

Future<void> _pump(WidgetTester tester, _FakeHealthApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[healthApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DiagnosticsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('model', () {
    test('the two lists answer two different questions', () {
      final ArchiveHealth h = ArchiveHealth.fromJson(_payload);
      expect(
        h.missing.fold<int>(0, (int n, HealthReason r) => n + r.count),
        139,
      );
      expect(
        h.notDocuments.fold<int>(0, (int n, HealthReason r) => n + r.count),
        110061,
      );
    });

    test('the denominator is what SHOULD have had text', () {
      // Non «totale meno saltati»: anche un allegato oltre il limite è saltato, e quello manca
      // davvero — sottrarlo lo nasconderebbe dietro un rassicurante 100%.
      expect(ArchiveHealth.fromJson(_payload).readableTotal, 17783);

      final ArchiveHealth overLimit = ArchiveHealth.fromJson(<String, dynamic>{
        'attachments': <String, dynamic>{
          'total': 100,
          'extracted': 90,
          'skipped': 10,
        },
        'reasons': <dynamic>[
          <String, dynamic>{
            'reason': 'over_size_limit',
            'count': 10,
            'action': 'ask_admin',
            'expected': false,
          },
        ],
      });
      expect(overLimit.readableTotal, 100);
      expect(overLimit.notDocuments, isEmpty);
    });

    test('a missing field never invents a number', () {
      final ArchiveHealth empty = ArchiveHealth.fromJson(<String, dynamic>{});
      expect(empty.status, 'ok');
      expect(empty.attachments.total, 0);
      expect(empty.readableTotal, 0);
    });
  });

  testWidgets('the causes are split, with the action next to each', (
    tester,
  ) async {
    await _pump(tester, _FakeHealthApi(_payload));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Perché 139 allegati non hanno testo'), findsOneWidget);
    expect(
      find.text('110.061 allegati non erano documenti da leggere'),
      findsOneWidget,
    );
    expect(
      find.text('Il lettore dei documenti non rispondeva'),
      findsOneWidget,
    );
    // «Riprova» accanto a ciò che può riuscire, «Niente da fare» accanto a ciò che non può:
    // dire «riprova» su un tipo non supportato sarebbe una bugia.
    expect(find.text('Riprova'), findsWidgets);
    expect(find.text('Niente da fare'), findsWidgets);
  });

  testWidgets('the requeue is offered only when it would move something', (
    tester,
  ) async {
    final _FakeHealthApi api = _FakeHealthApi(_payload);
    await _pump(tester, api);
    // 49 su 49 hanno già bruciato i cinque tentativi: il testo lo dice, altrimenti «Riprova 49»
    // sembra un'informazione nuova quando non è cambiato niente.
    expect(find.textContaining('già esaurito'), findsOneWidget);
    await tester.tap(find.text('Riprova 49 allegati'));
    await tester.pumpAndSettle();
    expect(api.retries, 1);
  });

  testWidgets('nothing to requeue, no button that would requeue nothing', (
    tester,
  ) async {
    // Test a sé: rimontare la stessa schermata nello stesso albero riusa lo State (initState
    // non rigira) e mostrerebbe ancora i dati di prima — un falso verde.
    await _pump(
      tester,
      _FakeHealthApi(<String, dynamic>{
        ..._payload,
        'attachments': <String, dynamic>{
          ...(_payload['attachments'] as Map<String, dynamic>),
          'retryable': 0,
          'exhausted': 0,
        },
      }),
    );
    // Il pulsante sparisce; la parola «Riprova» resta accanto alle cause che POTREBBERO
    // riuscire, ed è giusto così: è l'etichetta dell'azione, non un invito a premere.
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(find.textContaining('già esaurito'), findsNothing);
    expect(
      find.text('Il lettore dei documenti non rispondeva'),
      findsOneWidget,
    );
  });

  testWidgets('a cause without a translation shows its code', (tester) async {
    // Per un guasto dell'embedding quel codice È la classe dell'eccezione: meglio del generico
    // «causa non registrata», perché è qualcosa che l'utente può riferire.
    await _pump(
      tester,
      _FakeHealthApi(<String, dynamic>{
        'status': 'attention',
        'messages': <String, dynamic>{
          'total': 10,
          'embedded': 8,
          'errors': 2,
          'configured': true,
        },
        'attachments': <String, dynamic>{'total': 0},
        'reasons': <dynamic>[],
        'embed_reasons': <dynamic>[
          <String, dynamic>{
            'reason': 'HTTPStatusError',
            'count': 2,
            'action': 'none',
          },
        ],
      }),
    );
    expect(find.text('HTTPStatusError'), findsOneWidget);
  });

  testWidgets('the green state says so in words and stays quiet', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeHealthApi(<String, dynamic>{
        'status': 'ok',
        'messages': <String, dynamic>{
          'total': 10,
          'embedded': 10,
          'configured': true,
        },
        'attachments': <String, dynamic>{'total': 4, 'extracted': 4},
        'reasons': <dynamic>[],
        'embed_reasons': <dynamic>[],
      }),
    );
    expect(
      find.text('Tutto a posto: l\'archivio è completo e cercabile.'),
      findsOneWidget,
    );
    expect(find.textContaining('non hanno testo'), findsNothing);
  });
}
