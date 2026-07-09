import 'package:cercaposta/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the startup red-screen crash: the dense type ramp was
/// built with `textTheme.apply(fontSizeFactor: 0.95)`, and on Flutter 3.32 the
/// default M3 text theme carries styles whose `fontSize` is null, which makes
/// `TextStyle.apply` assert. That assert fired while building the theme, so the
/// app died on its very first frame. These tests must keep failing if anyone
/// reintroduces an unguarded factor apply.
void main() {
  test('AppTheme.light()/dark() build without asserting', () {
    expect(AppTheme.light, returnsNormally);
    expect(AppTheme.dark, returnsNormally);
  });

  for (final brightness in const ['light', 'dark']) {
    testWidgets('every text style renders under the $brightness theme', (
      tester,
    ) async {
      final theme = brightness == 'light' ? AppTheme.light() : AppTheme.dark();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              final t = Theme.of(context).textTheme;
              final styles = <TextStyle?>[
                t.displayLarge,
                t.displayMedium,
                t.displaySmall,
                t.headlineLarge,
                t.headlineMedium,
                t.headlineSmall,
                t.titleLarge,
                t.titleMedium,
                t.titleSmall,
                t.bodyLarge,
                t.bodyMedium,
                t.bodySmall,
                t.labelLarge,
                t.labelMedium,
                t.labelSmall,
              ];
              // A ListView (not a Column) so 15 lines never overflow the test
              // surface and trip an unrelated layout exception.
              return Scaffold(
                body: ListView(
                  children: [for (final s in styles) Text('Aa', style: s)],
                ),
              );
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
