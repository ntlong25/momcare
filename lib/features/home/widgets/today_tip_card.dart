import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/daily_item_model.dart';
import '../../references/widgets/draft_content_note.dart';

/// "Gợi ý hôm nay": the daily tip for content [day]; hidden when the tips
/// pack has no item.
class TodayTipCard extends StatelessWidget {
  final int day;

  /// Overrides the loaded pack (tests only).
  final DailyPack? pack;

  const TodayTipCard({super.key, required this.day, this.pack});

  @override
  Widget build(BuildContext context) {
    final source = pack ?? ContentPackService.dailyTipsPack;
    final item = source.itemForDay(day);
    if (item == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gợi ý hôm nay',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.body, style: theme.textTheme.bodyMedium),
            if (source.isDraft) ...[
              const SizedBox(height: 12),
              const DraftContentNote(),
            ],
          ],
        ),
      ),
    );
  }
}
