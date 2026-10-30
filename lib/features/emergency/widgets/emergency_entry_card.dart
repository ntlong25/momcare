import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/app_card.dart';

class EmergencyEntryCard extends StatelessWidget {
  const EmergencyEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = context.semantic.onEmergency;

    return AppCard(
      variant: AppCardVariant.emergency,
      onTap: () => NavigationHelper.toEmergencyWarning(context),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: fg, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dấu hiệu cần đi khám ngay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Xem các dấu hiệu bất thường cần liên hệ bác sĩ hoặc cơ sở y tế.',
                  style: theme.textTheme.bodySmall?.copyWith(color: fg),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: fg),
        ],
      ),
    );
  }
}
