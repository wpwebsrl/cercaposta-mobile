import 'dart:async';
import 'dart:convert';

import 'package:cercaposta/core/api/api_exception.dart';
import 'package:cercaposta/core/auth/auth_controller.dart';
import 'package:cercaposta/core/auth/biometric_vault.dart';
import 'package:cercaposta/core/auth/device_grant.dart';
import 'package:cercaposta/core/auth/secure_store.dart';
import 'package:cercaposta/core/providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_biometric_vault.dart';
import 'session_isolation_test.dart'
    show containerFor, pair, json, sessionChanged;

const info = DeviceGrantInfo(
  server: 'https://a.example',
  userId: 'A',
  username: 'A',
  deviceId: 'device-A',
);
final secret = 's' * 43;
Matcher code(String value) =>
    throwsA(predicate<Object>((e) => ApiException.from(e).code == value));

Future<void> seed(SecureStore store) async {
  await store.writeGrant(
    DeviceGrant(info, secret),
    reason: 'Authorize',
    cancel: 'Cancel',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native store refuses unsupported platforms instead of using an unlocked fallback',
    () async {
      await expectLater(
        NativeBiometricVault().read('test', reason: 'Test', cancel: 'Cancel'),
        code('biometric.unavailable'),
      );
    },
  );

  test(
    'ordinary secure storage contains only metadata, never the device secret or account password',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final vault = FakeBiometricVault();
      final store = SecureStore(biometricVault: vault);
      await seed(store);
      final values = await const FlutterSecureStorage().readAll();
      expect(values.length, 1);
      expect(values.values.single.contains(secret), isFalse);
      expect(values.values.single.contains('password'), isFalse);
      expect(vault.values[info.storageName], contains(secret));
      expect(vault.reads, 0);
      await store.readGrantInfo();
      expect(vault.reads, 0);
      await store.readGrant(info, reason: 'Unlock', cancel: 'Cancel');
      await store.readGrant(info, reason: 'Unlock again', cancel: 'Cancel');
      expect(vault.reads, 2); // no app cache authorizes later operations
    },
  );

  for (final binding in [
    'server',
    'user_id',
    'username',
    'device_id',
    'device_secret',
  ]) {
    test('tampered $binding in native value is rejected', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final vault = FakeBiometricVault();
      final store = SecureStore(biometricVault: vault);
      await seed(store);
      final value = jsonDecode(vault.values[info.storageName]!) as Map;
      value[binding] = 'other';
      vault.values[info.storageName] = jsonEncode(value);
      await expectLater(
        store.readGrant(info, reason: 'Unlock', cancel: 'Cancel'),
        code('biometric.reenroll'),
      );
    });
  }

  test('cancelled replacement preserves the previous usable grant', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final vault = FakeBiometricVault();
    final store = SecureStore(biometricVault: vault);
    await seed(store);
    vault.writeError = ApiException('biometric.cancelled');
    const replacement = DeviceGrantInfo(
      server: 'https://a.example',
      userId: 'A',
      username: 'A',
      deviceId: 'device-new',
    );
    await expectLater(
      store.writeGrant(
        DeviceGrant(replacement, 'n' * 43),
        reason: 'Save',
        cancel: 'Cancel',
      ),
      code('biometric.cancelled'),
    );
    expect((await store.readGrantInfo())?.deviceId, info.deviceId);
    expect(vault.values.keys.toList(), [info.storageName]);
  });

  test(
    'login waits for OS read, sends opaque grant and never replays account password',
    () async {
      final vault = FakeBiometricVault();
      final requests = <String>[];
      final c = await containerFor(
        vault: vault,
        handle: (request) async {
          requests.add(request.path);
          expect(request.path, '/auth/mobile-device/login');
          final data = request.data as Map;
          expect(data['device_secret'], secret);
          expect(data.containsKey('password'), isFalse);
          return json(pair('A'));
        },
      );
      await seed(c.read(secureStoreProvider));
      vault.readEntered = Completer<void>();
      vault.readRelease = Completer<void>();
      final pending = c
          .read(authProvider.notifier)
          .biometricLogin(reason: 'Login', cancel: 'Cancel');
      await vault.readEntered!.future;
      expect(requests, isEmpty);
      vault.readRelease!.complete();
      await pending;
      expect(c.read(authProvider).user?.id, 'A');
      expect(requests, ['/auth/mobile-device/login']);
    },
  );

  for (final change in ['server', 'logout', 'account']) {
    test(
      '$change while biometric read is pending discards the secret before network login',
      () async {
        final vault = FakeBiometricVault();
        final requests = <String>[];
        final c = await containerFor(
          vault: vault,
          handle: (request) async {
            requests.add(request.path);
            return json(pair('B'));
          },
        );
        await seed(c.read(secureStoreProvider));
        vault.readEntered = Completer<void>();
        vault.readRelease = Completer<void>();
        final auth = c.read(authProvider.notifier);
        final pending = auth.biometricLogin(reason: 'Login', cancel: 'Cancel');
        final checked = expectLater(pending, sessionChanged);
        await vault.readEntered!.future;
        if (change == 'server') {
          await c
              .read(activeServerProvider.notifier)
              .select('https://b.example');
        } else if (change == 'logout') {
          await auth.forceLogout();
        } else {
          await auth.login('B', 'password-B');
        }
        vault.readRelease!.complete();
        await checked;
        expect(requests.contains('/auth/mobile-device/login'), isFalse);
      },
    );
  }

  for (final error in [
    'biometric.cancelled',
    'biometric.unavailable',
    'biometric.reenroll',
  ]) {
    test('native $error falls back without sending credentials', () async {
      final vault = FakeBiometricVault();
      final requests = <String>[];
      final c = await containerFor(
        vault: vault,
        handle: (request) async {
          requests.add(request.path);
          return json({});
        },
      );
      await seed(c.read(secureStoreProvider));
      vault.readError = ApiException(error);
      await expectLater(
        c
            .read(authProvider.notifier)
            .biometricLogin(reason: 'Login', cancel: 'Cancel'),
        code(error),
      );
      expect(requests, isEmpty);
      expect(
        await c.read(secureStoreProvider).readGrantInfo(),
        error == 'biometric.reenroll' ? isNull : isNotNull,
      );
    });
  }

  for (final status in [401, 503]) {
    test('server rejection $status forgets only revoked grants', () async {
      final vault = FakeBiometricVault();
      final c = await containerFor(
        vault: vault,
        handle: (_) async => json({
          'error': {
            'code': status == 401
                ? 'trusted_device.not_available'
                : 'common.network',
          },
        }, status),
      );
      await seed(c.read(secureStoreProvider));
      await expectLater(
        c
            .read(authProvider.notifier)
            .biometricLogin(reason: 'Login', cancel: 'Cancel'),
        throwsA(isA<Object>()),
      );
      expect(
        await c.read(secureStoreProvider).readGrantInfo(),
        status == 401 ? isNull : isNotNull,
      );
    });
  }

  test(
    'TOTP is preserved after device login and its returned owner must match',
    () async {
      final vault = FakeBiometricVault();
      final c = await containerFor(
        vault: vault,
        handle: (request) async => request.path == '/auth/mobile-device/login'
            ? json({'requires_totp': true, 'totp_token': 'challenge'})
            : json(pair('B')),
      );
      await seed(c.read(secureStoreProvider));
      final auth = c.read(authProvider.notifier);
      await auth.biometricLogin(reason: 'Login', cancel: 'Cancel');
      expect(c.read(authProvider).status, AuthStatus.needsTotp);
      expect(c.read(authProvider).accessToken, isNull);
      await expectLater(auth.verifyTotp('123456'), sessionChanged);
      expect(c.read(authProvider).accessToken, isNull);
    },
  );

  test(
    'archive unlock requires native authorization and sends no password',
    () async {
      final vault = FakeBiometricVault();
      final c = await containerFor(
        vault: vault,
        handle: (request) async {
          if (request.path == '/auth/login') return json(pair('A'));
          expect(request.path, '/auth/trusted-device/unlock');
          expect(request.data, {
            'device_id': info.deviceId,
            'device_secret': secret,
          });
          return json({'enc_status': 'active', 'dek_available': true});
        },
      );
      await seed(c.read(secureStoreProvider));
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      auth.markLocked();
      expect(
        await auth.biometricUnlock(reason: 'Unlock', cancel: 'Cancel'),
        isTrue,
      );
      expect(vault.reads, 1);
      expect(c.read(authProvider).status, AuthStatus.loggedIn);
    },
  );

  test(
    'cancelled enrollment revokes newly minted grant and preserves old metadata',
    () async {
      final vault = FakeBiometricVault();
      final revoked = <String>[];
      final c = await containerFor(
        vault: vault,
        handle: (request) async {
          if (request.path == '/auth/login') return json(pair('A'));
          if (request.path == '/auth/mobile-device/enroll') {
            expect((request.data as Map)['password'], 'password-A');
            return json({'id': 'device-new', 'device_secret': 'n' * 43});
          }
          revoked.add(request.path);
          return json({});
        },
      );
      await seed(c.read(secureStoreProvider));
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      vault.writeError = ApiException('biometric.cancelled');
      await expectLater(
        auth.enableBiometricFromSession(reason: 'Save', cancel: 'Cancel'),
        code('biometric.cancelled'),
      );
      expect(revoked, ['/me/trusted-devices/device-new']);
      expect(
        (await c.read(secureStoreProvider).readGrantInfo())?.deviceId,
        info.deviceId,
      );
    },
  );

  test(
    'server change during enrollment prompt never publishes the stale selector',
    () async {
      final vault = FakeBiometricVault();
      final revoked = <String>[];
      final c = await containerFor(
        vault: vault,
        handle: (request) async {
          if (request.path == '/auth/login') return json(pair('A'));
          if (request.path == '/auth/mobile-device/enroll') {
            return json({'id': 'device-new', 'device_secret': 'n' * 43});
          }
          revoked.add(request.path);
          return json({});
        },
      );
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      vault.writeEntered = Completer<void>();
      vault.writeRelease = Completer<void>();
      final pending = auth.enableBiometricFromSession(
        reason: 'Save',
        cancel: 'Cancel',
      );
      final checked = expectLater(pending, sessionChanged);
      await vault.writeEntered!.future;
      await c.read(activeServerProvider.notifier).select('https://b.example');
      vault.writeRelease!.complete();
      await checked;
      expect(await c.read(secureStoreProvider).readGrantInfo(), isNull);
      expect(vault.values, isEmpty);
      expect(revoked, ['/me/trusted-devices/device-new']);
    },
  );

  test(
    'failed remote disable keeps the local grant until revocation is confirmed',
    () async {
      final vault = FakeBiometricVault();
      final c = await containerFor(
        vault: vault,
        handle: (request) async => request.path == '/auth/login'
            ? json(pair('A'))
            : json({
                'error': {'code': 'common.network'},
              }, 503),
      );
      await seed(c.read(secureStoreProvider));
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      await expectLater(auth.disableBiometric(), throwsA(isA<Object>()));
      expect(await c.read(secureStoreProvider).readGrantInfo(), isNotNull);
      expect(vault.reads, 0);
    },
  );

  test(
    'a grant already revoked remotely can still be disabled locally',
    () async {
      final vault = FakeBiometricVault();
      final c = await containerFor(
        vault: vault,
        handle: (request) async => request.path == '/auth/login'
            ? json(pair('A'))
            : json({
                'error': {'code': 'trusted_device.not_found'},
              }, 404),
      );
      await seed(c.read(secureStoreProvider));
      final auth = c.read(authProvider.notifier);
      await auth.login('A', 'password-A');
      await auth.disableBiometric();
      expect(await c.read(secureStoreProvider).readGrantInfo(), isNull);
      expect(vault.values, isEmpty);
    },
  );
}
