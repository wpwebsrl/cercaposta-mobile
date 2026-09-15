import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/capabilities.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';
import 'dio_factory.dart';
import 'api_exception.dart';
import 'services/billing_api.dart';
import 'services/capabilities_api.dart';
import 'services/chat_api.dart';
import 'services/events_api.dart';
import 'services/followup_api.dart';
import 'services/health_api.dart';
import 'services/memory_api.dart';
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
  final base = ref.watch(apiBaseProvider);
  final dio = buildDio(base);
  final auth = ref.read(authProvider.notifier);
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    dio.close(force: true);
  });
  bool current(RequestOptions request) =>
      !disposed &&
      ref.read(apiBaseProvider) == base &&
      auth.isCurrent(request.extra['sessionIdentity'] as String? ?? '');
  DioException changed(RequestOptions request) => DioException(
    requestOptions: request,
    type: DioExceptionType.cancel,
    error: ApiException('auth.session_changed'),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra.putIfAbsent(
          'sessionIdentity',
          () => auth.requestIdentity,
        );
        if (!current(options)) {
          handler.reject(changed(options));
          return;
        }
        final token = ref.read(authProvider).accessToken;
        options.headers.remove('Authorization');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (!current(response.requestOptions)) {
          handler.reject(changed(response.requestOptions));
          return;
        }
        final body = response.data;
        if (body is ResponseBody) {
          body.stream = body.stream.map((chunk) {
            if (!current(response.requestOptions)) {
              throw changed(response.requestOptions);
            }
            return chunk;
          });
        }
        handler.next(response);
      },
      onError: (e, handler) async {
        if (!current(e.requestOptions)) {
          handler.next(changed(e.requestOptions));
          return;
        }
        final status = e.response?.statusCode;
        if (status == 426) {
          // App below the supported floor: route to the mandatory-update screen.
          ref.read(authProvider.notifier).handleUpdateRequired(e);
          handler.next(e);
          return;
        }
        if (status == 423) {
          final parsed = await ApiException.fromAsync(e);
          if (!current(e.requestOptions)) {
            handler.next(changed(e.requestOptions));
            return;
          }
          // A streamed error is consumed once; preserve its envelope for the caller.
          if (e.response?.data is ResponseBody) {
            e.response!.data = <String, dynamic>{
              'error': {'code': parsed.code, 'params': parsed.params},
            };
          }
          if (!parsed.isDekLocked) {
            handler.next(e);
            return;
          }
          final alreadyUnlocked = e.requestOptions.extra['retried423'] == true;
          if (!alreadyUnlocked &&
              await ref.read(authProvider.notifier).tryAutoUnlock()) {
            if (!current(e.requestOptions)) {
              handler.next(changed(e.requestOptions));
              return;
            }
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
          if (current(e.requestOptions)) auth.markLocked();
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
          if (!current(e.requestOptions)) {
            handler.next(changed(e.requestOptions));
            return;
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
final followupApiProvider = Provider<FollowupApi>(
  (ref) => FollowupApi(ref.watch(apiDioProvider)),
);
final eventsApiProvider = Provider<EventsApi>(
  (ref) => EventsApi(ref.watch(apiDioProvider)),
);
final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(apiDioProvider)),
);
final billingApiProvider = Provider<BillingApi>(
  (ref) => BillingApi(ref.watch(apiDioProvider)),
);
final sessionApiProvider = Provider<SessionApi>(
  (ref) => SessionApi(ref.watch(apiDioProvider)),
);
final taxonomyApiProvider = Provider<TaxonomyApi>(
  (ref) => TaxonomyApi(ref.watch(apiDioProvider)),
);
final memoryApiProvider = Provider<MemoryApi>(
  (ref) => MemoryApi(ref.watch(apiDioProvider)),
);
final healthApiProvider = Provider<HealthApi>(
  (ref) => HealthApi(ref.watch(apiDioProvider)),
);

final capabilitiesApiProvider = Provider<CapabilitiesApi>(
  (ref) => CapabilitiesApi(ref.watch(apiDioProvider)),
);

/// Fail closed in every consumer (`valueOrNull ?? const Capabilities()`). Watching
/// the session key prevents one account's grants from leaking into the next one.
final capabilitiesProvider = FutureProvider<Capabilities>((ref) async {
  final key = ref.watch(sessionKeyProvider);
  if (key == null) return const Capabilities();
  return ref.watch(capabilitiesApiProvider).get();
});
