import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/message_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/email/email_screen.dart';
import 'package:cercaposta/shared/models/message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the real reader over the real parser, fed the shape `GET /messages/{id}`
/// really returns. The unit tests on the model would pass even with a hand-built
/// MessageDetail; this one only passes if the JSON survives all the way onto the
/// screen — which is exactly the leg that was broken (recipients parsed as strings,
/// silently dropped, rows never drawn).
///
/// The fixture deliberately has no body: `hasBody == false` keeps the WebView, which
/// cannot render under `flutter test`, out of the tree while leaving the header and
/// its details panel — the part under test — untouched.
Map<String, dynamic> _json({
  required List<Map<String, String>> to,
  List<Map<String, String>> cc = const [],
}) => <String, dynamic>{
  'id': 'm1',
  'subject': 'Preventivo',
  'from_name': 'Mario Rossi',
  'from_address': 'mario@example.it',
  'recipients': <String, dynamic>{'to': to, 'cc': cc, 'bcc': <dynamic>[]},
  'date_sent': '2026-07-14T10:30:00+00:00',
  'body_text': '',
  'attachments': <dynamic>[],
  'folders': <dynamic>[],
  'tags': <dynamic>[],
};

class _FakeMessageApi extends MessageApi {
  _FakeMessageApi(this._detail) : super(Dio());
  final MessageDetail _detail;

  @override
  Future<MessageDetail> get(String id, {bool allowRemote = false}) async =>
      _detail;

  @override
  Future<List<ThreadEntry>> thread(String id) async => const <ThreadEntry>[];
}

Future<void> _pump(WidgetTester tester, Map<String, dynamic> json) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        messageApiProvider.overrideWithValue(
          _FakeMessageApi(MessageDetail.fromJson(json)),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EmailScreen(messageId: 'm1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('recipients reach the screen without opening anything', (
    tester,
  ) async {
    await _pump(
      tester,
      _json(
        to: [
          {'name': 'Anna Bianchi', 'address': 'anna@example.it'},
        ],
      ),
    );

    // findRichText: the details rows are RichText (label in bold + value), which the
    // default text finder does not look inside.
    expect(
      find.textContaining('Anna Bianchi <anna@example.it>', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('every address is shown, not just the first', (tester) async {
    await _pump(
      tester,
      _json(
        to: [
          {'name': 'Anna', 'address': 'anna@example.it'},
          {'name': 'Luca', 'address': 'luca@example.it'},
          {'name': '', 'address': 'terzo@example.it'},
        ],
        cc: [
          {'name': 'Ufficio', 'address': 'ufficio@example.it'},
        ],
      ),
    );

    // All three To addresses and the Cc, on screen together.
    for (final needle in <String>[
      'Anna <anna@example.it>',
      'Luca <luca@example.it>',
      'terzo@example.it',
      'Ufficio <ufficio@example.it>',
    ]) {
      expect(
        find.textContaining(needle, findRichText: true),
        findsOneWidget,
        reason: '$needle should be rendered in full',
      );
    }
  });

  testWidgets('a name-less recipient falls back to the bare address', (
    tester,
  ) async {
    await _pump(
      tester,
      _json(
        to: [
          {'name': '', 'address': 'solo@example.it'},
        ],
      ),
    );
    expect(
      find.textContaining('solo@example.it', findRichText: true),
      findsWidgets,
    );
    // No stray "<>" from a blank name.
    expect(find.textContaining('<>', findRichText: true), findsNothing);
  });
}
