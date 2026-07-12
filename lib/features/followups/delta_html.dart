import 'package:flutter_quill/quill_delta.dart';

/// Convert a Quill [Delta] to the SMALL HTML subset the reminder-body sanitizer on
/// the server accepts (server repo, `sanitize_reminder_body_html`): `<p> <strong>
/// <em> <u> <s> <a href> <ul>/<ol>/<li>`. Text is always escaped; only http/https/
/// mailto/tel links survive. No third-party converter — the output stays inside the
/// allowlist by construction, and it's deterministic (golden-tested).
///
/// Quill represents inline formatting (bold/italic/…) as attributes on the text run,
/// and block formatting (lists) as attributes on the `\n` that terminates the line.
String deltaToHtml(Delta delta) {
  final lines = _splitLines(delta);
  final hasContent = lines.any(
    (l) => l.list != null || l.spans.any((s) => s.text.trim().isNotEmpty),
  );
  // An "empty" document (just Quill's terminator) → empty string, so the server
  // composes the HTML from the plain-text core instead.
  if (!hasContent) return '';

  final buf = StringBuffer();
  String? openList; // 'bullet' | 'ordered' while a list is open, else null
  void closeList() {
    if (openList != null) {
      buf.write(openList == 'ordered' ? '</ol>' : '</ul>');
      openList = null;
    }
  }

  for (final line in lines) {
    final inner = line.render();
    if (line.list == 'bullet' || line.list == 'ordered') {
      if (openList != line.list) {
        closeList();
        buf.write(line.list == 'ordered' ? '<ol>' : '<ul>');
        openList = line.list;
      }
      buf.write('<li>$inner</li>');
    } else {
      closeList();
      buf.write(inner.isEmpty ? '<p><br></p>' : '<p>$inner</p>');
    }
  }
  closeList();
  return buf.toString();
}

List<_Line> _splitLines(Delta delta) {
  final lines = <_Line>[_Line()];
  for (final op in delta.toList()) {
    if (!op.isInsert) continue;
    final data = op.data;
    // Embeds (images/formulas) aren't in our subset.
    if (data is! String) continue;
    final attrs = op.attributes ?? const <String, dynamic>{};
    final span = _SpanStyle(
      bold: attrs['bold'] == true,
      italic: attrs['italic'] == true,
      underline: attrs['underline'] == true,
      strike: attrs['strike'] == true,
      link: attrs['link'] is String ? attrs['link'] as String : null,
    );
    final list = attrs['list'] is String ? attrs['list'] as String : null;
    final parts = data.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        lines.last.spans.add(_Span(parts[i], span));
      }
      if (i < parts.length - 1) {
        // Newline boundary: the block (list) attribute belongs to this line.
        lines.last.list = list;
        lines.add(_Line());
      }
    }
  }
  // Drop the trailing empty line that Quill's mandatory final \n produces, so we
  // don't emit a spurious empty paragraph at the end.
  if (lines.length > 1 && lines.last.spans.isEmpty && lines.last.list == null) {
    lines.removeLast();
  }
  return lines;
}

class _Line {
  final List<_Span> spans = <_Span>[];
  String? list;
  String render() => spans.map((s) => s.render()).join();
}

class _SpanStyle {
  const _SpanStyle({
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strike,
    required this.link,
  });
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String? link;
}

class _Span {
  _Span(this.text, this.style);
  final String text;
  final _SpanStyle style;

  String render() {
    var h = _escape(text);
    if (style.strike) h = '<s>$h</s>';
    if (style.underline) h = '<u>$h</u>';
    if (style.italic) h = '<em>$h</em>';
    if (style.bold) h = '<strong>$h</strong>';
    final url = _safeUrl(style.link);
    if (url != null) h = '<a href="$url">$h</a>';
    return h;
  }
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Escaped URL if it uses an allowed scheme (mirrors the server's url_schemes),
/// else null so the link is dropped and only its text is kept.
String? _safeUrl(String? url) {
  if (url == null) return null;
  final u = url.trim();
  final lower = u.toLowerCase();
  const allowed = <String>['http://', 'https://', 'mailto:', 'tel:'];
  if (!allowed.any(lower.startsWith)) return null;
  return _escape(u);
}
