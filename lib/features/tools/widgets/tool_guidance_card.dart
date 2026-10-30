import 'package:flutter/material.dart';

import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/app_card.dart';

/// Guidance card (notice variant) for the counter tools with a link to the
/// emergency warning signs.
class ToolGuidanceCard extends StatelessWidget {
  static const String disclaimer =
      'Thông tin tham khảo, không thay thế chẩn đoán hay tư vấn của bác sĩ.';

  final String title;
  final List<String> paragraphs;

  const ToolGuidanceCard({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppCardColors.of(context, AppCardVariant.notice);
    final text = colors.foreground;

    return SizedBox(
      width: double.infinity,
      child: AppCard(
        key: const ValueKey('tool-guidance-card'),
        variant: AppCardVariant.notice,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        icon: Icons.info_outline,
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final paragraph in paragraphs) ...[
              Text(
                paragraph,
                style: theme.textTheme.bodyMedium?.copyWith(color: text),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: text),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('tool-guidance-warning-link'),
                style: TextButton.styleFrom(foregroundColor: text),
                onPressed: () => NavigationHelper.toEmergencyWarning(context),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Xem dấu hiệu cần đi khám'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
