import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/food_model.dart';
import '../../../core/models/guide_models.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/services/guide_progress_service.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../nutrition/screens/food_lookup_screen.dart';
import 'guide_detail_screen.dart';

/// Cẩm nang tab: guides for the current app mode, grouped by category.
class GuidesScreen extends ConsumerWidget {
  /// Override the guide list (tests); defaults to the bundled content pack.
  final List<GuideArticle>? guides;

  /// Override the food pack behind the "Bầu ăn được không?" card (tests).
  final FoodPack? foodPack;

  const GuidesScreen({super.key, this.guides, this.foodPack});

  static GuideStage stageForMode(AppMode? mode) =>
      mode == AppMode.prePregnancy ? GuideStage.pre : GuideStage.pregnant;

  /// Guides for [stage] grouped by category (category enum order), each
  /// group keeping the content `order`.
  static Map<GuideCategory, List<GuideArticle>> groupForStage(
    List<GuideArticle> guides,
    GuideStage stage,
  ) {
    final grouped = <GuideCategory, List<GuideArticle>>{};
    for (final category in GuideCategory.values) {
      final items =
          guides
              .where((g) => g.stage == stage && g.category == category)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      if (items.isNotEmpty) grouped[category] = items;
    }
    // Groups follow the content `order` of their first guide, so authors
    // control which topics appear first.
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.value.first.order.compareTo(b.value.first.order));
    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = stageForMode(ref.watch(appModeProvider));
    final ticked = ref.watch(guideChecklistProvider);
    final grouped = groupForStage(guides ?? ContentPackService.guides, stage);
    final pack = foodPack ?? ContentPackService.foodPack;
    final foodCard = pack.isEmpty
        ? null
        : _FoodLookupEntryCard(pack: pack, count: pack.items.length);

    return Scaffold(
      appBar: AppBar(title: const Text('Cẩm nang')),
      body: grouped.isEmpty
          ? (foodCard == null
                ? const _EmptyGuides()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [foodCard, const _EmptyGuides()],
                  ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    stage == GuideStage.pre
                        ? 'Chuẩn bị mang thai'
                        : 'Hành trang khi mang thai',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ?foodCard,
                for (final entry in grouped.entries) ...[
                  SectionHeader(
                    title: GuideEnums.categoryLabel(entry.key),
                    padding: const EdgeInsets.only(
                      top: AppSpacing.lg,
                      bottom: AppSpacing.sm,
                    ),
                  ),
                  for (final guide in entry.value)
                    _GuideCard(guide: guide, ticked: ticked),
                ],
              ],
            ),
    );
  }
}

/// Entry to the "Bầu ăn được không?" lookup, shown above the guides.
class _FoodLookupEntryCard extends StatelessWidget {
  final FoodPack pack;
  final int count;

  const _FoodLookupEntryCard({required this.pack, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => FoodLookupScreen(pack: pack))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.restaurant_menu,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FoodLookupScreen.title,
                      style: AppCard.titleTextStyle(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tra cứu nhanh $count thực phẩm, món ăn',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final GuideArticle guide;
  final Set<String> ticked;

  const _GuideCard({required this.guide, required this.ticked});

  @override
  Widget build(BuildContext context) {
    final progress = guide.progress(ticked);
    final theme = Theme.of(context);
    final isWarning = guide.category == GuideCategory.warning;
    final variant = isWarning ? AppCardVariant.alert : AppCardVariant.standard;
    final fg = AppCardColors.of(context, variant).foreground;

    return AppCard(
      variant: variant,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => Navigator.of(context).push(
        AppMotion.detailRoute(context, (_) => GuideDetailScreen(guide: guide)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWarning) ...[
                Icon(Icons.warning_amber_rounded, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  guide.title,
                  style: AppCard.titleTextStyle(context)?.copyWith(color: fg),
                ),
              ),
              Icon(Icons.chevron_right, color: fg),
            ],
          ),
          if (guide.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              guide.summary,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
              // The warning summary says to call 115: never cut it.
              maxLines: isWarning ? null : 2,
              overflow: isWarning ? null : TextOverflow.ellipsis,
            ),
          ],
          // Only once the guide is started; an empty bar says nothing.
          if (progress != null && progress > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: AppProgressBar(value: progress)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(color: fg),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyGuides extends StatelessWidget {
  const _EmptyGuides();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Cẩm nang đang được cập nhật',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nội dung cho giai đoạn này sẽ sớm có trong bản cập nhật tiếp theo.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
