import 'package:flutter/material.dart';
import '../../../core/data/medical_references.dart';
import '../../../core/data/pregnancy_weeks_data.dart';
import '../../../core/models/week_detail_model.dart';
import '../../references/widgets/source_metadata_card.dart';

class BabyDevelopmentCard extends StatelessWidget {
  final PregnancyWeekData weekData;

  /// Resolved week page; its size/length/weight win over [weekData] so the
  /// card matches the week detail screen.
  final WeekDetail? weekDetail;

  const BabyDevelopmentCard({
    super.key,
    required this.weekData,
    this.weekDetail,
  });

  /// Prefers the weeks_v2 text so the card matches the week detail page.
  String get _developmentText {
    final text = weekDetail?.babyDevelopment.trim() ?? '';
    return text.isNotEmpty ? text : weekData.development;
  }

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
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.child_care,
                    color: Colors.pink,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sự phát triển của bé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.straighten,
              'Chiều dài',
              WeekDetail.statText(weekDetail?.lengthText, weekData.babyLength),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.monitor_weight_outlined,
              'Cân nặng',
              WeekDetail.statText(weekDetail?.weightText, weekData.babyWeight),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.spa,
              'Kích thước',
              WeekDetail.statText(weekDetail?.sizeCompare, weekData.babySize),
            ),
            const Divider(height: 32),
            Text(
              'Điều đang diễn ra',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _developmentText,
              key: const ValueKey('baby-development-text'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const SourceMetadataCard(
              group: MedicalReferenceGroup.growthAndVitals,
              note:
                  'Các mốc phát triển là ước tính tham khảo. Kết quả thực tế có thể khác nhau theo từng thai kỳ.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
