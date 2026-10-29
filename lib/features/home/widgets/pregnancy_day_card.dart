import 'package:flutter/material.dart';

import '../../../core/models/pregnancy_model.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';

/// Hero "Ngày X/280" counter at the top of the Hôm nay tab, with the week,
/// the time left until the due date and a progress bar.
class PregnancyDayCard extends StatelessWidget {
  final PregnancyModel pregnancy;

  /// Overrides "now" (tests only).
  final DateTime? now;

  const PregnancyDayCard({super.key, required this.pregnancy, this.now});

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final rawDay = pregnancy.pregnancyDayAt(today);
    final day = rawDay < 1 ? 1 : rawDay;
    final overdue = day > PregnancyModel.gestationDays;
    final week = pregnancy.currentWeekAt(today);
    final dayOfWeek = (day - 1) % 7 + 1;
    final progress = (day / PregnancyModel.gestationDays).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onPrimaryContainer;

    return AppCard(
      variant: AppCardVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_outlined, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  overdue
                      ? 'Ngày $day'
                      : 'Ngày $day/${PregnancyModel.gestationDays}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tuần $week · ngày $dayOfWeek',
            style: theme.textTheme.bodyLarge?.copyWith(color: fg),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormatter.formatDaysRemaining(pregnancy.daysUntilDueAt(today)),
            key: const ValueKey('pregnancy-day-remaining'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg,
              fontWeight: overdue ? FontWeight.w600 : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: scheme.primary,
              backgroundColor: scheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}
