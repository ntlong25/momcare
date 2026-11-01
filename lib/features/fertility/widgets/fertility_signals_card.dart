import 'package:flutter/material.dart';

import '../../../core/models/fertile_guidance.dart';
import '../../../core/models/fertility_log_model.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../references/widgets/draft_content_note.dart';

/// Quick log entry and history on Chu kỳ. Signals are listed as the user
/// logged them; nothing here interprets temperature or mucus.
class FertilitySignalsCard extends StatelessWidget {
  /// How many recent days are listed.
  static const int historyLength = 6;

  final FertileGuidance guidance;
  final List<FertilityLogModel> logs;
  final bool showIntimacy;

  /// The day a new log goes to; never in the future.
  final DateTime logDay;
  final DateTime today;
  final ValueChanged<DateTime> onOpenLog;
  final VoidCallback onOpenSettings;

  const FertilitySignalsCard({
    super.key,
    required this.guidance,
    required this.logs,
    required this.showIntimacy,
    required this.logDay,
    required this.today,
    required this.onOpenLog,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final visible = logs
        .where((log) => log.isVisible(showIntimacy: showIntimacy))
        .take(historyLength)
        .toList();
    final isToday =
        FertilityLogModel.dayKey(logDay) == FertilityLogModel.dayKey(today);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  guidance.text('signals_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('fertility-signals-settings'),
                tooltip: guidance.text('signals_settings'),
                icon: const Icon(Icons.tune),
                onPressed: onOpenSettings,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('fertility-log-open'),
              onPressed: () => onOpenLog(logDay),
              icon: const Icon(Icons.edit_calendar),
              label: Text(
                isToday
                    ? guidance.text('signals_log_today')
                    : '${guidance.text('signals_log_day')} '
                          '${DateFormatter.formatDate(logDay)}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            Text(guidance.text('signals_empty'), style: muted)
          else ...[
            Text(guidance.text('signals_history_hint'), style: muted),
            for (final log in visible)
              ListTile(
                key: ValueKey(
                  'fertility-history-${FertilityLogModel.dayKey(log.date)}',
                ),
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormatter.formatDate(log.date)),
                subtitle: Text(
                  guidance.logSummary(log, showIntimacy: showIntimacy),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => onOpenLog(log.date),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(guidance.text('signals_history_note'), style: muted),
          const SizedBox(height: AppSpacing.xs),
          Text(guidance.text('signals_privacy'), style: muted),
          if (guidance.isDraft) ...[
            const SizedBox(height: AppSpacing.md),
            const DraftContentNote(),
          ],
        ],
      ),
    );
  }
}
