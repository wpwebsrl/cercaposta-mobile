import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/followup_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/followups/delivery_history.dart';
import 'package:cercaposta/features/followups/send_identity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApi extends FollowupApi {
  FakeApi(this.state) : super(Dio());
  final String state;
  final resolutions = <bool>[];
  @override
  Future<List<Map<String, dynamic>>> deliveries(String id) async => [
    {
      'id': 'trace',
      'state': state,
      'provider': 'smtp',
      'created_at': '2026-09-15T10:00:00Z',
      'can_resolve': state == 'unknown',
    },
  ];
  @override
  Future<void> resolveDelivery(String id, {required bool accepted}) async {
    resolutions.add(accepted);
  }
}

Future<void> mount(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [followupApiProvider.overrideWithValue(api)],
      child: const MaterialApp(
        locale: Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeliveryHistory(expectationId: 'exp'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Esiti degli invii'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'same reviewed payload retries with same UUID; changes use a fresh UUID',
    () {
      final identity = SendIdentity();
      final first = identity.forPayload({'body': 'test'});
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(identity.forPayload({'body': 'test'}), first);
      expect(identity.forPayload({'body': 'changed'}), isNot(first));
    },
  );

  test(
    'request ID reaches API and resolution never calls send-reminder',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response<dynamic>(
                requestOptions: request,
                data: <String, dynamic>{'from_address': 'test@example.invalid'},
                statusCode: 200,
              ),
            );
          },
        ),
      );
      final api = FollowupApi(dio);
      await api.sendReminder(
        'exp',
        subject: 'Test',
        body: 'Test',
        requestId: 'stable',
      );
      expect((requests.single.data as Map)['request_id'], 'stable');
      requests.clear();
      await api.resolveDelivery('trace', accepted: false);
      expect(requests.single.path, '/followups/deliveries/trace/resolve');
      expect(requests.single.data, {
        'accepted': false,
        'provider_checked': true,
      });
    },
  );

  testWidgets('unknown outcome requires explicit check and does not send', (
    tester,
  ) async {
    final api = FakeApi('unknown');
    await mount(tester, api);
    expect(find.textContaining('Esito da verificare'), findsOneWidget);
    expect(api.resolutions, isEmpty);
    final action = find.widgetWithText(TextButton, 'Conferma mancato invio');
    expect(tester.widget<TextButton>(action).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(api.resolutions, [false]);
  });

  testWidgets('active sender cannot be resolved early', (tester) async {
    final api = FakeApi('sending');
    await mount(tester, api);
    expect(find.textContaining('Invio in corso'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(api.resolutions, isEmpty);
  });
}
