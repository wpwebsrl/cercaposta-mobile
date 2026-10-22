import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:cercaposta/core/api/api_exception.dart';
import 'package:cercaposta/core/api/error_messages.dart';
import 'package:cercaposta/core/i18n/app_localizations.dart';

void main() {
  test(
    'shared critical errors have actionable messages in every locale',
    () async {
      final contract =
          jsonDecode(File('tool/critical-errors.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(contract['schema'], 1);
      for (final supported in AppLocalizations.supportedLocales) {
        final locale = await AppLocalizations.delegate.load(supported);
        final generic = localizeApiError(
          locale,
          ApiException('unknown.synthetic'),
        );
        for (final row in contract['errors'] as List<dynamic>) {
          final code = row['code'] as String;
          final message = localizeApiError(locale, ApiException(code));
          expect(message.trim(), isNotEmpty, reason: code);
          expect(message, isNot(generic), reason: code);
        }
      }
    },
  );
}
