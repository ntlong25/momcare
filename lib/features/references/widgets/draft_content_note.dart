import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Banner for content-engine items whose `reviewStatus` is not `approved`.
class DraftContentNote extends StatelessWidget {
  const DraftContentNote({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: semantic.onWarningContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Nội dung đang chờ bác sĩ duyệt',
              style: TextStyle(color: semantic.onWarningContainer),
            ),
          ),
        ],
      ),
    );
  }
}
