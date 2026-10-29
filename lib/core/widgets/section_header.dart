import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Title above a group of cards, with an optional trailing action
/// (e.g. "Xem tất cả"). The title wraps instead of overflowing.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
