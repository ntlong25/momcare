import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/theme/app_theme.dart';

void main() {
  Map<String, TextStyle?> styles(TextTheme t) => {
    'displayLarge': t.displayLarge,
    'displayMedium': t.displayMedium,
    'displaySmall': t.displaySmall,
    'headlineLarge': t.headlineLarge,
    'headlineMedium': t.headlineMedium,
    'headlineSmall': t.headlineSmall,
    'titleLarge': t.titleLarge,
    'titleMedium': t.titleMedium,
    'titleSmall': t.titleSmall,
    'bodyLarge': t.bodyLarge,
    'bodyMedium': t.bodyMedium,
    'bodySmall': t.bodySmall,
    'labelLarge': t.labelLarge,
    'labelMedium': t.labelMedium,
    'labelSmall': t.labelSmall,
  };

  test('light and dark share one type scale', () {
    final light = styles(AppTheme.light().textTheme);
    final dark = styles(AppTheme.dark().textTheme);
    for (final name in light.keys) {
      expect(dark[name]?.fontSize, light[name]?.fontSize, reason: name);
      expect(dark[name]?.fontWeight, light[name]?.fontWeight, reason: name);
      expect(dark[name]?.height, light[name]?.height, reason: name);
      expect(
        dark[name]?.letterSpacing,
        light[name]?.letterSpacing,
        reason: name,
      );
      expect(dark[name]?.fontFamily, light[name]?.fontFamily, reason: name);
    }
  });

  for (final style in ['appBar', 'navigationBar', 'chip', 'button']) {
    test('component text matches between themes: $style', () {
      TextStyle? pick(ThemeData t) => switch (style) {
        'appBar' => t.appBarTheme.titleTextStyle,
        'navigationBar' => t.navigationBarTheme.labelTextStyle?.resolve({}),
        'chip' => t.chipTheme.labelStyle,
        _ => t.filledButtonTheme.style?.textStyle?.resolve({}),
      };
      final light = pick(AppTheme.light());
      final dark = pick(AppTheme.dark());
      expect(dark?.fontSize, light?.fontSize);
      expect(dark?.fontWeight, light?.fontWeight);
    });
  }
}
