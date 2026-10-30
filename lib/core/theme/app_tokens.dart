import 'package:flutter/material.dart';

/// Spacing scale (dp). Use these instead of ad-hoc paddings.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Bottom padding for scrollables under a (extended) FAB: FAB height 56
  /// + 2 x [kFloatingActionButtonMargin], so the last item can scroll clear
  /// of the button.
  static const double fabClearance = 88;

  /// Standard 16 dp page padding with [fabClearance] at the bottom.
  static const EdgeInsets fabPagePadding = EdgeInsets.fromLTRB(
    lg,
    lg,
    lg,
    fabClearance,
  );
}

/// Corner radius scale (dp).
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
}

/// Fixed light palette for exported images (the shareable milestone card
/// PNG). Exported images are not themed, so they cannot read the
/// [ColorScheme]. Values are the light roles generated from
/// `AppTheme.seedColor` (checked by `test/theme_contrast_test.dart`).
class AppBrandColors {
  const AppBrandColors._();

  /// Light `primary` generated from the seed.
  static const Color primary = Color(0xFF894A68);

  /// Light `onSurface` generated from the seed.
  static const Color ink = Color(0xFF21191C);

  /// Light `onSurfaceVariant` generated from the seed.
  static const Color inkSoft = Color(0xFF504348);

  /// Light `surfaceContainerLow` generated from the seed (card gradient
  /// start).
  static const Color background = Color(0xFFFFF0F4);

  /// Light `primaryContainer` generated from the seed (card gradient end).
  static const Color backgroundAccent = Color(0xFFFFD8E6);

  /// Launcher icon glyph colour (white on [primary]), see
  /// `assets/branding/app_icon_foreground.svg`. Used by the in-app splash
  /// mark so it matches the Android 12 system splash icon.
  static const Color onPrimary = Color(0xFFFFFFFF);
}

/// Status colours the [ColorScheme] does not have: success, warning, info
/// and danger, each with an on-colour, a container and an on-container
/// colour. Every pair keeps >= 4.5:1 contrast in its theme (see
/// `test/theme_contrast_test.dart`). Danger is the scheme's error roles.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  /// Light-theme tokens; danger comes from [scheme]'s error roles.
  factory AppSemanticColors.light(ColorScheme scheme) => AppSemanticColors(
    success: const Color(0xFF2E6B30),
    onSuccess: const Color(0xFFFFFFFF),
    successContainer: const Color(0xFFC8EBC4),
    onSuccessContainer: const Color(0xFF0A2E0D),
    warning: const Color(0xFF7A5900),
    onWarning: const Color(0xFFFFFFFF),
    warningContainer: const Color(0xFFFFE08A),
    onWarningContainer: const Color(0xFF261A00),
    info: const Color(0xFF1F5FA8),
    onInfo: const Color(0xFFFFFFFF),
    infoContainer: const Color(0xFFD5E3FF),
    onInfoContainer: const Color(0xFF001B3C),
    danger: scheme.error,
    onDanger: scheme.onError,
    dangerContainer: scheme.errorContainer,
    onDangerContainer: scheme.onErrorContainer,
  );

  /// Dark-theme tokens; danger comes from [scheme]'s error roles.
  factory AppSemanticColors.dark(ColorScheme scheme) => AppSemanticColors(
    success: const Color(0xFF8FD68C),
    onSuccess: const Color(0xFF003A07),
    successContainer: const Color(0xFF1E5221),
    onSuccessContainer: const Color(0xFFC8EBC4),
    warning: const Color(0xFFF2BF48),
    onWarning: const Color(0xFF3F2E00),
    warningContainer: const Color(0xFF5B4300),
    onWarningContainer: const Color(0xFFFFDF9E),
    info: const Color(0xFFA8C8FF),
    onInfo: const Color(0xFF003060),
    infoContainer: const Color(0xFF1A4A80),
    onInfoContainer: const Color(0xFFD5E3FF),
    danger: scheme.error,
    onDanger: scheme.onError,
    dangerContainer: scheme.errorContainer,
    onDangerContainer: scheme.onErrorContainer,
  );

  /// Tokens matching [scheme]'s brightness.
  factory AppSemanticColors.of(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark
      ? AppSemanticColors.dark(scheme)
      : AppSemanticColors.light(scheme);

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      onInfo: l(onInfo, other.onInfo),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
    );
  }
}

/// `context.semantic` reads the [AppSemanticColors] of the current theme.
/// Falls back to tokens built from the current [ColorScheme] when a theme
/// without the extension is in use (e.g. some widget tests).
extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semantic {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        AppSemanticColors.of(theme.colorScheme);
  }
}

/// A colour family for accent icons, badges and tinted tiles. Each tone
/// resolves to a main colour (icons/text on the surface), its on-colour,
/// and a container with its on-container colour, all from the
/// [ColorScheme] or [AppSemanticColors] of the current theme.
enum AppTone { primary, secondary, tertiary, success, warning, info, danger }

/// The resolved colours of an [AppTone].
@immutable
class AppToneColors {
  final Color main;
  final Color onMain;
  final Color container;
  final Color onContainer;

  const AppToneColors({
    required this.main,
    required this.onMain,
    required this.container,
    required this.onContainer,
  });
}

extension AppToneResolve on AppTone {
  /// Colours of this tone in the theme of [context].
  AppToneColors of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = context.semantic;
    switch (this) {
      case AppTone.primary:
        return AppToneColors(
          main: scheme.primary,
          onMain: scheme.onPrimary,
          container: scheme.primaryContainer,
          onContainer: scheme.onPrimaryContainer,
        );
      case AppTone.secondary:
        return AppToneColors(
          main: scheme.secondary,
          onMain: scheme.onSecondary,
          container: scheme.secondaryContainer,
          onContainer: scheme.onSecondaryContainer,
        );
      case AppTone.tertiary:
        return AppToneColors(
          main: scheme.tertiary,
          onMain: scheme.onTertiary,
          container: scheme.tertiaryContainer,
          onContainer: scheme.onTertiaryContainer,
        );
      case AppTone.success:
        return AppToneColors(
          main: s.success,
          onMain: s.onSuccess,
          container: s.successContainer,
          onContainer: s.onSuccessContainer,
        );
      case AppTone.warning:
        return AppToneColors(
          main: s.warning,
          onMain: s.onWarning,
          container: s.warningContainer,
          onContainer: s.onWarningContainer,
        );
      case AppTone.info:
        return AppToneColors(
          main: s.info,
          onMain: s.onInfo,
          container: s.infoContainer,
          onContainer: s.onInfoContainer,
        );
      case AppTone.danger:
        return AppToneColors(
          main: s.danger,
          onMain: s.onDanger,
          container: s.dangerContainer,
          onContainer: s.onDangerContainer,
        );
    }
  }
}

/// `theme.semantic` reads the [AppSemanticColors] of a [ThemeData], for
/// helpers that take a theme instead of a [BuildContext].
extension AppSemanticColorsTheme on ThemeData {
  AppSemanticColors get semantic =>
      extension<AppSemanticColors>() ?? AppSemanticColors.of(colorScheme);
}
