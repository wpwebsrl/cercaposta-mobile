import 'package:cercaposta/core/config/app_info.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/core/providers.dart';
import 'package:cercaposta/features/about/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('About shows company, app name, version and credits in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appInfoProvider.overrideWithValue(
            const AppInfo(
              client: 'android',
              version: '1.0.0',
              deviceName: 'test',
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AboutScreen(),
        ),
      ),
    );
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Company (rendered uppercased), app name, version pill, build label.
    expect(find.text('WPWEB S.R.L.'), findsOneWidget);
    expect(
      find.text('Cerca posta'),
      findsOneWidget,
    ); // header title, exact match
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.textContaining('build'), findsOneWidget);
    // Hold phase (before the logo finishes): ONLY the first credit line shows.
    expect(find.textContaining('è un prodotto WpWeb'), findsOneWidget);
    expect(
      find.textContaining('Grazie per aver scelto Cerca posta.'),
      findsNothing,
    );

    await tester.pumpWidget(
      const SizedBox(),
    ); // unmount → dispose timers/ticker
  });
}
