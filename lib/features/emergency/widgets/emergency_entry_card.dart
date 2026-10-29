import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/app_card.dart';

class EmergencyEntryCard extends StatelessWidget {
  const EmergencyEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = AppTone.danger.of(context);

    return AppCard(
      variant: AppCardVariant.alert,
      onTap: () => NavigationHelper.toEmergencyWarning(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: danger.main,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.warning_amber_rounded, color: danger.onMain),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dấu hiệu cần đi khám ngay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: danger.onContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Xem các dấu hiệu bất thường cần liên hệ bác sĩ hoặc cơ sở y tế.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: danger.onContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: danger.onContainer),
        ],
      ),
    );
  }
}
