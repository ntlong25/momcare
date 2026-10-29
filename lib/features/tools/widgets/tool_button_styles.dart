import 'package:flutter/material.dart';

/// Shared button styles of the counter tools, so the kick counter and the
/// contraction timer look the same.
class ToolButtonStyles {
  const ToolButtonStyles._();

  /// Size of the secondary session actions ("Hoàn tác", "Kết thúc"); both
  /// use it so they always have the same height.
  static const Size secondaryMinSize = Size(120, 48);

  /// Full-width main action ("Bắt đầu đếm", "Bắt đầu cơn co"). [danger]
  /// switches to the error roles (active "Kết thúc cơn co").
  static ButtonStyle mainAction(BuildContext context, {bool danger = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(64),
      backgroundColor: danger ? scheme.error : scheme.primary,
      foregroundColor: danger ? scheme.onError : scheme.onPrimary,
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// "Hoàn tác" (outlined).
  static ButtonStyle secondaryOutlined() =>
      OutlinedButton.styleFrom(minimumSize: secondaryMinSize);

  /// "Kết thúc" (tonal: secondaryContainer / onSecondaryContainer).
  static ButtonStyle secondaryTonal() =>
      FilledButton.styleFrom(minimumSize: secondaryMinSize);
}
