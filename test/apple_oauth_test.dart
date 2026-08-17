import 'package:cercaposta/core/auth/apple_oauth_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple OAuth native callback', () {
    test('accepts only the exact private CercaPosta target', () {
      expect(
        AppleOAuthBridge.isAppleCallback(
          Uri.parse('it.cercaposta.app://oauth/apple?code=once&state=expected'),
        ),
        isTrue,
      );
      expect(
        AppleOAuthBridge.isAppleCallback(
          Uri.parse('it.cercaposta.app://oauth/other?code=once'),
        ),
        isFalse,
      );
      expect(
        AppleOAuthBridge.isAppleCallback(
          Uri.parse('https://cercaposta.it/oauth/apple'),
        ),
        isFalse,
      );
    });
  });
}
