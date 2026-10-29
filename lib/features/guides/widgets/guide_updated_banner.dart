import 'package:flutter/material.dart';

import '../../../core/services/milestone_progress_service.dart';
import '../../../core/utils/date_formatter.dart';

/// "Cập nhật ngày ..." banner for the documents & benefits guide (B8): rules
/// change, so the user is told when the content was last checked.
class GuideUpdatedBanner extends StatelessWidget {
  final String? lastUpdated;

  const GuideUpdatedBanner({super.key, required this.lastUpdated});

  static const String fallback = 'Chưa rõ ngày cập nhật';
  static const String checkOfficially =
      'Quy định về chế độ thai sản, BHXH và giấy tờ có thể thay đổi. Hãy kiểm tra lại trên cổng BHXH Việt Nam, Cổng Dịch vụ công hoặc hỏi cơ quan có thẩm quyền trước khi làm thủ tục.';

  /// "Cập nhật ngày dd/MM/yyyy", or [fallback] for a missing/invalid date.
  static String label(String? lastUpdated) {
    final date = MilestoneProgressService.parseDate(lastUpdated);
    if (date == null) return fallback;
    return 'Cập nhật ngày ${DateFormatter.formatDate(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      key: const ValueKey('guide-updated-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.update, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label(lastUpdated),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(checkOfficially, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
