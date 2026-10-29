import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_helper.dart';

/// Tinted guidance card for the counter tools with a link to the
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
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.75);

    return Container(
      key: const ValueKey('tool-guidance-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint(scheme, 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: scheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final paragraph in paragraphs) ...[
            Text(
              paragraph,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            disclaimer,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('tool-guidance-warning-link'),
              style: TextButton.styleFrom(foregroundColor: scheme.onSurface),
              onPressed: () => NavigationHelper.toEmergencyWarning(context),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Xem dấu hiệu cần đi khám'),
            ),
          ),
        ],
      ),
    );
  }
}
