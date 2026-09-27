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
  Future<BillingOverview> overview() async => value;

  @override
  Future<List<PlanChangeSummary>> changes() async =>
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

Future<void> _mount(WidgetTester tester, BillingOverview overview) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        billingApiProvider.overrideWithValue(_FakeBillingApi(overview)),
      ],
      child: const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BillingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
