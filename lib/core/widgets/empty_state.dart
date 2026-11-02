import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Empty list/result placeholder: an icon in `onSurfaceVariant`, a title,
/// an optional one-sentence message and an optional action button.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Icon size; smaller inside cards and history lists.
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool _inline;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconSize = 64,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  }) : _inline = false;

  /// Compact variant for empty sections inside a screen (history lists).
  const AppEmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconSize = 40,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  }) : _inline = false;

  /// One-line variant for a card in a busy screen: icon and title, with
  /// the action at the end. The action wraps below at large text sizes.
  const AppEmptyState.inline({
    super.key,
    required this.icon,
    required this.title,
    required Widget this.action,
  }) : message = null,
       iconSize = 24,
       padding = EdgeInsets.zero,
       _inline = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_inline) {
      return SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            ?action,
          ],
        ),
      );
    }
    // Fill the available width (e.g. a full-width card that lays out its
    // child start-aligned) and centre the content in it; shrink-wrap when
    // the width is unbounded.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
