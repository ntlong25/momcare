import 'package:flutter/material.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';

class PregnancyProgressCard extends StatelessWidget {
  final PregnancyModel pregnancy;

  const PregnancyProgressCard({super.key, required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final currentWeek = pregnancy.currentWeek;
    final progress = currentWeek / 40;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuần $currentWeek',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pregnancy.trimester,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          // Wraps to two lines at large font scales.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                'Hoàn thành ${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Dự sinh: ${DateFormatter.formatDate(pregnancy.dueDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getWeeklyTip(currentWeek),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeeklyTip(int week) {
    if (week <= 13) {
      return 'Các cơ quan chính của bé đang hình thành. Hãy dùng vitamin bầu theo hướng dẫn của bác sĩ.';
    } else if (week <= 27) {
      return 'Bé đang phát triển nhanh. Hãy duy trì bữa ăn cân bằng và theo dõi lịch khám.';
    } else {
      return 'Bé đang chuẩn bị chào đời. Hãy nghỉ ngơi và luyện tập thư giãn nếu phù hợp.';
    }
  }
}
