/// Email HTML on a real browser engine (the platform WebView).
///
/// Why not `flutter_widget_from_html_core`, which this replaces: real mail lays out with nested
/// tables + a `<style>` block + inline `style=""`, and a widget renderer implements a small subset
/// of CSS — it cannot lay that out. The same newsletter that renders correctly in Outlook came out
/// mangled. The web reader (an iframe) and the desktop reader (QtWebEngine) both feed a real engine
/// the same document; this is the mobile third of that contract.
///
/// **Hardening.** We render untrusted third-party HTML, so the engine is kept as narrow as it goes:
///
/// * **JavaScript OFF.** Mail never needs it and the server's `sanitize_html` already strips
///   `<script>`. This turns off V8/JIT, where most engine CVEs live.
/// * **CSP** `default-src 'none'` with an explicit `img-src`: defence in depth over the server's
///   own remote-URL blocking, so a vector its regexes missed still cannot phone home.
/// * **Navigation refused**: a tapped link leaves through the OS browser; the view never navigates.
///
/// Unlike the desktop we do not add a request interceptor — `webview_flutter` has no hook for it —
/// so the posture here matches the **web** reader (server sanitizer + CSP), not the desktop's extra
/// belt. See `docs/mobile-apps.md` and PIANO-MOBILE-WEBVIEW-2026-07-15.md in the server repo.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The reader document: an archived email, laid out to fit the phone.
///
/// Mirrors `frontend/.../ReaderPane.tsx` (`iframeDoc`) and
/// `desktop/.../mail_view.py` (`build_document`) — keep the three in step, or the same email
/// starts looking different depending on which surface you open it from.
String buildReaderDocument(String bodyHtml, {required bool allowRemote}) {
  // `data:` covers the email's own inlined cid: images; opting into remote images widens it to
  // https: only. No script-src is needed: JavaScript is off at the engine.
  final String imgSrc = allowRemote ? 'data: https:' : 'data:';
  final String csp =
      "default-src 'none'; img-src $imgSrc; style-src 'unsafe-inline'; font-src data:";
  // The viewport meta is the one thing NOT in the web/desktop documents, and it is not optional
  // here: with no viewport an Android WebView assumes a ~980px desktop window and scales the whole
  // email down to fit the phone, which is unreadable. `width=device-width` lays the body out at
  // the real screen width, which is what `img{max-width:100%}` below is relative to.
  return '''<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="$csp">
<meta name="referrer" content="no-referrer">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{font-family:system-ui,sans-serif;font-size:13.5px;margin:12px;line-height:1.5;overflow-wrap:break-word}
/* overflow-wrap, NOT `word-break:break-word` — they look interchangeable and are not. Chromium
   resolves that legacy alias to `overflow-wrap:ANYWHERE`, which is defined to count its break
   opportunities when computing min-content width; so a table cell holding «Status» claimed it could
   live in the width of «S», auto-layout took the offer, and a GitHub notification came out with the
   column collapsed and the word stacked letter by letter (Outlook rendered it fine). `break-word`
   still rescues a long unbreakable URL from overflowing the pane — the reason the rule exists — but
   keeps its hands off intrinsic sizing. Measured guard in the server repo's desktop
   test_mail_view.py: the header was 6.1 lines tall before, 1 after. */
/* height:auto so an image keeps its aspect ratio when max-width clamps the width. It has to be
   !important: Outlook writes the size into an INLINE style — a real one from the archive is
   `<img width="1643" height="847" style="width:17.113in;height:8.8214in">` — and an inline
   declaration beats a normal rule in here, so max-width squeezed the width while the inline height
   stayed put and every Outlook screenshot came out STRETCHED. Measured on Chromium at a 420px
   viewport: 405x847 with plain `height:auto`, 420x210 with this one. Keep the three surfaces in
   step (ReaderPane.tsx, desktop's mail_view.py, here) — this bug hit all three at once.
   Known limit, pre-existing and NOT fixed by this: a spacer (`<img width="600" height="3">` on a
   1x1 file) inflates, because once loaded the engine uses the file's real ratio, not the declared
   one. That needs the server to rewrite the markup. */
img{max-width:100%;height:auto!important}
/* Always white, in BOTH themes: mail is authored against an implicit white canvas and carries the
   sender's own colours, so on a dark surface a sender's color:#1a1a1a would be unreadable. Same
   rule as web and desktop. Our rules are in <head>; the email's <style> lands in <body> and so
   wins the cascade wherever it has an opinion. */
body{background:#ffffff;color:#1b1f24} a{color:#0b66c3}</style></head>
<body>$bodyHtml</body></html>''';
}

/// The reminder preview: the composed email exactly as its recipient will get it.
///
/// Mirrors `desktop/.../mail_view.py` (`build_preview_document`) and
/// `frontend/.../EmailPreview.tsx` (`emailDoc`). Different job from the reader, hence a different
/// document: **no** `img{max-width:100%}` and a **fixed** 940px width (a typical Outlook reading
/// pane), because the question this answers is «how will this land for them?» — lines must wrap
/// where they will wrap for the recipient, not where this phone would wrap them.
///
/// `width=940` in the viewport (not `device-width`) is deliberate and is the mobile-specific half:
/// it makes the engine lay out at 940px and then scale that to the screen, so the recipient's line
/// breaks survive, just smaller — and pinch-zoom reads them. Laying out at device width would
/// silently reflow the email and misreport what the recipient gets, which is the one thing this
/// screen must never do.
String buildPreviewDocument(String html) {
  const String csp =
      "default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src data:";
  return '''<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="$csp">
<meta name="referrer" content="no-referrer">
<meta name="viewport" content="width=940">
</head>
<body style="margin:0;background:#ffffff;color:#222222;">
<div style="padding:16px;width:940px;box-sizing:border-box;">$html</div></body></html>''';
}

/// Renders one of the documents above. The body owns its scrolling: the WebView keeps its own
/// viewport, which is why callers must give it a bounded height rather than put it in a list.
class MailWebView extends StatefulWidget {
  const MailWebView({required this.document, this.onTapUrl, super.key});

  /// A document from [buildReaderDocument] or [buildPreviewDocument] — never raw email HTML:
  /// the wrapper is what carries the CSP and the white surface.
  final String document;

  /// Invoked for a tapped link, with the raw URL. The view never navigates either way, so what
  /// counts as an openable scheme is the caller's policy, not this widget's. Null = links do
  /// nothing.
  final void Function(String)? onTapUrl;

  @override
  State<MailWebView> createState() => _MailWebViewState();
}

class _MailWebViewState extends State<MailWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigation),
      )
      ..loadHtmlString(widget.document);
  }

  @override
  void didUpdateWidget(covariant MailWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opting into remote images rebuilds the document: re-render rather than rebuild the engine.
    if (oldWidget.document != widget.document) {
      _controller.loadHtmlString(widget.document);
    }
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    // `loadHtmlString` lands on about:blank — that is our own document being (re)loaded.
    if (request.url == 'about:blank') return NavigationDecision.navigate;
    // Everything else goes to the caller as-is: which schemes are safe to open is one policy and
    // it lives in one place (the reader's `_onTapUrl`), not half here and half there.
    widget.onTapUrl?.call(request.url);
    // Never navigate the view away from the email, whatever the caller decides to do with it.
    return NavigationDecision.prevent;
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
