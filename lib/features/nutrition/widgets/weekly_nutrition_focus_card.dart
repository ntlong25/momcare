import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/week_detail_model.dart';
import '../../references/widgets/draft_content_note.dart';

/// "Dinh dưỡng tuần X": the `nutritionFocus` lines of the week page.
/// Hidden when [week] is null or the week has no focus lines.
class WeeklyNutritionFocusCard extends StatelessWidget {
  final int? week;

  /// Override the week pages (tests); defaults to `weeks_v2.json`.
  final Map<int, WeekDetail>? details;

  const WeeklyNutritionFocusCard({super.key, required this.week, this.details});

  static String titleFor(int week) =>
      week <= 0 ? 'Dinh dưỡng khi chuẩn bị mang thai' : 'Dinh dưỡng tuần $week';

  @override
  Widget build(BuildContext context) {
    final week = this.week;
    if (week == null) return const SizedBox.shrink();
    final detail = ContentPackService.resolveWeekDetail(
      week,
      details ?? ContentPackService.weekDetails,
    );
    final focus = detail.nutritionFocus
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (focus.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titleFor(detail.week),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in focus)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
            if (detail.isDraft) ...[
              const SizedBox(height: 6),
              const DraftContentNote(),
            ],
          ],
        ),
      ),
    );
  }
}
