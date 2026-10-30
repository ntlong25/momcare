import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/bump_photo.dart';
import '../../../core/services/bump_photo_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../screens/bump_journal_screen.dart';

/// Visual entry to "Nhật ký ảnh bụng bầu" on Hôm nay and Tuần thai: the
/// latest photo of [week], or an invitation to take one, with up to
/// [maxRecent] thumbnails of earlier weeks. Only built for an active
/// pregnancy. The card opens the journal on [week]; "Chụp ảnh" also starts
/// the camera there.
class BumpSpotlightCard extends ConsumerWidget {
  static const int maxRecent = 3;

  /// Current pregnancy week.
  final int week;

  const BumpSpotlightCard({super.key, required this.week});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = BumpPhotoService.groupByWeek(ref.watch(bumpPhotoProvider));
    final notifier = ref.read(bumpPhotoProvider.notifier);
    void open() => NavigationHelper.toBumpJournal(context, week: week);

    final thisWeek = [
      for (final group in groups)
        if (group.key == week) ...group.value,
    ];
    if (thisWeek.isNotEmpty) {
      return _LatestPhoto(
        week: week,
        count: thisWeek.length,
        image: BumpPhotoImage(file: notifier.fileFor(thisWeek.first)),
        onTap: open,
      );
    }
    final recent = <BumpPhoto>[
      for (final group in groups)
        if (group.key < week) ...group.value,
    ].take(maxRecent);
    return _Invitation(
      week: week,
      thumbnails: [
        for (final photo in recent)
          BumpPhotoImage(file: notifier.fileFor(photo), cacheWidth: 150),
      ],
      onTap: open,
      onCamera: () =>
          NavigationHelper.toBumpJournal(context, week: week, openCamera: true),
    );
  }
}

class _LatestPhoto extends StatelessWidget {
  static const double _width = 96;
  static const double _height = 120;

  final int week;
  final int count;
  final Widget image;
  final VoidCallback onTap;

  const _LatestPhoto({
    required this.week,
    required this.count,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = AppCardColors.of(context, AppCardVariant.spotlight).foreground;
    return MergeSemantics(
      child: AppCard(
        variant: AppCardVariant.spotlight,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(width: _width, height: _height, child: image),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ảnh bụng tuần $week',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$count ảnh trong tuần này',
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Xem nhật ký ảnh',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: fg,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: fg),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Invitation extends StatelessWidget {
  static const double _thumbnailSize = 44;

  final int week;
  final List<Widget> thumbnails;
  final VoidCallback onTap;
  final VoidCallback onCamera;

  const _Invitation({
    required this.week,
    required this.thumbnails,
    required this.onTap,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = AppCardColors.of(context, AppCardVariant.spotlight).foreground;
    return AppCard(
      variant: AppCardVariant.spotlight,
      icon: Icons.photo_camera_outlined,
      title: 'Tuần $week đã có ảnh chưa?',
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lưu lại dáng bụng của mẹ tuần này nhé.',
            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Wraps instead of overflowing at large text sizes.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (thumbnails.isNotEmpty)
                ExcludeSemantics(
                  child: Row(
                    key: const ValueKey('bump-spotlight-recent'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < thumbnails.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: SizedBox.square(
                            dimension: _thumbnailSize,
                            child: thumbnails[i],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              FilledButton.icon(
                key: const ValueKey('bump-spotlight-camera'),
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Chụp ảnh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
