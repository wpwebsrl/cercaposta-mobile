import 'dart:async';
import 'dart:convert';

import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/message_api.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/features/email/email_screen.dart';
import 'package:cercaposta/shared/models/message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _message({bool allowed = false}) => <String, dynamic>{
  'id': 'm1',
  'subject': 'Newsletter',
  'from_address': 'sender@example.test',
  'has_remote_images': true,
  'remote_images_allowed': allowed,
  'remote_images_permission': allowed ? 'message' : 'blocked',
  // No WebView is needed to test consent controls and the server's permission.
  'body_text': '',
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = options.path.endsWith('remote-image-preferences')
        ? <String, dynamic>{
            'always_allow': options.method == 'PATCH'
                ? (options.data as Map<String, dynamic>)['always_allow']
                : false,
            'trusted_senders': <String>['sender@example.test'],
          }
        : _message(allowed: true);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApi extends MessageApi {
  _FakeApi({this.allowed = false, this.fail = false, this.pending})
    : super(Dio());
  bool allowed;
  final bool fail;
  final Completer<void>? pending;
  final scopes = <String>[];
  final reads = <bool?>[];

  @override
  Future<MessageDetail> get(String id, {bool? allowRemote}) async {
    reads.add(allowRemote);
    return MessageDetail.fromJson(_message(allowed: allowed));
  }

  @override
  Future<List<ThreadEntry>> thread(String id) async => <ThreadEntry>[];

  @override
  Future<void> allowRemoteImages(String id, {required String scope}) async {
    scopes.add(scope);
    if (pending != null) await pending!.future;
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/messages/$id/remote-images'),
        type: DioExceptionType.connectionTimeout,
      );
    }
    allowed = true;
  }
}

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _FakeApi api, {
  String language = 'it',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[messageApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EmailScreen(messageId: 'm1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(EmailScreen)))!;
}

void main() {
  test(
    'API defaults to saved permissions and preserves explicit overrides',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final api = MessageApi(dio);
      final detail = await api.get('m1');
      expect(adapter.requests.last.queryParameters, isEmpty);
      expect(detail.remoteImagesAllowed, isTrue);
      expect(detail.remoteImagesPermission, 'message');
      for (final value in <bool>[true, false]) {
        await api.get('m1', allowRemote: value);
        expect(adapter.requests.last.queryParameters, <String, dynamic>{
          'allow_remote': value,
        });
      }
      for (final scope in <String>['message', 'sender']) {
        await api.allowRemoteImages('m1', scope: scope);
        expect(adapter.requests.last.method, 'POST');
        expect(adapter.requests.last.path, '/messages/m1/remote-images');
        expect(adapter.requests.last.data, <String, dynamic>{'scope': scope});
      }
      final prefs = await api.remoteImagePreferences();
      expect(prefs.alwaysAllow, isFalse);
      expect(prefs.trustedSenders, <String>['sender@example.test']);
      for (final value in <bool>[true, false]) {
        expect(
          (await api.setAlwaysAllowRemoteImages(value)).alwaysAllow,
          value,
        );
        expect(adapter.requests.last.method, 'PATCH');
        expect(adapter.requests.last.data, <String, dynamic>{
          'always_allow': value,
        });
      }
    },
  );

  test('older servers default to blocking remote images', () {
    final detail = MessageDetail.fromJson(<String, dynamic>{'id': 'm1'});
    expect(detail.remoteImagesAllowed, isFalse);
    expect(detail.remoteImagesPermission, 'blocked');
  });

  for (final language in <String>['it', 'en']) {
    testWidgets('saved consent hides both offers in $language', (tester) async {
      final api = _FakeApi(allowed: true);
      final l = await _pump(tester, api, language: language);
      expect(find.text(l.emailShowRemoteImages), findsNothing);
      expect(find.text(l.emailAlwaysShowRemoteImagesFromSender), findsNothing);
      expect(api.reads, <bool?>[null]);
      expect(api.scopes, isEmpty);
    });

    for (final scope in <String>['message', 'sender']) {
      testWidgets('reader saves $scope consent then reloads in $language', (
        tester,
      ) async {
        final api = _FakeApi();
        final l = await _pump(tester, api, language: language);
        await tester.tap(
          find.text(
            scope == 'message'
                ? l.emailShowRemoteImages
                : l.emailAlwaysShowRemoteImagesFromSender,
          ),
        );
        await tester.pumpAndSettle();
        expect(api.scopes, <String>[scope]);
        expect(api.reads, <bool?>[null, null]);
        expect(find.text(l.emailShowRemoteImages), findsNothing);
        expect(
          find.text(l.emailAlwaysShowRemoteImagesFromSender),
          findsNothing,
        );
      });
    }
  }

  testWidgets('failed consent keeps the offer and reports an error', (
    tester,
  ) async {
    final api = _FakeApi(fail: true);
    final l = await _pump(tester, api);
    await tester.tap(find.text(l.emailShowRemoteImages));
    await tester.pumpAndSettle();
    expect(find.text(l.emailShowRemoteImages), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(api.reads, <bool?>[null]);
  });

  testWidgets('closing the reader during consent does not reload it', (
    tester,
  ) async {
    final pending = Completer<void>();
    final api = _FakeApi(pending: pending);
    final l = await _pump(tester, api);
    await tester.tap(find.text(l.emailShowRemoteImages));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pumpAndSettle();
    expect(api.reads, <bool?>[null]);
    expect(tester.takeException(), isNull);
  });
}
