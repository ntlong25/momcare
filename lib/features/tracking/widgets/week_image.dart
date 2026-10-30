import 'package:flutter/material.dart';

import '../../../core/models/week_detail_model.dart';

/// Week illustration from `WeekDetail.image`. While the asset is loading, or
/// when it is missing/unset, a themed placeholder card is shown instead, so a
/// real `week_XX.webp` can be dropped into `assets/images/weeks/` later
/// without code changes.
class WeekImage extends StatelessWidget {
  final WeekDetail detail;
  final double height;

  const WeekImage({super.key, required this.detail, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final path = detail.image?.trim();
    if (path == null || path.isEmpty) return _placeholder(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: 'Hình minh hoạ tuần ${detail.week}',
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _placeholder(context);
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = scheme.onSecondaryContainer;
    final size = detail.sizeCompare;

    return Container(
      key: const ValueKey('week-image-placeholder'),
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            size == null ? Icons.child_care : Icons.eco,
            color: foreground,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Tuần ${detail.week}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            size == null ? 'Đang chuẩn bị' : 'Bé to bằng $size',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
