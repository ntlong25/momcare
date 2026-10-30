import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/guide_models.dart';
import '../../../core/models/pre_readiness.dart';
import '../../../core/services/guide_progress_service.dart';
import '../../guides/screens/guide_detail_screen.dart';
import '../../references/widgets/draft_content_note.dart';
import '../screens/main_navigation.dart';
import '../../../core/widgets/app_card.dart';

/// "Sẵn sàng mang thai": checklist progress across the pre-pregnancy guides
/// with up to three guides to continue (A1). Hidden when no pre guide tracks
/// progress.
class PreReadinessCard extends ConsumerWidget {
  /// Cẩm nang tab index in [MainNavigation].
  static const int guidesTabIndex = 2;

  /// Overrides the loaded guides (tests); defaults to the content pack.
  final List<GuideArticle>? guides;

  const PreReadinessCard({super.key, this.guides});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticked = ref.watch(guideChecklistProvider);
    final readiness = PreReadiness.compute(
      guides ?? ContentPackService.guides,
      ticked,
    );
    if (readiness.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      key: const ValueKey('pre-readiness-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sẵn sàng mang thai',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('pre-readiness-see-all'),
                onPressed: () =>
                    ref.read(navigationIndexProvider.notifier).state =
                        guidesTabIndex,
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: readiness.ratio,
              minHeight: 8,
              color: theme.colorScheme.tertiary,
              backgroundColor: theme.colorScheme.tertiaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${readiness.done}/${readiness.total} việc · ${readiness.percent}%',
            style: theme.textTheme.labelLarge,
          ),
          if (readiness.isComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành danh sách chuẩn bị. Bạn có thể xem lại '
              'cẩm nang bất cứ lúc nào.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ] else ...[
            const SizedBox(height: 4),
            for (final entry in readiness.nextUp)
              _NextUpRow(entry: entry, muted: muted),
          ],
          if (readiness.isDraft) ...[
            const SizedBox(height: 8),
            const DraftContentNote(),
          ],
        ],
      ),
    );
  }
}

class _NextUpRow extends StatelessWidget {
  final PreReadinessEntry entry;
  final Color muted;

  const _NextUpRow({required this.entry, required this.muted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('pre-readiness-row-${entry.guide.id}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuideDetailScreen(guide: entry.guide),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.radio_button_unchecked,
              size: 18,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.guide.title,
                style: theme.textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.done}/${entry.total}',
              style: theme.textTheme.labelMedium?.copyWith(color: muted),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}
