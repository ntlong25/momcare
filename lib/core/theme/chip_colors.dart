import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Tinted chip colours from the semantic tokens; every pair keeps >= 4.5:1
/// contrast in light and dark mode.
class ChipColors {
  static Color positiveBackground(BuildContext context) =>
      context.semantic.successContainer;

  static Color positiveText(BuildContext context) =>
      context.semantic.onSuccessContainer;

  static Color negativeBackground(BuildContext context) =>
      context.semantic.dangerContainer;

  static Color negativeText(BuildContext context) =>
      context.semantic.onDangerContainer;
}
