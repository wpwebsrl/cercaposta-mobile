import 'dart:convert';
import 'dart:io';

import 'package:cercaposta/core/i18n/app_localizations.dart';
import 'package:cercaposta/core/language_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native language declarations and permission descriptions match the registry',
    () {
      final xml = File(
        'android/app/src/main/res/xml/locales_config.xml',
      ).readAsStringSync();
      expect(
        RegExp(
          r'android:name="([^"]+)"',
        ).allMatches(xml).map((match) => match.group(1)).toSet(),
        languageNames.keys.toSet(),
      );
      Set<String?> androidKeys(String path) => RegExp(r'<string name="([^"]+)"')
          .allMatches(File(path).readAsStringSync())
          .map((match) => match.group(1))
          .toSet();
      final baseKeys = androidKeys(
        'android/app/src/main/res/values/strings.xml',
      );
      final permissionKeys = RegExp(r'<key>(NS\w+UsageDescription)</key>')
          .allMatches(File('ios/Runner/Info.plist').readAsStringSync())
          .map((match) => match.group(1)!)
          .toSet();
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final declarations = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>([\s\S]*?)</array>',
      ).firstMatch(plist)!.group(1)!;
      expect(
        RegExp(
          r'<string>([^<]+)</string>',
        ).allMatches(declarations).map((match) => match.group(1)).toSet(),
        languageNames.keys.toSet(),
      );
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      for (final language in languageNames.keys) {
        final reference = RegExp(
          r'([A-F0-9]{24}) /\* ' +
              language +
              r' \*/ = \{isa = PBXFileReference;[^\n]*path = ' +
              language +
              r'\.lproj/InfoPlist\.strings;',
        ).firstMatch(project);
        expect(
          reference,
          isNotNull,
          reason: '$language must be included in Xcode',
        );
        final variants = RegExp(
          r'isa = PBXVariantGroup;\s*children = \(([\s\S]*?)\);\s*name = InfoPlist.strings;',
        ).firstMatch(project)!.group(1)!;
        expect(
          variants.contains(reference!.group(1)!),
          isTrue,
          reason: language,
        );
        expect(
          androidKeys(
            'android/app/src/main/res/values${language == 'en' ? '' : '-$language'}/strings.xml',
          ),
          baseKeys,
          reason: language,
        );
        final permissions = File(
          'ios/Runner/$language.lproj/InfoPlist.strings',
        ).readAsStringSync();
        for (final key in permissionKeys) {
          expect(permissions.contains(key), isTrue, reason: '$language:$key');
        }
      }
    },
  );
  test(
    'every supported language has real ARB text and identical placeholders',
    () {
      final registry =
          jsonDecode(File('assets/l10n/languages.json').readAsStringSync())
              as Map<String, dynamic>;
      final languages = registry['languages'] as List<dynamic>;
      for (final dynamic language in languages) {
        final entry = language as Map<String, dynamic>;
        expect(entry['flag'], matches(RegExp(r'^[a-z]{2}$')));
      }
      expect(
        languages
            .map((dynamic row) => (row as Map<String, dynamic>)['code'])
            .toSet(),
        languageNames.keys.toSet(),
      );
      expect(
        AppLocalizations.supportedLocales
            .map((locale) => locale.languageCode)
            .toSet(),
        languageNames.keys.toSet(),
      );
      final source =
          jsonDecode(File('assets/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final keys = source.keys.where((key) => !key.startsWith('@')).toSet();
      final placeholders = RegExp(r'\{([A-Za-z]\w*)(?:[,}])');
      for (final language in languageNames.keys) {
        final target =
            jsonDecode(File('assets/l10n/app_$language.arb').readAsStringSync())
                as Map<String, dynamic>;
        expect(
          target.keys.where((key) => !key.startsWith('@')).toSet(),
          keys,
          reason: language,
        );
        for (final key in keys) {
          expect(target[key], isA<String>(), reason: '$language:$key');
          expect(
            (target[key] as String).trim(),
            isNotEmpty,
            reason: '$language:$key',
          );
          Set<String?> arguments(String text) => placeholders
              .allMatches(text)
              .map((match) => match.group(1))
              .toSet();
          expect(
            arguments(target[key] as String),
            arguments(source[key] as String),
            reason: '$language:$key',
          );
        }
      }
    },
  );
}
