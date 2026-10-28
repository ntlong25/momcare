import 'package:flutter/material.dart';

/// Tinted chip colours that keep readable contrast in light and dark mode.
class ChipColors {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color positiveBackground(BuildContext context) => _isDark(context)
      ? Colors.green.withValues(alpha: 0.28)
      : Colors.green.withValues(alpha: 0.1);

  static Color positiveText(BuildContext context) =>
      _isDark(context) ? Colors.green.shade100 : Colors.green.shade800;

  static Color negativeBackground(BuildContext context) => _isDark(context)
      ? Colors.red.withValues(alpha: 0.28)
      : Colors.red.withValues(alpha: 0.1);

  static Color negativeText(BuildContext context) =>
      _isDark(context) ? Colors.red.shade100 : Colors.red.shade800;
}
