import 'dart:io';
import 'package:cercaposta/core/api/api_exception.dart';
import 'package:cercaposta/core/auth/passkey_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS allows only shipped associations and preserves password fallback',
    () {
      expect(
        passkeyServerSupported('ios', 'https://app.cercaposta.it'),
        isTrue,
      );
      for (final server in [
        null,
        'http://app.cercaposta.it',
        'https://self.example',
        'https://app.cercaposta.it.evil.example',
        'https://user@app.cercaposta.it',
        'https://192.0.2.1',
      ]) {
        expect(passkeyServerSupported('ios', server), isFalse);
        expect(
          () => requirePasskeyServer('ios', server),
          throwsA(isA<ApiException>()),
        );
      }
      expect(passkeyServerSupported('android', 'https://self.example'), isTrue);
    },
  );

  test('server options cannot silently select another relying party', () {
    requirePasskeyServer(
      'ios',
      'https://app.cercaposta.it',
      rpId: 'app.cercaposta.it',
    );
    for (final rp in ['', 'evil.example', 'cercaposta.it']) {
      expect(
        () =>
            requirePasskeyServer('ios', 'https://app.cercaposta.it', rpId: rp),
        throwsA(isA<ApiException>()),
      );
    }
    requirePasskeyServer(
      'android',
      'https://mail.self.example',
      rpId: 'self.example',
    );
    expect(
      () => requirePasskeyServer(
        'android',
        'https://mail.self.example',
        rpId: 'other.example',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('runtime iOS allowlist exactly matches signed entitlements', () {
    final xml = File('ios/Runner/Runner.entitlements').readAsStringSync();
    final shipped = RegExp(
      r'<string>webcredentials:([^<]+)</string>',
    ).allMatches(xml).map((m) => m.group(1)!).toSet();
    expect(shipped, iosPasskeyDomains);
  });
}
