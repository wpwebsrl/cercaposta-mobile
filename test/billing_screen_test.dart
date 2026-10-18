import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/billing_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/billing/billing_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBillingApi extends BillingApi {
  _FakeBillingApi(this.value) : super(Dio());

  final BillingOverview value;

  @override
  Future<BillingOverview> overview({String? language}) async => value;

  @override
  Future<List<PlanChangeSummary>> changes({String? language}) async =>
      const <PlanChangeSummary>[];
}

BillingOverview _overview({
  required String provider,
  required int priceCents,
  required DateTime? periodEnd,
}) => BillingOverview(
  hasSubscription: true,
  planNameIt: provider == 'free' ? 'Gratuito' : 'Base',
  planNameEn: provider == 'free' ? 'Free' : 'Base',
  status: 'active',
  provider: provider,
  interval: 'monthly',
  currency: 'EUR',
  priceCents: priceCents,
  periodEnd: periodEnd,
  graceUntil: null,
);

Future<void> _mount(
  WidgetTester tester,
  BillingOverview overview, {
  Locale locale = const Locale('it'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        billingApiProvider.overrideWithValue(_FakeBillingApi(overview)),
      ],
      child: MaterialApp(
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BillingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Spanish long plan text fits a narrow screen at 200 percent text scale',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const name =
          'Plan profesional de colaboración y almacenamiento compartido con el equipo';
      await _mount(
        tester,
        const BillingOverview(
          hasSubscription: true,
          planNameIt: 'Originale',
          planNameEn: 'Original',
          localizedPlanName: name,
          status: 'active',
          provider: 'stripe',
          interval: 'monthly',
          currency: 'EUR',
          priceCents: 12345,
          periodEnd: null,
          graceUntil: null,
        ),
        locale: const Locale('es'),
        textScale: 2,
      );
      expect(find.text(name), findsOneWidget);
      expect(find.text('Original'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'free plan shows unlimited validity and no recurring zero price',
    (tester) async {
      await _mount(
        tester,
        _overview(provider: 'free', priceCents: 0, periodEnd: null),
      );

      expect(find.text('Validità del piano'), findsOneWidget);
      expect(find.text('Nessuna scadenza'), findsOneWidget);
      expect(find.text('Prezzo ricorrente'), findsNothing);
      expect(find.textContaining('0,00'), findsNothing);
    },
  );

  testWidgets('paid plan shows cadence, renewal date and renewal amount', (
    tester,
  ) async {
    await _mount(
      tester,
      _overview(
        provider: 'stripe',
        priceCents: 2900,
        periodEnd: DateTime.utc(2026, 10, 27),
      ),
    );

    expect(find.text('Periodicità'), findsOneWidget);
    expect(find.text('Mensile'), findsOneWidget);
    expect(find.text('Prossimo rinnovo'), findsOneWidget);
    expect(find.text('Importo del prossimo rinnovo'), findsOneWidget);
    expect(find.textContaining('29,00'), findsOneWidget);
  });
}
