import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cercaposta/core/api/api_exception.dart';
import 'package:cercaposta/core/api/api_providers.dart';
import 'package:cercaposta/core/api/services/chat_api.dart';
import 'package:cercaposta/core/auth/auth_controller.dart';
import 'package:cercaposta/core/auth/device_grant.dart';
import 'fake_biometric_vault.dart';
import 'package:cercaposta/core/auth/secure_store.dart';
import 'package:cercaposta/core/auth/session_coordinator.dart';
import 'package:cercaposta/core/config/app_info.dart';
import 'package:cercaposta/core/providers.dart';
import 'package:cercaposta/features/chat/chat_controller.dart';
import 'package:cercaposta/shared/models/chat.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Transport implements HttpClientAdapter {
  Transport(this.handle);
  final Future<ResponseBody> Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handle(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Map<String, dynamic> pair(String id) => {
  'access_token': 'access-$id',
  'refresh_token': 'refresh-$id',
  'user': {'id': id, 'username': id},
  'enc_status': 'active',
  'dek_available': true,
};

Future<ProviderContainer> containerFor({
  Future<ResponseBody> Function(RequestOptions)? handle,
  ChatApi? chat,
  FakeBiometricVault? vault,
}) async {
  SharedPreferences.setMockInitialValues({
    'active_server': 'https://a.example',
  });
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  sqfliteFfiInit();
  final database = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: SessionCoordinator.createSchema,
    ),
  );
  addTearDown(database.close);
  final store = SecureStore(biometricVault: vault ?? FakeBiometricVault());
  final dio = Dio(BaseOptions(baseUrl: 'https://a.example/api/v1'));
  dio.httpClientAdapter = Transport(
    handle ??
        (request) async {
          if (request.path == '/auth/login') {
            return json(pair((request.data as Map)['username'] as String));
          }
          return json({});
        },
  );
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appInfoProvider.overrideWithValue(
        const AppInfo(client: 'android', version: '1.5.0', deviceName: 'test'),
      ),
      authDioProvider.overrideWithValue(dio),
      secureStoreProvider.overrideWithValue(store),
      sessionCoordinatorProvider.overrideWithValue(
        SessionCoordinator(store, openDatabase: () async => database),
      ),
      if (chat != null) chatApiProvider.overrideWithValue(chat),
    ],
  );
  addTearDown(c.dispose);
  addTearDown(dio.close);
  return c;
}

Matcher get sessionChanged => throwsA(
  predicate<Object>(
    (error) => ApiException.from(error).code == 'auth.session_changed',
  ),
);

class DelayedChat extends ChatApi {
  DelayedChat() : super(Dio());
  final output = StreamController<ChatStreamEvent>();
  final loads = <String, Completer<List<ChatMessage>>>{};
  final requests = <List<Map<String, String>>>[];
  CancelToken? cancel;
  @override
  Stream<ChatStreamEvent> stream({
    required String message,
    required List<Map<String, String>> history,
    String? conversationId,
    CancelToken? cancelToken,
  }) {
    requests.add(history);
    cancel = cancelToken;
    return output.stream;
  }

  @override
  Future<List<ChatMessage>> conversationMessages(String id) =>
      (loads[id] = Completer<List<ChatMessage>>()).future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final status in [200, 401, 403]) {
    test('late refresh $status cannot replace or log out B', () async {
      final entered = Completer<void>(), release = Completer<void>();
      final c = await containerFor(
        handle: (request) async {
          if (request.path == '/auth/refresh') {
            entered.complete();
            await release.future;
            return json(pair('late-A'), status);
          }
          return json(pair((request.data as Map)['username'] as String));
        },
      );
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      final pending = auth.performRefresh();
      final checked = expectLater(pending, sessionChanged);
      await entered.future;
      await auth.login('B', 'password-B');
      final identity = c.read(sessionKeyProvider);
      release.complete();
      await checked;
      expect(c.read(authProvider).user?.id, 'B');
      expect(c.read(sessionKeyProvider), identity);
      expect(
        (await c.read(sessionCoordinatorProvider).read('https://a.example'))
            ?.refreshToken,
        'refresh-B',
      );
    });
  }

  test('logout while login is pending cannot resurrect tokens', () async {
    final entered = Completer<void>(), release = Completer<void>();
    final c = await containerFor(
      handle: (_) async {
        entered.complete();
        await release.future;
        return json(pair('A'));
      },
    );
    final auth = c.read(authProvider.notifier);
    final pending = auth.login('A', 'password-A');
    final checked = expectLater(pending, sessionChanged);
    await entered.future;
    await auth.forceLogout();
    release.complete();
    await checked;
    expect(c.read(authProvider).user, isNull);
    expect(
      await c.read(sessionCoordinatorProvider).read('https://a.example'),
      isNull,
    );
  });

  test('new login for the same user changes session identity', () async {
    final c = await containerFor();
    final auth = c.read(authProvider.notifier);
    await auth.login('A', 'password-A');
    final first = c.read(sessionKeyProvider);
    await auth.login('A', 'password-A');
    expect(c.read(sessionKeyProvider), isNot(first));
  });

  test(
    'biometric selector is bound to verified user and server without secret reads',
    () async {
      final vault = FakeBiometricVault();
      final c = await containerFor(vault: vault);
      final store = c.read(secureStoreProvider);
      await store.writeGrant(
        DeviceGrant(
          const DeviceGrantInfo(
            server: 'https://a.example',
            username: 'A',
            userId: 'A',
            deviceId: 'device-A',
          ),
          's' * 43,
        ),
        reason: 'Test',
        cancel: 'Cancel',
      );
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      expect(await auth.hasBiometricForCurrentUser(), isTrue);
      await auth.login('B', 'password-B');
      expect(await auth.hasBiometricForCurrentUser(), isFalse);
      expect((await store.readGrantInfo())?.userId, 'A');
      await c.read(activeServerProvider.notifier).select('https://b.example');
      expect(await auth.savedGrantInfo(), isNull);
      expect(vault.reads, 0);
    },
  );

  test(
    'legacy passwords are deleted without altering the live refresh session',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'unlock_password': 'old-secret',
        'credentials_v2': '{"password":"old-secret"}',
        'cred_password': 'old-secret',
        'cred_username': 'A',
        'cred_server': 'https://a.example',
        'session_record_v3': '{"refresh_token":"live-refresh"}',
        'refresh_token': 'legacy-refresh',
      });
      final store = SecureStore();
      expect(await store.readGrantInfo(), isNull);
      final values = await const FlutterSecureStorage().readAll();
      expect(values.keys.toSet(), {'session_record_v3', 'refresh_token'});
      expect((await store.readSessionData())?['refresh_token'], 'live-refresh');
    },
  );

  for (final mode in [
    ResponseType.json,
    ResponseType.bytes,
    ResponseType.stream,
  ]) {
    for (final code in [
      'plans.subscription_required',
      'enc.migration_in_progress',
    ]) {
      test('423 $code keeps meaning for $mode', () async {
        final c = await containerFor();
        final auth = c.read(authProvider.notifier);
        await auth.login('A', 'password-A');
        final dio = c.read(apiDioProvider);
        var calls = 0;
        dio.httpClientAdapter = Transport((_) async {
          calls++;
          return json({
            'error': {
              'code': code,
              'params': {'test': 42},
            },
          }, 423);
        });
        try {
          await dio.get<dynamic>(
            '/private',
            options: Options(responseType: mode),
          );
          fail('expected the 423');
        } on DioException catch (error) {
          final parsed = await ApiException.fromAsync(error);
          expect(parsed.code, code);
          expect(parsed.params['test'], 42);
        }
        expect(calls, 1);
        expect(c.read(authProvider).status, AuthStatus.loggedIn);
      });
    }
  }

  test(
    'old successful API response cannot deliver private data after new login',
    () async {
      final c = await containerFor();
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      final entered = Completer<void>(), release = Completer<void>();
      final dio = c.read(apiDioProvider);
      dio.httpClientAdapter = Transport((_) async {
        entered.complete();
        await release.future;
        return json({'private': 'A'});
      });
      final checked = expectLater(dio.get<dynamic>('/private'), sessionChanged);
      await entered.future;
      await auth.login('B', 'password-B');
      release.complete();
      await checked;
    },
  );

  test(
    'chat account change cancels the stream and clears retry history',
    () async {
      final chat = DelayedChat();
      final c = await containerFor(chat: chat);
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      final controller = c.read(chatProvider.notifier);
      final pending = controller.send('private A');
      chat.output.add(
        const ChatStreamEvent(type: ChatEventType.token, text: 'old'),
      );
      await Future<void>.delayed(Duration.zero);
      await auth.login('B', 'password-B');
      expect(c.read(chatProvider).messages, isEmpty);
      expect(chat.cancel?.isCancelled, isTrue);
      chat.output.add(
        const ChatStreamEvent(type: ChatEventType.token, text: 'late A'),
      );
      await chat.output.close();
      await pending;
      await controller.retryLast();
      expect(c.read(chatProvider).messages, isEmpty);
      expect(chat.requests, hasLength(1));
    },
  );

  test('last selected conversation wins over older late load', () async {
    final chat = DelayedChat();
    final c = await containerFor(chat: chat);
    await c.read(authProvider.notifier).login('A', 'password-A');
    final controller = c.read(chatProvider.notifier);
    final old = controller.loadConversation('old');
    final latest = controller.loadConversation('latest');
    chat.loads['latest']!.complete([
      ChatMessage(role: 'user', content: 'latest'),
    ]);
    await latest;
    chat.loads['old']!.complete([ChatMessage(role: 'user', content: 'old')]);
    await old;
    expect(c.read(chatProvider).messages.single.content, 'latest');
    chat.output.stream.listen((_) {});
    await chat.output.close();
  });
}
