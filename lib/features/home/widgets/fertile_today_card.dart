import 'package:flutter/material.dart';

import '../../../core/models/fertile_guidance.dart';
import '../../../core/services/cycle_prediction.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../fertility/widgets/cycle_marker.dart';
import '../../references/widgets/draft_content_note.dart';

/// "Khả năng thụ thai hôm nay" on the pre-pregnancy Hôm nay. An estimate with
/// no percentage; it renders nothing when [CyclePrediction.todayLevel] is
/// null (the late-period card takes over) or the wording is not loaded.
class FertileTodayCard extends StatelessWidget {
  final CyclePrediction prediction;
  final FertileGuidance guidance;

  /// Opens the quick log of today.
  final VoidCallback? onLog;

  const FertileTodayCard({
    super.key,
    required this.prediction,
    required this.guidance,
    this.onLog,
  });

  static bool isVisible(
    CyclePrediction? prediction,
    FertileGuidance guidance,
  ) => prediction?.todayLevel != null && !guidance.isEmpty;

  @override
  Widget build(BuildContext context) {
    final level = prediction.todayLevel;
    if (level == null || guidance.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final (levelId, messageId, marker) = switch (level) {
      FertilityLevel.low => ('level_low', 'message_low', null),
      FertilityLevel.high => (
        'level_high',
        'message_high',
        CycleMarkerKind.fertile,
      ),
      // Peak days are fertile days, not the estimated ovulation date: the
      // marker keeps the meaning it has on the calendar and legend.
      FertilityLevel.peak => (
        'level_peak',
        'message_peak',
        CycleMarkerKind.fertile,
      ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guidance.text('title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (marker != null) ...[
                CycleMarker(kind: marker, size: 16),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  '${guidance.text(levelId)} '
                  '${guidance.text('estimate_suffix')}',
                  key: const ValueKey('fertile-today-level'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(guidance.text(messageId), style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${guidance.text('window_label')}'
            '${prediction.isFromLhTest ? ' (${guidance.text('lh_source')})' : ''}: '
            '${DateFormatter.formatDateRange(prediction.fertileStart, prediction.fertileEnd)}',
            key: const ValueKey('fertile-today-window'),
            style: theme.textTheme.bodyMedium,
          ),
          if (prediction.isFromLhTest) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              guidance.text('lh_note'),
              key: const ValueKey('fertile-today-lh-note'),
              style: muted,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            guidance.confidenceLine(prediction),
            key: const ValueKey('fertile-today-confidence'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(guidance.confidenceNote(prediction), style: muted),
          const SizedBox(height: AppSpacing.sm),
          Text(guidance.text('frequency'), style: theme.textTheme.bodyMedium),
          if (prediction.hasCycleOutsideTypicalRange) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              guidance.text('outside_range_note'),
              key: const ValueKey('fertile-today-outside-range'),
              style: muted,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(guidance.text('not_contraception'), style: muted),
          if (onLog != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('fertile-today-log'),
                onPressed: onLog,
                icon: const Icon(Icons.edit_calendar),
                label: Text(guidance.text('signals_log_today')),
              ),
            ),
          ],
          if (guidance.isDraft) ...[
            const SizedBox(height: AppSpacing.md),
            const DraftContentNote(),
          ],
        ],
      ),
    );
  }
}
