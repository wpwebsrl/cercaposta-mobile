import 'package:cercaposta/core/auth/google_oauth_bridge.dart';
import 'package:cercaposta/core/legal/legal_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Google OAuth native callback', () {
    test('accepts only the exact private CercaPosta target', () {
      expect(
        GoogleOAuthBridge.isGoogleCallback(
          Uri.parse(
            'it.cercaposta.app://oauth/google?code=once&state=expected',
          ),
        ),
        isTrue,
      );
      expect(
        GoogleOAuthBridge.isGoogleCallback(
          Uri.parse('it.cercaposta.app://oauth/other?code=once'),
        ),
        isFalse,
      );
      expect(
        GoogleOAuthBridge.isGoogleCallback(
          Uri.parse('https://cercaposta.it/oauth/google'),
        ),
        isFalse,
      );
    });
  });

  group('public legal links', () {
    test('selects Italian pages by default and English when requested', () {
      expect(
        legalUri(LegalDestination.privacy, const Locale('it')).toString(),
        'https://cercaposta.it/legal/privacy.it.html',
      );
      expect(
        legalUri(LegalDestination.terms, const Locale('en')).toString(),
        'https://cercaposta.it/legal/terms.en.html',
      );
      expect(
        legalUri(LegalDestination.support, const Locale('de')).toString(),
        'https://cercaposta.it/legal/support.it.html',
      );
    });
  });
}
