import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cercaposta/core/api/services/message_api.dart';

/// Byte-level cut of the RFC822 header block. Getting this wrong either truncates the
/// headers or defeats the early stop and drags the whole `.eml` — attachments included —
/// down a mobile connection, so it is pinned here.
void main() {
  List<int> b(String s) => utf8.encode(s);

  group('headerEnd', () {
    test('finds the CRLF blank line that closes the headers', () {
      final raw = b('From: a@b.it\r\nSubject: Ciao\r\n\r\nCorpo del messaggio');
      final end = headerEnd(raw);
      expect(end, greaterThan(0));
      expect(
        decodeHeaderBytes(raw.sublist(0, end)),
        'From: a@b.it\r\nSubject: Ciao',
      );
    });

    test('accepts bare LF, as gateways that rewrite line endings leave it', () {
      final raw = b('From: a@b.it\nSubject: Ciao\n\nCorpo');
      final end = headerEnd(raw);
      expect(
        decodeHeaderBytes(raw.sublist(0, end)),
        'From: a@b.it\nSubject: Ciao',
      );
    });

    test('reports -1 while the block is still open, so the read continues', () {
      expect(headerEnd(b('From: a@b.it\r\nSubject: incom')), -1);
      expect(headerEnd(b('')), -1);
    });

    test('stops at the FIRST blank line, not at one inside the body', () {
      final raw = b('From: a@b.it\r\n\r\nCorpo\r\n\r\nAltro paragrafo');
      expect(headerEnd(raw), b('From: a@b.it').length);
    });

    test('a folded header keeps its continuation lines', () {
      final raw = b('To: a@b.it,\r\n\tc@d.it\r\nSubject: X\r\n\r\nCorpo');
      final end = headerEnd(raw);
      expect(decodeHeaderBytes(raw.sublist(0, end)), contains('c@d.it'));
      expect(decodeHeaderBytes(raw.sublist(0, end)), isNot(contains('Corpo')));
    });
  });

  group('decodeHeaderBytes', () {
    test('decodes utf-8', () {
      expect(decodeHeaderBytes(b('Subject: perché')), 'Subject: perché');
    });

    test('falls back to latin-1 on 8-bit bytes instead of throwing', () {
      // 0xE8 is 'è' in latin-1 and invalid on its own in utf-8.
      final raw = <int>[...b('Subject: perch'), 0xE8];
      expect(decodeHeaderBytes(raw), 'Subject: perchè');
    });
  });
}
