import 'package:flutter_test/flutter_test.dart';

import 'package:cercaposta/shared/models/message.dart';

/// The payload `GET /messages/{id}` really returns: `recipients` holds objects,
/// not strings (backend `parser.py::_address_list` -> `{"name", "address"}`).
/// Parsing it as a list of strings silently yielded an empty list, so the To/Cc/Bcc
/// rows never rendered — these tests exist to keep that from coming back.
Map<String, dynamic> _detailJson({
  List<Map<String, String>>? to,
  List<Map<String, String>>? cc,
  List<Map<String, String>>? bcc,
}) => <String, dynamic>{
  'id': 'a1',
  'subject': 'Oggetto',
  'from_name': 'Mario Rossi',
  'from_address': 'mario@example.it',
  'recipients': <String, dynamic>{
    'to': to ?? <Map<String, String>>[],
    'cc': cc ?? <Map<String, String>>[],
    'bcc': bcc ?? <Map<String, String>>[],
  },
  'body_text': '',
  'attachments': <dynamic>[],
  'folders': <dynamic>[],
  'tags': <dynamic>[],
};

void main() {
  group('MessageDetail recipients', () {
    test('parses the {name,address} objects the server actually sends', () {
      final d = MessageDetail.fromJson(
        _detailJson(
          to: [
            {'name': 'Anna Bianchi', 'address': 'anna@example.it'},
          ],
        ),
      );

      expect(d.to, hasLength(1));
      expect(d.to.single.name, 'Anna Bianchi');
      expect(d.to.single.address, 'anna@example.it');
    });

    test('keeps every address when a field carries more than one', () {
      final d = MessageDetail.fromJson(
        _detailJson(
          to: [
            {'name': 'Anna', 'address': 'anna@example.it'},
            {'name': 'Luca', 'address': 'luca@example.it'},
            {'name': '', 'address': 'terzo@example.it'},
          ],
          cc: [
            {'name': 'Ufficio', 'address': 'ufficio@example.it'},
            {'name': '', 'address': 'altro@example.it'},
          ],
        ),
      );

      expect(d.to, hasLength(3));
      expect(d.cc, hasLength(2));
    });

    test('empty buckets stay empty (received mail has no Bcc header)', () {
      final d = MessageDetail.fromJson(_detailJson());
      expect(d.to, isEmpty);
      expect(d.cc, isEmpty);
      expect(d.bcc, isEmpty);
    });

    test('a Bcc is parsed when present, as on sent copies', () {
      final d = MessageDetail.fromJson(
        _detailJson(
          bcc: [
            {'name': '', 'address': 'nascosto@example.it'},
          ],
        ),
      );
      expect(d.bcc.single.address, 'nascosto@example.it');
    });

    test('malformed buckets degrade to empty instead of throwing', () {
      final d = MessageDetail.fromJson(<String, dynamic>{
        'id': 'a1',
        'subject': '',
        'from_name': '',
        'from_address': '',
        'recipients': <String, dynamic>{'to': 'non-una-lista'},
        'body_text': '',
        'attachments': <dynamic>[],
        'folders': <dynamic>[],
        'tags': <dynamic>[],
      });
      expect(d.to, isEmpty);
    });
  });

  group('Recipient.display', () {
    test('shows "Name <address>" when both are known', () {
      const r = Recipient(name: 'Anna Bianchi', address: 'anna@example.it');
      expect(r.display, 'Anna Bianchi <anna@example.it>');
    });

    test('falls back to the bare address when the name is empty', () {
      const r = Recipient(name: '', address: 'anna@example.it');
      expect(r.display, 'anna@example.it');
    });

    test('falls back to the name when the address is empty', () {
      const r = Recipient(name: 'Anna', address: '');
      expect(r.display, 'Anna');
    });
  });
}
