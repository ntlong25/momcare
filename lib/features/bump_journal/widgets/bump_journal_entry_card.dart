import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bump_photo_service.dart';
import '../../../core/utils/navigation_helper.dart';

/// Tuần thai entry to "Nhật ký ảnh bụng bầu".
class BumpJournalEntryCard extends ConsumerWidget {
  const BumpJournalEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(bumpPhotoProvider).length;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        key: const ValueKey('tracking-bump-journal'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.photo_camera_outlined,
            color: scheme.onSecondaryContainer,
          ),
        ),
        title: const Text('Nhật ký ảnh bụng bầu'),
        subtitle: Text(count > 0 ? '$count ảnh' : 'Lưu ảnh bụng bầu theo tuần'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => NavigationHelper.toBumpJournal(context),
      ),
    );
  }
}
