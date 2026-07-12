import 'package:cercaposta/features/followups/reminder_mailto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decode the `body=` query of a built mailto back to plain text, to assert on
/// the joined content without hand-encoding it in the expectations.
String _bodyOf(String url) {
  final q = Uri.parse(url).query;
  final match = RegExp(r'body=([^&]*)').firstMatch(q)!;
  return Uri.decodeComponent(match.group(1)!);
}

void main() {
  test('joins prefix, body and suffix with blank lines', () {
    final url = reminderMailtoUrl(
      address: 'x@y.z',
      subject: 'Re: preventivo',
      prefix: 'Avviso AI',
      body: 'Ciao, un promemoria.',
      suffix: '-- \nDavide',
    );
    expect(_bodyOf(url), 'Avviso AI\n\nCiao, un promemoria.\n\n-- \nDavide');
  });

  test('empty prefix/suffix are omitted (no leading/trailing blank lines)', () {
    final url = reminderMailtoUrl(
      address: 'x@y.z',
      subject: 's',
      prefix: '',
      body: 'Solo il messaggio.',
      suffix: '   ',
    );
    expect(_bodyOf(url), 'Solo il messaggio.');
  });

  test('address and subject are percent-encoded; & and spaces survive', () {
    final url = reminderMailtoUrl(
      address: 'a b@y.z',
      subject: 'Costi & tempi',
      prefix: '',
      body: 'x',
      suffix: '',
    );
    expect(url.startsWith('mailto:a%20b%40y.z?'), isTrue);
    expect(Uri.parse(url).queryParameters['subject'], 'Costi & tempi');
  });
}
