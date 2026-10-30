import 'package:flutter/material.dart';

import '../../../core/models/food_model.dart';
import '../../../core/theme/app_tokens.dart';

/// UI colour family of a [FoodVerdict]: ok = success, limit = warning,
/// avoid = danger (semantic tokens, readable in light and dark).
extension FoodVerdictTone on FoodVerdict {
  AppTone get tone {
    switch (this) {
      case FoodVerdict.ok:
        return AppTone.success;
      case FoodVerdict.limit:
        return AppTone.warning;
      case FoodVerdict.avoid:
        return AppTone.danger;
    }
  }
}

/// Verdict pill with icon and text (never colour alone).
class FoodVerdictBadge extends StatelessWidget {
  final FoodVerdict verdict;

  const FoodVerdictBadge({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final colors = verdict.tone.of(context);
    final foreground = colors.onContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verdict.icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            verdict.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
