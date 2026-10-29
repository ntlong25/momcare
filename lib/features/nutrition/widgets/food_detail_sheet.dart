import 'package:flutter/material.dart';

import '../../../core/models/food_model.dart';
import '../../../core/models/guide_models.dart';
import '../../guides/screens/guide_detail_screen.dart';
import '../../references/widgets/draft_content_note.dart';
import '../../references/widgets/source_metadata_card.dart';
import 'food_verdict_badge.dart';

/// Bottom sheet with the verdict, reason, tip and sources of one food.
class FoodDetailSheet extends StatelessWidget {
  static const String disclaimer =
      'Thông tin mang tính tham khảo, không thay thế tư vấn của bác sĩ hoặc chuyên gia dinh dưỡng.';
  static const String noSourcesText =
      'Mục này chưa gắn nguồn riêng; nội dung dựa trên khuyến nghị dinh dưỡng chung trong danh sách nguồn tham khảo.';
  static const String seeDoctorText =
      'Nếu đã lỡ ăn hoặc thấy triệu chứng bất thường (sốt, đau bụng, tiêu chảy, ra huyết...), hãy liên hệ bác sĩ để được tư vấn.';

  final FoodItem item;
  final FoodPack pack;
  final Map<String, ContentSource> sources;

  const FoodDetailSheet({
    super.key,
    required this.item,
    required this.pack,
    required this.sources,
  });

  static Future<void> show(
    BuildContext context, {
    required FoodItem item,
    required FoodPack pack,
    required Map<String, ContentSource> sources,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FoodDetailSheet(item: item, pack: pack, sources: sources),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FoodVerdictBadge(verdict: item.verdict),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                item.groupLabel,
                if (item.aliases.isNotEmpty)
                  'Tên khác: ${item.aliases.join(', ')}',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            if (item.reason.isNotEmpty)
              _Section(
                icon: Icons.help_outline,
                title: 'Vì sao',
                text: item.reason,
              ),
            if (item.tip.isNotEmpty)
              _Section(
                icon: Icons.lightbulb_outline,
                title: 'Lời khuyên',
                text: item.tip,
              ),
            if (item.verdict != FoodVerdict.ok) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(seeDoctorText)),
                ],
              ),
            ],
            if (pack.isDraft) ...[
              const SizedBox(height: 16),
              const DraftContentNote(),
            ],
            const SizedBox(height: 16),
            if (item.sources.isEmpty) ...[
              Text(noSourcesText, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            SourceMetadataCard.custom(
              sourceNames: GuideDetailScreen.sourceNames(item.sources, sources),
              lastUpdated: pack.lastUpdated,
              note: disclaimer,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Section({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
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
          ),
          const SizedBox(height: 6),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
