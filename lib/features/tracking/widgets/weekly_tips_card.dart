import 'package:flutter/material.dart';
import '../../../core/data/medical_references.dart';
import '../../../core/data/pregnancy_weeks_data.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../../../core/theme/app_tokens.dart';

class WeeklyTipsCard extends StatelessWidget {
  final PregnancyWeekData weekData;

  const WeeklyTipsCard({super.key, required this.weekData});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gợi ý trong tuần này',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (weekData.nutritionFocus.isNotEmpty) ...[
              _buildInfoBlock(
                context,
                Icons.restaurant_menu,
                'Trọng tâm dinh dưỡng',
                weekData.nutritionFocus,
                AppTone.success,
              ),
              const SizedBox(height: 16),
            ],
            ...weekData.tips.asMap().entries.map((entry) {
              final index = entry.key;
              final tip = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (weekData.redFlags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildWarningBlock(context),
            ],
            const SizedBox(height: 4),
            const SourceMetadataCard(group: MedicalReferenceGroup.pregnancy),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(
    BuildContext context,
    IconData icon,
    String title,
    String body,
    AppTone tone,
  ) {
    final colors = tone.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.onContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.onContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Cần đi khám ngay nếu có',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...weekData.redFlags
              .take(3)
              .map(
                (flag) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $flag',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
