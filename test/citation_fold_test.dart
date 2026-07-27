import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/chat/citation_block.dart';
import 'package:cercaposta/features/chat/citation_fold.dart';
import 'package:cercaposta/shared/models/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'elenco delle citazioni che si piega, variante del telefono (docs/mobile-apps.md).
///
/// Regola comune alle tre superfici: il turno che si sta leggendo resta aperto — per un turno
/// d'elenco la lista È la risposta — e i precedenti si chiudono in una riga. In più, qui,
/// l'elenco aperto si ferma a dieci: su uno schermo di telefono trenta righe sono quattro
/// schermate, cioè un muro, non una risposta.

List<Citation> _cits(int n, {String? name}) => List<Citation>.generate(
  n,
  (i) => Citation(
    n: i + 1,
    id: 'E$i',
    subject: 'Oggetto $i',
    fromName: name ?? (i < 2 ? 'Mittente $i' : 'Altro'),
    fromAddress: 'm$i@x.it',
    date: null,
    snippet: '…',
    folder: 'INBOX',
  ),
);

Citation _unused(Citation c) => Citation(
  n: c.n,
  id: c.id,
  subject: c.subject,
  fromName: c.fromName,
  fromAddress: c.fromAddress,
  date: c.date,
  snippet: c.snippet,
  folder: c.folder,
  used: false,
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('lette e non usate', _unusedRows);

  group('regola del ripiegamento', () {
    test('il turno che si legge non si piega mai da solo', () {
      expect(citationsFolded(30, true), isFalse);
    });

    test('un turno precedente si piega, se è abbastanza lungo', () {
      expect(citationsFolded(30, false), isTrue);
      expect(citationsFolded(kCitationsFoldMin, false), isTrue);
      expect(citationsFolded(kCitationsFoldMin - 1, false), isFalse);
    });

    test('la scelta dell\'utente vince, in entrambe le direzioni', () {
      expect(citationsFolded(30, false, manual: false), isFalse);
      expect(citationsFolded(30, true, manual: true), isTrue);
    });

    test('sul telefono anche l\'elenco aperto si ferma a dieci', () {
      expect(citationsVisible(30, showAll: false), kCitationsMaxVisible);
      expect(citationsVisible(30, showAll: true), 30);
      expect(citationsVisible(4, showAll: false), 4);
    });

    test('il riepilogo nomina prima chi ha davvero contribuito', () {
      // Mostrare solo le citate lasciava buchi nella numerazione, e sui buchi il verdetto
      // dell'utente è stato «confonde»: ora le lette e non usate ci sono, smorzate — ma la riga
      // chiusa deve riassumere la RISPOSTA, non tutto quello che il turno ha aperto.
      final cits = _cits(6);
      cits[0] = _unused(cits[0]);
      expect(citationNames(cits, limit: 1), <String>['Mittente 1']);
    });

    test('il riepilogo non ripete due volte lo stesso mittente', () {
      expect(citationNames(_cits(5, name: 'ACME')), <String>['ACME']);
    });
  });

  testWidgets('turno corrente: dieci righe e l\'invito a vedere le altre', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CitationBlock(citations: _cits(30), isLastAssistant: true)),
    );
    expect(find.byType(ActionChip), findsNWidgets(kCitationsMaxVisible));
    // Un elenco tagliato in silenzio si legge come un elenco completo: dillo, e offrile.
    await tester.tap(find.text('Mostra tutte le altre 20'));
    await tester.pump();
    expect(find.byType(ActionChip), findsNWidgets(30));
  });

  testWidgets('turno precedente: una riga sola, con conteggio e mittenti', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CitationBlock(citations: _cits(30), isLastAssistant: false)),
    );
    expect(find.byType(ActionChip), findsNothing);
    expect(find.textContaining('30 email'), findsOneWidget);
    expect(find.textContaining('Mittente 0'), findsOneWidget);
    expect(find.textContaining('e altri 28'), findsOneWidget);
  });

  testWidgets('un tocco riapre il turno precedente', (tester) async {
    await tester.pumpWidget(
      _wrap(CitationBlock(citations: _cits(12), isLastAssistant: false)),
    );
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    // Riaperto: le prime dieci, più l'invito per le due che restano.
    expect(find.byType(ActionChip), findsNWidgets(kCitationsMaxVisible));
    expect(find.text('Mostra tutte le altre 2'), findsOneWidget);
  });

  testWidgets('un elenco corto non offre nemmeno la levetta', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CitationBlock(
          citations: _cits(kCitationsFoldMin - 1),
          isLastAssistant: false,
        ),
      ),
    );
    expect(find.byType(ActionChip), findsNWidgets(kCitationsFoldMin - 1));
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });
}

/// Le email lette e non usate restano nell'elenco, smorzate: toglierle faceva «saltare» dei
/// numeri che nella risposta invece si leggono, e sui buchi il verdetto dell'utente è stato
/// «confonde». La legenda compare solo quando c'è almeno una scheda grigia — una scheda smorzata
/// senza spiegazione è un enigma.
void _unusedRows() {
  testWidgets('le lette e non usate restano, con la legenda', (tester) async {
    final cits = _cits(6);
    cits[2] = _unused(cits[2]);
    await tester.pumpWidget(
      _wrap(CitationBlock(citations: cits, isLastAssistant: true)),
    );
    expect(find.byType(ActionChip), findsNWidgets(6)); // nessun numero saltato
    expect(find.textContaining('In grigio'), findsOneWidget);
  });

  testWidgets('senza lette e non usate non c\'è niente da spiegare', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(CitationBlock(citations: _cits(6), isLastAssistant: true)),
    );
    expect(find.textContaining('In grigio'), findsNothing);
  });
}
