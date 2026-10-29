import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/services/health_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../fertility/screens/add_period_screen.dart';
import '../../guides/screens/guide_detail_screen.dart';
import 'pregnant_switch_card.dart';

/// Guide opened from the late-period and early-signs cards.
const String earlySignsGuideId = 'pre_early_signs';

void _openEarlySigns(BuildContext context) {
  final guide = ContentPackService.guideById(earlySignsGuideId);
  if (guide == null) return;
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => GuideDetailScreen(guide: guide)));
}

/// Late-period estimate on the pre-pregnancy Hôm nay (A2). Shown only when
/// cycles exist and the expected period is at least one day past; when the
/// last recorded period is too old it asks the user to update their data
/// instead. Wording stays an estimate, never a diagnosis.
class LatePeriodCard extends ConsumerWidget {
  final List<MenstrualCycleModel> cycles;
  final DateTime today;

  const LatePeriodCard({super.key, required this.cycles, required this.today});

  /// Whether the card renders for [cycles] on [today].
  static bool isVisible(List<MenstrualCycleModel> cycles, DateTime today) =>
      cycles.isNotEmpty && HealthService.daysLate(cycles, today: today) >= 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible(cycles, today)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final stale = HealthService.isCycleDataStale(cycles, today: today);
    final hasGuide = ContentPackService.guideById(earlySignsGuideId) != null;

    Widget addPeriodButton() => OutlinedButton.icon(
      key: const ValueKey('late-period-add'),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AddPeriodScreen())),
      icon: const Icon(Icons.add),
      label: const Text('Ghi kỳ kinh mới'),
    );

    if (stale) {
      return Card(
        key: const ValueKey('late-period-card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(theme, Icons.update, 'Đã lâu bạn chưa ghi kỳ kinh mới'),
              const SizedBox(height: 8),
              Text(
                'Hãy cập nhật ngày bắt đầu kỳ kinh gần nhất để MomCare+ '
                'ước tính chu kỳ chính xác hơn.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: addPeriodButton()),
            ],
          ),
        ),
      );
    }

    final late = HealthService.daysLate(cycles, today: today);
    final expected = HealthService.expectedPeriodDate(cycles)!;
    final average = HealthService.calculateAverageCycleLength(cycles);
    final regularity = HealthService.cycleRegularity(cycles);

    return Card(
      key: const ValueKey('late-period-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              theme,
              Icons.event_busy,
              'Trễ kinh $late ngày → có thể thử thai',
            ),
            const SizedBox(height: 8),
            Text(
              'Kỳ kinh dự kiến: ${DateFormatter.formatDate(expected)} '
              '(theo chu kỳ trung bình $average ngày)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Đây chỉ là ước tính từ dữ liệu bạn đã ghi. Chu kỳ có thể '
              'thay đổi vì nhiều lý do; nếu chưa chắc, bạn có thể thử thai '
              'hoặc hỏi bác sĩ.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            if (regularity != CycleRegularity.regular) ...[
              const SizedBox(height: 6),
              Text(
                regularity == CycleRegularity.irregular
                    ? 'Chu kỳ của bạn chưa đều nên ngày dự kiến có thể lệch '
                          'nhiều hơn.'
                    : 'Chưa đủ dữ liệu chu kỳ nên ngày dự kiến có thể lệch '
                          'nhiều hơn. Ghi thêm kỳ kinh giúp ước tính tốt hơn.',
                key: const ValueKey('late-period-regularity-note'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
            const SizedBox(height: 12),
            if (hasGuide) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('late-period-guide'),
                  onPressed: () => _openEarlySigns(context),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Xem dấu hiệu & cách thử thai'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('late-period-pregnant'),
                  onPressed: () => confirmAndSwitchToPregnancy(context, ref),
                  icon: const Icon(Icons.pregnant_woman),
                  label: const Text('Tôi đã có thai'),
                ),
                addPeriodButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Always-visible "Dấu hiệu mang thai sớm" entry (A3); hidden when the
/// early-signs guide is not loaded.
class EarlySignsEntryCard extends StatelessWidget {
  const EarlySignsEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final guide = ContentPackService.guideById(earlySignsGuideId);
    if (guide == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.75);
    return Card(
      key: const ValueKey('early-signs-card'),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.search, color: Colors.pink),
        title: Text(
          'Dấu hiệu mang thai sớm',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Các dấu hiệu thường gặp và khi nào nên thử thai',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openEarlySigns(context),
      ),
    );
  }
}
