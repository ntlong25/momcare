import 'package:flutter/material.dart';
import '../../../core/data/medical_references.dart';
import '../../../core/utils/navigation_helper.dart';

class SourceMetadataCard extends StatelessWidget {
  final MedicalReferenceGroup? group;
  final String? note;

  /// Explicit source names (e.g. resolved from `sources.json` ids). When set,
  /// they replace the names derived from [group].
  final List<String>? sourceNames;

  /// Explicit "last updated" text; defaults to the references list date.
  final String? lastUpdated;

  const SourceMetadataCard({
    super.key,
    required MedicalReferenceGroup this.group,
    this.note,
  }) : sourceNames = null,
       lastUpdated = null;

  /// Metadata for content-engine items that carry their own source ids and
  /// `lastUpdated` value.
  const SourceMetadataCard.custom({
    super.key,
    required List<String> this.sourceNames,
    this.lastUpdated,
    this.note,
    this.group,
  });

  @override
  Widget build(BuildContext context) {
    final names =
        sourceNames ??
        (group == null
            ? const <String>[]
            : MedicalReferenceData.byGroup(
                group!,
              ).map((reference) => reference.organization).toSet().toList());
    final sourceText = names.isEmpty ? 'Chưa gắn nguồn' : names.join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.source, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nguồn tham khảo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (group != null) ...[
              Text('Nhóm nguồn: ${MedicalReferenceData.labelForGroup(group!)}'),
              const SizedBox(height: 4),
            ],
            Text('Nguồn: $sourceText'),
            const SizedBox(height: 4),
            Text(
              'Cập nhật lần cuối: ${lastUpdated ?? MedicalReferenceData.lastUpdated}',
            ),
            if (note != null) ...[const SizedBox(height: 8), Text(note!)],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => NavigationHelper.toReferences(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Xem nguồn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
