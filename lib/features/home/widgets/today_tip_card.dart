import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/daily_item_model.dart';
import '../../../core/theme/app_tokens.dart';
import '../../references/widgets/draft_content_note.dart';
import '../../../core/widgets/app_card.dart';

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
    final fg = AppTone.mint.of(context).onContainer;

    return AppCard(
      variant: AppCardVariant.mint,
      icon: Icons.lightbulb_outline,
      title: 'Gợi ý hôm nay',
      titleStyle: theme.textTheme.titleLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: 4),
          Text(
            item.body,
            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
          ),
          if (source.isDraft) ...[
            const SizedBox(height: 12),
            const DraftContentNote(),
          ],
        ],
      ),
    );
  }
}
