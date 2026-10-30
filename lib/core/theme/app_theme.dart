import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// MomCare+ theme: light and dark [ColorScheme]s generated from one seed with
/// [DynamicSchemeVariant.tonalSpot], the brand roles pinned on top (white
/// page, bright pink blocks, warm cards), and component themes that read
/// only scheme roles. Typography is the bundled Be Vietnam Pro on the
/// Material 3 type scale.
class AppTheme {
  const AppTheme._();

  /// Bright pink brand colour; also the light `primary` and the launcher
  /// icon background (`AppBrandColors.primary`).
  static const Color seedColor = Color(0xFFC92A68);

  /// Bundled app font family (see `flutter: fonts:` in pubspec.yaml).
  static const String fontFamily = 'BeVietnamPro';

  static final ColorScheme lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      ).copyWith(
        primary: seedColor,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFF78FB3),
        onPrimaryContainer: const Color(0xFF4F1730),
        secondaryContainer: const Color(0xFFFFD6E4),
        onSecondaryContainer: const Color(0xFF4F1730),
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF2B1A20),
        onSurfaceVariant: const Color(0xFF6B4F58),
        surfaceContainerLow: const Color(0xFFFFF4EC),
        // Warm steps, light enough for `primary` text (dialog buttons) at 4.5:1.
        surfaceContainer: const Color(0xFFFFF1E7),
        surfaceContainerHigh: const Color(0xFFFFEEE2),
        surfaceContainerHighest: const Color(0xFFFFEBDE),
      );

  static final ColorScheme darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      ).copyWith(
        primary: const Color(0xFFFF9FC2),
        onPrimary: const Color(0xFF4F1730),
        primaryContainer: const Color(0xFF7A2A50),
        onPrimaryContainer: const Color(0xFFFFE3EC),
        secondaryContainer: const Color(0xFF7A2A50),
        onSecondaryContainer: const Color(0xFFFFE3EC),
        surface: const Color(0xFF1F1518),
        onSurface: const Color(0xFFF3E3E8),
        onSurfaceVariant: const Color(0xFFD4C0C6),
        surfaceContainerLow: const Color(0xFF2C2024),
      );

  static final ThemeData _light = _build(lightColorScheme);
  static final ThemeData _dark = _build(darkColorScheme);

  static ThemeData light() => _light;
  static ThemeData dark() => _dark;

  /// Legacy getters kept for existing call sites.
  static ThemeData get lightTheme => _light;
  static ThemeData get darkTheme => _dark;

  static TextTheme _textTheme(TextTheme base) {
    TextStyle? h(TextStyle? s, double height) =>
        s?.copyWith(height: height, fontFamily: fontFamily);
    return base.copyWith(
      displayLarge: h(base.displayLarge, 1.3),
      displayMedium: h(base.displayMedium, 1.3),
      displaySmall: h(base.displaySmall, 1.3),
      headlineLarge: h(base.headlineLarge, 1.3),
      headlineMedium: h(base.headlineMedium, 1.3),
      headlineSmall: h(base.headlineSmall, 1.3),
      titleLarge: h(base.titleLarge, 1.3),
      titleMedium: h(base.titleMedium, 1.3),
      titleSmall: h(base.titleSmall, 1.3),
      bodyLarge: h(base.bodyLarge, 1.5),
      bodyMedium: h(base.bodyMedium, 1.5),
      bodySmall: h(base.bodySmall, 1.5),
      labelLarge: h(base.labelLarge, 1.3),
      labelMedium: h(base.labelMedium, 1.3),
      // Minimum on-screen size 12 sp.
      labelSmall: h(base.labelSmall, 1.3)?.copyWith(fontSize: 12),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final text = _textTheme(base.textTheme);
    const buttonMinSize = Size(64, 48);
    const stadium = StadiumBorder();
    final buttonText = text.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final disabledFg = scheme.onSurface.withValues(alpha: 0.38);
    final disabledBg = scheme.onSurface.withValues(alpha: 0.12);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: text,
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      extensions: [AppSemanticColors.of(scheme)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: stadium,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              minimumSize: buttonMinSize,
              shape: stadium,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              textStyle: buttonText,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? disabledBg
                      : states.contains(WidgetState.focused)
                      ? scheme.primary
                      : scheme.outline,
                ),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: buttonMinSize,
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      // ElevatedButton is mapped to the tonal look.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledFg,
          elevation: 0,
          minimumSize: buttonMinSize,
          shape: stadium,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: buttonText,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.secondaryContainer
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? disabledFg
                : states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
        deleteIconColor: scheme.onSurfaceVariant,
        labelStyle: text.labelLarge,
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: scheme.secondaryContainer)
              : states.contains(WidgetState.disabled)
              ? BorderSide(color: disabledBg)
              : BorderSide(color: scheme.outline),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            // No extra tracking, so "Cẩm nang" fits one line on 360 dp.
            letterSpacing: 0,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: text.titleSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        closeIconColor: scheme.onInverseSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.secondary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: scheme.surfaceContainerHigh,
        headerForegroundColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : states.contains(WidgetState.disabled)
              ? disabledFg
              : scheme.onSurface,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : states.contains(WidgetState.disabled)
              ? disabledFg
              : scheme.primary,
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        todayBorder: BorderSide(color: scheme.primary),
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : states.contains(WidgetState.disabled)
              ? disabledFg
              : scheme.onSurfaceVariant,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
        weekdayStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
        rangePickerBackgroundColor: scheme.surface,
        rangePickerSurfaceTintColor: Colors.transparent,
        rangePickerHeaderBackgroundColor: scheme.surface,
        rangePickerHeaderForegroundColor: scheme.onSurfaceVariant,
        rangePickerShape: const RoundedRectangleBorder(),
        // In-range days are drawn with the body text colour (onSurface),
        // which keeps >= 4.5:1 on primaryContainer in both themes.
        rangeSelectionBackgroundColor: scheme.primaryContainer,
        dividerColor: scheme.outlineVariant,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        dialBackgroundColor: scheme.surfaceContainerHighest,
        dialHandColor: scheme.primary,
        dialTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurface,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurface,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.secondaryContainer
              : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
        dayPeriodBorderSide: BorderSide(color: scheme.outline),
        entryModeIconColor: scheme.onSurfaceVariant,
        helpTextStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? null
              : states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? null
              : states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : states.contains(WidgetState.disabled)
              ? null
              : scheme.outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.secondaryContainer,
        circularTrackColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 3,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
