import 'package:flutter/material.dart';

/// Dense, curated theme matching the web ethos (tight rows, 13–14px type),
/// brand seed = the envelope green; clean light/dark.
class AppTheme {
  static const Color brandGreen = Color(0xFF3CAE7E);
  static const Color brandIndigo = Color(0xFF4F46E5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: brightness,
    ).copyWith(secondary: brandIndigo);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );
    return base.copyWith(
      visualDensity: VisualDensity.compact,
      textTheme: _denser(base.textTheme, 0.95),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 6,
        horizontalTitleGap: 10,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
      ),
      dividerTheme: const DividerThemeData(thickness: 0.6, space: 1),
    );
  }

  /// Scale the type ramp for a denser look. Unlike [TextTheme.apply], this only
  /// touches styles whose [TextStyle.fontSize] is non-null: on some Flutter
  /// versions the default M3 text theme carries styles with a null fontSize,
  /// and `apply(fontSizeFactor:)` asserts on those (red screen at startup).
  static TextTheme _denser(TextTheme t, double factor) {
    TextStyle? s(TextStyle? style) => style?.fontSize == null
        ? style
        : style!.copyWith(fontSize: style.fontSize! * factor);
    return t.copyWith(
      displayLarge: s(t.displayLarge),
      displayMedium: s(t.displayMedium),
      displaySmall: s(t.displaySmall),
      headlineLarge: s(t.headlineLarge),
      headlineMedium: s(t.headlineMedium),
      headlineSmall: s(t.headlineSmall),
      titleLarge: s(t.titleLarge),
      titleMedium: s(t.titleMedium),
      titleSmall: s(t.titleSmall),
      bodyLarge: s(t.bodyLarge),
      bodyMedium: s(t.bodyMedium),
      bodySmall: s(t.bodySmall),
      labelLarge: s(t.labelLarge),
      labelMedium: s(t.labelMedium),
      labelSmall: s(t.labelSmall),
    );
  }
}
