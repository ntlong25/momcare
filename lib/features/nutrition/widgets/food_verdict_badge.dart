import 'package:flutter/material.dart';

import '../../../core/models/food_model.dart';

/// Verdict pill with icon and text (never colour alone).
class FoodVerdictBadge extends StatelessWidget {
  final FoodVerdict verdict;

  const FoodVerdictBadge({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final foreground = verdict.colorFor(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verdict.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.6)),
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
