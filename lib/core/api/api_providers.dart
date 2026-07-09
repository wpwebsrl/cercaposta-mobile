import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../providers.dart';
import 'dio_factory.dart';
import 'services/chat_api.dart';
import 'services/message_api.dart';
import 'services/meta_api.dart';
import 'services/notification_api.dart';
import 'services/search_api.dart';
import 'services/session_api.dart';
import 'services/taxonomy_api.dart';

/// Authenticated Dio: injects the Bearer, does a single serialized refresh on 401
/// and retries once; on 423 (DEK vault lapsed) it first tries a silent re-unlock
/// (RAM-held session password) and retries — only if that fails it routes to the
/// lock screen.
final apiDioProvider = Provider<Dio>((ref) {
  final dio = buildDio(ref.watch(apiBaseProvider));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        final status = e.response?.statusCode;
        if (status == 426) {
          // App below the supported floor: route to the mandatory-update screen.
          ref.read(authProvider.notifier).handleUpdateRequired(e);
          handler.next(e);
          return;
        }
        if (status == 423) {
          final alreadyUnlocked = e.requestOptions.extra['retried423'] == true;
          if (!alreadyUnlocked &&
              await ref.read(authProvider.notifier).tryAutoUnlock()) {
            final req = e.requestOptions;
            req.extra['retried423'] = true;
            try {
              final clone = await dio.fetch<dynamic>(req);
              handler.resolve(clone);
              return;
            } on DioException catch (err) {
              handler.next(err);
              return;
            }
          }
          ref.read(authProvider.notifier).markLocked();
          handler.next(e);
          return;
        }
        final alreadyRetried = e.requestOptions.extra['retried'] == true;
        if (status == 401 && !alreadyRetried) {
          String? token;
          try {
            token = await ref.read(authProvider.notifier).performRefresh();
          } on Object {
            token =
                null; // network error during refresh: fail THIS call, keep the session
          }
          if (token != null) {
            final req = e.requestOptions;
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer $token';
            try {
              final clone = await dio.fetch<dynamic>(req);
              handler.resolve(clone);
              return;
            } on DioException catch (err) {
              handler.next(err);
              return;
            }
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
});

final metaApiProvider = Provider<MetaApi>((ref) => MetaApi());
final searchApiProvider = Provider<SearchApi>(
  (ref) => SearchApi(ref.watch(apiDioProvider)),
);
final messageApiProvider = Provider<MessageApi>(
  (ref) => MessageApi(ref.watch(apiDioProvider)),
);
final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(apiDioProvider)),
);
final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(apiDioProvider)),
);
final sessionApiProvider = Provider<SessionApi>(
  (ref) => SessionApi(ref.watch(apiDioProvider)),
);
final taxonomyApiProvider = Provider<TaxonomyApi>(
  (ref) => TaxonomyApi(ref.watch(apiDioProvider)),
);
