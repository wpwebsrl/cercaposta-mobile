import 'package:cercaposta/core/config/app_info.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/core/providers.dart';
import 'package:cercaposta/features/login/update_required_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('storeUpdateUris', () {
    test('android points at the store deep link with a web fallback', () {
      const info = AppInfo(
        client: 'android',
        version: '1.0.0',
        deviceName: 'x',
      );
      final uris = info.storeUpdateUris();
      expect(uris, hasLength(2));
      expect(uris.first.toString(), 'market://details?id=it.cercaposta.app');
      expect(
        uris[1].toString(),
        'https://play.google.com/store/apps/details?id=it.cercaposta.app',
      );
    });

    test('ios has no url until STORE_URL_IOS is set at build time', () {
      const info = AppInfo(client: 'ios', version: '1.0.0', deviceName: 'x');
      // STORE_URL_IOS defaults to empty in tests → nothing to open.
      expect(info.storeUpdateUris(), isEmpty);
    });
  });

  testWidgets('UpdateRequiredScreen shows the title and the update button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appInfoProvider.overrideWithValue(
            const AppInfo(client: 'android', version: '1.0.0', deviceName: 'x'),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UpdateRequiredScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Aggiornamento necessario'), findsOneWidget);
    expect(find.text('Aggiorna ora'), findsOneWidget);
    // The version is interpolated into the body.
    expect(find.textContaining('1.0.0'), findsOneWidget);
  });
}
