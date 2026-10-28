import 'package:flutter/material.dart';

import '../../../core/models/pregnancy_model.dart';

/// "Ngày X/280" counter at the top of the Hôm nay tab.
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_outlined, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    overdue
                        ? 'Ngày $day'
                        : 'Ngày $day/${PregnancyModel.gestationDays}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tuần $week · ngày $dayOfWeek',
              style: theme.textTheme.bodyLarge,
            ),
            if (overdue) ...[
              const SizedBox(height: 4),
              Text(
                'Đã qua ngày dự sinh',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
