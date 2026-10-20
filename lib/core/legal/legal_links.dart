import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../language_registry.dart';

enum LegalDestination { privacy, terms, support }

Uri legalUri(LegalDestination destination, Locale locale) {
  final lang = normalizeLanguage(locale.languageCode);
  final slug = switch (destination) {
    LegalDestination.privacy => 'privacy',
    LegalDestination.terms => 'terms',
    LegalDestination.support => 'support',
  };
  return Uri.parse('https://cercaposta.it/legal/$slug.$lang.html');
}

Future<bool> openLegal(LegalDestination destination, Locale locale) =>
    launchUrl(
      legalUri(destination, locale),
      mode: LaunchMode.externalApplication,
    );
