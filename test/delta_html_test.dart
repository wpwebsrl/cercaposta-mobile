import 'package:cercaposta/features/followups/delta_html.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tags the server's reminder-body sanitizer accepts (`sanitize_reminder_body_html`).
/// The converter must never emit anything outside this set.
const _allowed = <String>{
  'p',
  'br',
  'strong',
  'em',
  'u',
  's',
  'a',
  'ul',
  'ol',
  'li',
};

Set<String> _tagsIn(String html) => RegExp(
  r'</?([a-zA-Z0-9]+)',
).allMatches(html).map((m) => m.group(1)!.toLowerCase()).toSet();

void main() {
  test('plain single line → one paragraph', () {
    expect(deltaToHtml(Delta()..insert('Hello\n')), '<p>Hello</p>');
  });

  test('inline bold inside a paragraph', () {
    final d = Delta()
      ..insert('Hello ')
      ..insert('world', <String, dynamic>{'bold': true})
      ..insert('\n');
    expect(deltaToHtml(d), '<p>Hello <strong>world</strong></p>');
  });

  test('combined marks nest link outside, strong/em/u/s inside', () {
    final d = Delta()
      ..insert('x', <String, dynamic>{
        'bold': true,
        'italic': true,
        'underline': true,
        'strike': true,
        'link': 'https://a.io',
      })
      ..insert('\n');
    expect(
      deltaToHtml(d),
      '<p><a href="https://a.io"><strong><em><u><s>x</s></u></em></strong></a></p>',
    );
  });

  test('a disallowed link scheme is dropped, keeping the text', () {
    final d = Delta()
      ..insert('click', <String, dynamic>{'link': 'javascript:alert(1)'})
      ..insert('\n');
    expect(deltaToHtml(d), '<p>click</p>');
  });

  test('bullet list groups contiguous items', () {
    final d = Delta()
      ..insert('a')
      ..insert('\n', <String, dynamic>{'list': 'bullet'})
      ..insert('b')
      ..insert('\n', <String, dynamic>{'list': 'bullet'});
    expect(deltaToHtml(d), '<ul><li>a</li><li>b</li></ul>');
  });

  test('ordered list and a following paragraph close the list', () {
    final d = Delta()
      ..insert('one')
      ..insert('\n', <String, dynamic>{'list': 'ordered'})
      ..insert('after')
      ..insert('\n');
    expect(deltaToHtml(d), '<ol><li>one</li></ol><p>after</p>');
  });

  test('switching bullet → ordered opens a new list', () {
    final d = Delta()
      ..insert('a')
      ..insert('\n', <String, dynamic>{'list': 'bullet'})
      ..insert('b')
      ..insert('\n', <String, dynamic>{'list': 'ordered'});
    expect(deltaToHtml(d), '<ul><li>a</li></ul><ol><li>b</li></ol>');
  });

  test('special characters are HTML-escaped', () {
    expect(
      deltaToHtml(Delta()..insert('a<b>&"c\n')),
      '<p>a&lt;b&gt;&amp;&quot;c</p>',
    );
  });

  test('a blank line between paragraphs becomes an empty paragraph', () {
    final d = Delta()..insert('a\n\nb\n');
    expect(deltaToHtml(d), '<p>a</p><p><br></p><p>b</p>');
  });

  test(
    'an empty document yields empty HTML (server derives from text core)',
    () {
      expect(deltaToHtml(Delta()..insert('\n')), '');
      expect(deltaToHtml(Delta()..insert('   \n')), '');
    },
  );

  test('every emitted tag stays within the server allowlist', () {
    final d = Delta()
      ..insert('title ')
      ..insert('bold', <String, dynamic>{'bold': true})
      ..insert(' ')
      ..insert('link', <String, dynamic>{'link': 'mailto:x@y.z'})
      ..insert('\n')
      ..insert('item1')
      ..insert('\n', <String, dynamic>{'list': 'bullet'})
      ..insert('item2')
      ..insert('\n', <String, dynamic>{'list': 'ordered'});
    final tags = _tagsIn(deltaToHtml(d));
    expect(tags.difference(_allowed), isEmpty);
  });
}
