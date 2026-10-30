import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

double hueDistance(Color a, Color b) {
  final d = (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs();
  return d > 180 ? 360 - d : d;
}

/// CIE76 colour difference in CIELAB (D65).
double deltaE(Color a, Color b) {
  List<double> lab(Color c) {
    double lin(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) * 1.0;
    final r = lin(c.r), g = lin(c.g), bl = lin(c.b);
    final x = (0.4124 * r + 0.3576 * g + 0.1805 * bl) / 0.95047;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * bl;
    final z = (0.0193 * r + 0.1192 * g + 0.9505 * bl) / 1.08883;
    double f(double t) =>
        t > 0.008856 ? math.pow(t, 1 / 3) * 1.0 : 7.787 * t + 16 / 116;
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
  }

  final p = lab(a), q = lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}

void main() {
  final themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};

  test('schemes keep the seed roles and pin only the brand roles', () {
    expect(AppTheme.seedColor, const Color(0xFFC92A68));
    for (final b in Brightness.values) {
      final seed = ColorScheme.fromSeed(
        seedColor: AppTheme.seedColor,
        brightness: b,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      );
      final actual = b == Brightness.light
          ? AppTheme.light().colorScheme
          : AppTheme.dark().colorScheme;
      expect(actual.secondary, seed.secondary);
      expect(actual.tertiary, seed.tertiary);
      expect(actual.outline, seed.outline);
      expect(actual.inverseSurface, seed.inverseSurface);
      // M3 error roles are kept.
      expect(actual.error, seed.error);
      expect(actual.onError, seed.onError);
      expect(actual.errorContainer, seed.errorContainer);
      expect(actual.onErrorContainer, seed.onErrorContainer);
    }
  });

  // Snapshot so a palette or generator change is deliberate.
  test('role snapshot', () {
    String roles(ColorScheme s) => [
      'primary ${hex(s.primary)}',
      'onPrimary ${hex(s.onPrimary)}',
      'primaryContainer ${hex(s.primaryContainer)}',
      'onPrimaryContainer ${hex(s.onPrimaryContainer)}',
      'secondaryContainer ${hex(s.secondaryContainer)}',
      'onSecondaryContainer ${hex(s.onSecondaryContainer)}',
      'tertiary ${hex(s.tertiary)}',
      'surface ${hex(s.surface)}',
      'onSurface ${hex(s.onSurface)}',
      'onSurfaceVariant ${hex(s.onSurfaceVariant)}',
      'surfaceContainerLow ${hex(s.surfaceContainerLow)}',
      'surfaceContainer ${hex(s.surfaceContainer)}',
      'surfaceContainerHigh ${hex(s.surfaceContainerHigh)}',
      'surfaceContainerHighest ${hex(s.surfaceContainerHighest)}',
      'outline ${hex(s.outline)}',
      'error ${hex(s.error)}',
      'onError ${hex(s.onError)}',
      'errorContainer ${hex(s.errorContainer)}',
    ].join(', ');
    expect(
      roles(AppTheme.light().colorScheme),
      'primary #C92A68, onPrimary #FFFFFF, primaryContainer #F78FB3, '
      'onPrimaryContainer #4F1730, secondaryContainer #FFD6E4, '
      'onSecondaryContainer #4F1730, tertiary #7B5733, surface #FFFFFF, '
      'onSurface #2B1A20, onSurfaceVariant #6B4F58, '
      'surfaceContainerLow #FFF4EC, surfaceContainer #FFF1E7, '
      'surfaceContainerHigh #FFEEE2, surfaceContainerHighest #FFEBDE, '
      'outline #847376, error #BA1A1A, onError #FFFFFF, '
      'errorContainer #FFDAD6',
    );
    expect(
      roles(AppTheme.dark().colorScheme),
      'primary #FF9FC2, onPrimary #4F1730, primaryContainer #7A2A50, '
      'onPrimaryContainer #FFE3EC, secondaryContainer #7A2A50, '
      'onSecondaryContainer #FFE3EC, tertiary #EDBD92, surface #1F1518, '
      'onSurface #F3E3E8, onSurfaceVariant #D4C0C6, '
      'surfaceContainerLow #2C2024, surfaceContainer #261D1F, '
      'surfaceContainerHigh #312829, surfaceContainerHighest #3C3234, '
      'outline #9E8C8F, error #FFB4AB, onError #690005, '
      'errorContainer #93000A',
    );
  });

  test('brand constants for exported images match the light scheme', () {
    final s = AppTheme.light().colorScheme;
    expect(AppBrandColors.primary, s.primary);
    expect(AppBrandColors.ink, s.onSurface);
    expect(AppBrandColors.inkSoft, s.onSurfaceVariant);
    expect(AppBrandColors.background, s.surface);
    expect(AppBrandColors.backgroundAccent, s.secondaryContainer);
  });

  // The milestone PNG: text and icons sit anywhere on the white-to-pink
  // gradient, so both ends must pass.
  test('milestone card colours are readable on both gradient ends', () {
    for (final bg in [
      AppBrandColors.background,
      AppBrandColors.backgroundAccent,
    ]) {
      expect(contrast(AppBrandColors.ink, bg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppBrandColors.inkSoft, bg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppBrandColors.primary, bg), greaterThanOrEqualTo(3.0));
    }
  });

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    group('$name theme', () {
      final s = theme.colorScheme;
      final sem = theme.extension<AppSemanticColors>()!;

      final textPairs = <String, (Color, Color)>{
        'primary/onPrimary': (s.primary, s.onPrimary),
        'primaryContainer/onPrimaryContainer': (
          s.primaryContainer,
          s.onPrimaryContainer,
        ),
        'secondaryContainer/onSecondaryContainer': (
          s.secondaryContainer,
          s.onSecondaryContainer,
        ),
        'tertiaryContainer/onTertiaryContainer': (
          s.tertiaryContainer,
          s.onTertiaryContainer,
        ),
        'errorContainer/onErrorContainer': (
          s.errorContainer,
          s.onErrorContainer,
        ),
        'error/onError': (s.error, s.onError),
        'surface/onSurface': (s.surface, s.onSurface),
        'surface/onSurfaceVariant': (s.surface, s.onSurfaceVariant),
        'surfaceContainerLow/onSurface': (s.surfaceContainerLow, s.onSurface),
        'surfaceContainerLow/onSurfaceVariant': (
          s.surfaceContainerLow,
          s.onSurfaceVariant,
        ),
        'surfaceContainer/onSurfaceVariant': (
          s.surfaceContainer,
          s.onSurfaceVariant,
        ),
        'surfaceContainerHigh/onSurfaceVariant': (
          s.surfaceContainerHigh,
          s.onSurfaceVariant,
        ),
        'surfaceContainerHighest/onSurfaceVariant': (
          s.surfaceContainerHighest,
          s.onSurfaceVariant,
        ),
        // Dialog, date and time picker buttons.
        'surfaceContainerHigh/primary': (s.surfaceContainerHigh, s.primary),
        'surfaceContainerHighest/primary': (
          s.surfaceContainerHighest,
          s.primary,
        ),
        'surface/primary (greeting)': (s.surface, s.primary),
        'inverseSurface/onInverseSurface': (
          s.inverseSurface,
          s.onInverseSurface,
        ),
        'inverseSurface/inversePrimary': (s.inverseSurface, s.inversePrimary),
        // In-range day text (onSurface) on the range band (P21-R2-01).
        'primaryContainer/onSurface (date range band)': (
          s.primaryContainer,
          s.onSurface,
        ),
        // Tinted tiles (secondaryContainer) with onSurface text.
        'secondaryContainer/onSurface': (s.secondaryContainer, s.onSurface),
        'success/onSuccess': (sem.success, sem.onSuccess),
        'successContainer/onSuccessContainer': (
          sem.successContainer,
          sem.onSuccessContainer,
        ),
        'warning/onWarning': (sem.warning, sem.onWarning),
        'warningContainer/onWarningContainer': (
          sem.warningContainer,
          sem.onWarningContainer,
        ),
        'info/onInfo': (sem.info, sem.onInfo),
        'infoContainer/onInfoContainer': (
          sem.infoContainer,
          sem.onInfoContainer,
        ),
        'danger/onDanger': (sem.danger, sem.onDanger),
        'dangerContainer/onDangerContainer': (
          sem.dangerContainer,
          sem.onDangerContainer,
        ),
        'peachContainer/onPeachContainer': (
          sem.peachContainer,
          sem.onPeachContainer,
        ),
        'mintContainer/onMintContainer': (
          sem.mintContainer,
          sem.onMintContainer,
        ),
        'emergency/onEmergency': (sem.emergency, sem.onEmergency),
        'emergencyContainer/onEmergencyContainer': (
          sem.emergencyContainer,
          sem.onEmergencyContainer,
        ),
        // Chips on the peach card use the theme's onSurface label.
        'peachContainer/onSurface': (sem.peachContainer, s.onSurface),
      };
      for (final MapEntry(key: pair, value: (bg, fg)) in textPairs.entries) {
        test('$pair >= 4.5:1', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      final graphicPairs = <String, (Color, Color)>{
        'outline vs surface': (s.outline, s.surface),
        'primary vs surface (icons)': (s.primary, s.surface),
        'error vs surface': (s.error, s.surface),
        'success vs surface': (sem.success, s.surface),
        'warning vs surface': (sem.warning, s.surface),
        'info vs surface': (sem.info, s.surface),
        'tertiary vs surface': (s.tertiary, s.surface),
      };
      for (final MapEntry(key: pair, value: (a, b)) in graphicPairs.entries) {
        test('$pair >= 3:1', () {
          expect(contrast(a, b), greaterThanOrEqualTo(3.0));
        });
      }

      // THEME-R1-01: emergency actions must never read as a pink button.
      test('emergency red is far from primary with white text', () {
        expect(deltaE(sem.emergency, s.primary), greaterThanOrEqualTo(40));
        expect(sem.onEmergency, const Color(0xFFFFFFFF));
        expect(
          contrast(sem.onEmergency, sem.emergency),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('the emergency banner is weaker than the emergency button', () {
        expect(
          contrast(sem.emergencyContainer, s.surface),
          lessThan(contrast(sem.emergency, s.surface)),
        );
      });

      // The bright pink brand sits closer to red than the old plum: the HSL
      // hue gap is only 23.4 deg in light (28.3 deg in dark; the old plum had 28.6 and
      // 31.8). Hue alone no longer
      // separates them, so the floor just locks the measured value and the
      // emergency surfaces use the dedicated emergency tokens instead. The M3
      // error role stays for destructive actions.
      test('error and primary stay distinct', () {
        expect(hueDistance(s.error, s.primary), greaterThanOrEqualTo(23));
        expect(deltaE(s.error, s.primary), greaterThanOrEqualTo(23));
      });

      test('danger tokens are the scheme error roles', () {
        expect(sem.danger, s.error);
        expect(sem.onDanger, s.onError);
        expect(sem.dangerContainer, s.errorContainer);
        expect(sem.onDangerContainer, s.onErrorContainer);
      });

      test('component themes use scheme roles', () {
        expect(theme.chipTheme.selectedColor, s.secondaryContainer);
        expect(theme.navigationBarTheme.indicatorColor, s.secondaryContainer);
        expect(theme.snackBarTheme.backgroundColor, s.inverseSurface);
        expect(theme.snackBarTheme.actionTextColor, s.inversePrimary);
        expect(
          theme.datePickerTheme.rangeSelectionBackgroundColor,
          s.primaryContainer,
        );
      });

      test('text theme is bundled Be Vietnam Pro', () {
        expect(theme.textTheme.bodyMedium!.fontFamily, AppTheme.fontFamily);
        expect(theme.textTheme.titleLarge!.fontFamily, AppTheme.fontFamily);
        expect(theme.textTheme.labelSmall!.fontSize, greaterThanOrEqualTo(12));
        expect(theme.textTheme.bodyMedium!.height, 1.5);
        expect(theme.textTheme.titleMedium!.height, 1.3);
      });

      // Phase 22.2b: charts and the cycle calendar draw on Card
      // (surfaceContainerLow).
      test('chart axis text >= 4.5:1 and series >= 3:1 on the card', () {
        final card = s.surfaceContainerLow;
        expect(
          contrast(s.onSurfaceVariant, card),
          greaterThanOrEqualTo(4.5),
          reason: 'axis labels',
        );
        expect(
          contrast(s.outline, card),
          greaterThanOrEqualTo(3.0),
          reason: 'axis lines',
        );
        final series = {
          'weight (primary)': s.primary,
          'systolic (danger)': sem.danger,
          'diastolic (info)': sem.info,
          'mood success': sem.success,
          'mood warning': sem.warning,
          'mood secondary': s.secondary,
          'mood tertiary': s.tertiary,
        };
        for (final MapEntry(key: label, value: color) in series.entries) {
          expect(
            contrast(color, card),
            greaterThanOrEqualTo(3.0),
            reason: label,
          );
        }
      });

      test('cycle calendar markers >= 3:1 on the card', () {
        final card = s.surfaceContainerLow;
        for (final MapEntry(key: label, value: color) in {
          'period (error)': s.error,
          'ovulation (primary)': s.primary,
          'fertile (tertiary)': s.tertiary,
        }.entries) {
          expect(
            contrast(color, card),
            greaterThanOrEqualTo(3.0),
            reason: label,
          );
        }
        // Today / selected day text on their circles.
        expect(
          contrast(s.onPrimaryContainer, s.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
      });

      test('pie slice labels are >= 4.5:1 on their tone', () {
        for (final (main, onMain) in [
          (sem.success, sem.onSuccess),
          (sem.warning, sem.onWarning),
          (sem.info, sem.onInfo),
          (sem.danger, sem.onDanger),
          (s.primary, s.onPrimary),
          (s.secondary, s.onSecondary),
          (s.tertiary, s.onTertiary),
        ]) {
          expect(contrast(onMain, main), greaterThanOrEqualTo(4.5));
        }
      });
    });
  }
}
