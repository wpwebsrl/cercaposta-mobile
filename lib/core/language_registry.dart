// Public language contract: assets/l10n/languages.json. Keep native labels neutral.
const languageNames = <String, String>{
  'it': 'Italiano',
  'en': 'English',
  'es': 'Español',
};
const defaultLanguage = 'it';

String normalizeLanguage(String? value) {
  final code = (value ?? '')
      .trim()
      .replaceAll('_', '-')
      .split('-')
      .first
      .toLowerCase();
  return languageNames.containsKey(code) ? code : defaultLanguage;
}
