import 'package:flutter/material.dart';

import '../../../core/models/fertile_guidance.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../references/widgets/draft_content_note.dart';

/// "Nên đi khám khi nào": fixed draft wording only. It reads no user data, so
/// it cannot count months or turn into a diagnosis.
class DoctorVisitCard extends StatelessWidget {
  final FertileGuidance guidance;

  const DoctorVisitCard({super.key, required this.guidance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guidance.text('doctor_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          for (final id in const [
            'doctor_cycles',
            'doctor_trying',
            'doctor_age',
          ]) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(guidance.text(id), style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            guidance.text('doctor_anytime'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (guidance.isDraft) ...[
            const SizedBox(height: AppSpacing.md),
            const DraftContentNote(),
          ],
        ],
      ),
    );
  }
}
