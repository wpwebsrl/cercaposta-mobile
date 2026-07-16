import 'package:cercaposta/shared/widgets/mail_web_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The email body renders on a real browser engine (see shared/widgets/mail_web_view.dart).
///
/// These pin the two things that are easy to regress silently: the hardening posture (we render
/// untrusted third-party HTML) and the document contract shared with the web and desktop readers —
/// three surfaces that must show the same email the same way.
void main() {
  group('reader document', () {
    test('blocks everything by default', () {
      final String doc = buildReaderDocument('<p>ciao</p>', allowRemote: false);
      expect(doc, contains("default-src 'none'"));
      // `data:` only: the email's own inline cid: images, nothing off-device.
      expect(doc, contains('img-src data:;'));
      final String csp = doc.split('Content-Security-Policy')[1].split('>')[0];
      expect(csp, isNot(contains('https:')));
    });

    test('opens https only when remote images are allowed', () {
      expect(
        buildReaderDocument('<p>ciao</p>', allowRemote: true),
        contains('img-src data: https:'),
      );
    });

    test('renders on white in both themes', () {
      // Mail carries the sender's own colours, so a dark surface would put color:#1a1a1a on a
      // dark background. Same rule as the web and desktop readers.
      final String doc = buildReaderDocument('<p>x</p>', allowRemote: false);
      expect(doc, contains('background:#ffffff'));
      expect(doc, contains('color:#1b1f24'));
    });

    test('clamps images to the screen without stretching them', () {
      // The clamp must beat the SENDER's own inline height, or it distorts instead of resizing.
      // Outlook writes `<img width="1643" height="847" style="width:17.113in;height:8.8214in">`,
      // and an inline declaration outranks a normal rule in our <head>: max-width squeezed the
      // width, the inline height stayed, and every Outlook screenshot came out stretched.
      // Measured on Chromium at a 420px viewport: 405x847 without !important, 420x210 with it.
      final String doc = buildReaderDocument('<p>x</p>', allowRemote: false);
      expect(doc, contains('max-width:100%'));
      expect(doc, contains('height:auto!important'));
    });

    test('lays out at the device width, not a desktop window', () {
      // The one part not shared with web/desktop, and not optional: with no viewport an Android
      // WebView assumes ~980px and scales the whole email down to something unreadable.
      expect(
        buildReaderDocument('<p>x</p>', allowRemote: false),
        contains('width=device-width'),
      );
    });

    test('embeds the body verbatim', () {
      // The body arrives already sanitized from the API; the document must not re-escape it or
      // the email's own markup would show up as text.
      expect(
        buildReaderDocument(
          '<table width="600"><tr><td>x</td></tr></table>',
          allowRemote: false,
        ),
        contains('<table width="600">'),
      );
    });
  });

  // Different job, different document: this one answers «how will this land for the recipient?»,
  // so it must NOT adapt to the phone. Mirrors build_preview_document on the desktop.
  group('reminder preview document', () {
    test('renders at the recipient width, not the phone width', () {
      final String doc = buildPreviewDocument('<p>ciao</p>');
      expect(doc, contains('width:940px'));
      expect(doc, contains('box-sizing:border-box'));
      // Laying out at device width would reflow the email and misreport the recipient's line
      // breaks — the one thing this screen must never do.
      expect(doc, contains('width=940'));
      expect(doc, isNot(contains('width=device-width')));
    });

    test('does not clamp images to the screen', () {
      // The reader clamps so mail fits its pane; shrinking an image here would misreport what
      // the recipient gets.
      expect(
        buildPreviewDocument('<img src="x">'),
        isNot(contains('max-width:100%')),
      );
    });

    test('is white with dark text whatever the theme', () {
      final String doc = buildPreviewDocument('<p>x</p>');
      expect(doc, contains('background:#ffffff'));
      expect(doc, contains('color:#222222'));
    });

    test('blocks remote entirely', () {
      // Everything it needs is already a data: URI. Anything remote would come from the quoted
      // original, and fetching it would fire that email's tracking pixels at US, while previewing.
      final String doc = buildPreviewDocument('<p>x</p>');
      expect(doc, contains("default-src 'none'"));
      expect(doc, contains('img-src data:;'));
      final String csp = doc.split('Content-Security-Policy')[1].split('>')[0];
      expect(csp, isNot(contains('https:')));
    });

    test('embeds the composed html verbatim', () {
      expect(
        buildPreviewDocument(
          '<table width="100%"><tr><td>firma</td></tr></table>',
        ),
        contains('<table width="100%">'),
      );
    });
  });
}
