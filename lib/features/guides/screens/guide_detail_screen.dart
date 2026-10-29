import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/guide_models.dart';
import '../../../core/services/guide_progress_service.dart';
import '../../references/widgets/draft_content_note.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../guide_actions.dart';

/// Generic renderer for a content-engine guide: sections, checklist with
/// persisted ticks, timeline and actions.
class GuideDetailScreen extends ConsumerWidget {
  final GuideArticle guide;

  /// Override source lookup (tests); defaults to `sources.json`.
  final Map<String, ContentSource>? sources;

  const GuideDetailScreen({super.key, required this.guide, this.sources});

  /// Source display names for [ids]; unknown ids are shown as-is.
  static List<String> sourceNames(
    List<String> ids,
    Map<String, ContentSource> sources,
  ) {
    return ids.map((id) => sources[id]?.organization ?? id).toSet().toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticked = ref.watch(guideChecklistProvider);
    final theme = Theme.of(context);
    final progress = guide.progress(ticked);

    return Scaffold(
      appBar: AppBar(title: Text(GuideEnums.categoryLabel(guide.category))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            guide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (guide.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(guide.summary, style: theme.textTheme.bodyLarge),
          ],
          if (guide.isDraft) ...[
            const SizedBox(height: 12),
            const DraftContentNote(),
          ],
          for (final section in guide.sections) _SectionView(section: section),
          if (guide.checklist.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    guide.tracksProgress
                        ? 'Việc cần làm'
                        : 'Dấu hiệu cần lưu ý',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (progress != null)
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 6),
            ],
            const SizedBox(height: 4),
            for (final item in guide.checklist)
              _ChecklistTile(
                item: item,
                tickable: guide.tracksProgress,
                checked: ticked.contains(item.id),
                onChanged: (value) => ref
                    .read(guideChecklistProvider.notifier)
                    .toggle(item.id, value),
                onAction: () => GuideActions.run(
                  context,
                  type: item.actionType,
                  title: item.text,
                  value: item.actionValue,
                  week: item.weekDue ?? guide.weekFrom,
                ),
              ),
          ],
          if (guide.timeline.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Các mốc theo tuần', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final item in guide.timeline)
              _TimelineTile(
                item: item,
                onAction: () => GuideActions.run(
                  context,
                  type: item.actionType,
                  title: item.title,
                  value: item.actionValue,
                  week: item.weekFrom,
                ),
              ),
          ],
          const SizedBox(height: 24),
          SourceMetadataCard.custom(
            sourceNames: sourceNames(
              guide.sources,
              sources ?? ContentPackService.sources,
            ),
            lastUpdated: guide.lastUpdated,
            note:
                'Thông tin mang tính tham khảo, không thay thế tư vấn của bác sĩ hoặc nhân viên y tế.',
          ),
        ],
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final GuideSection section;

  const _SectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.heading != null)
            Text(
              section.heading!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          if (section.body != null) ...[
            const SizedBox(height: 6),
            Text(section.body!, style: theme.textTheme.bodyMedium),
          ],
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(bullet, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final GuideActionType type;
  final String? label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.type,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(GuideActions.icon(type), size: 18),
      label: Text(
        (label == null || label!.isEmpty)
            ? GuideActions.defaultLabel(type)
            : label!,
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final GuideChecklistItem item;

  /// False renders a plain bullet (no checkbox), e.g. for warning guides.
  final bool tickable;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onAction;

  const _ChecklistTile({
    required this.item,
    this.tickable = true,
    required this.checked,
    required this.onChanged,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!tickable)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(
                  child: Text(
                    item.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          )
        else
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: checked,
            onChanged: (value) => onChanged(value ?? false),
            title: Text(
              item.text,
              style: checked
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: item.weekDue != null
                ? Text('Tuần ${item.weekDue}')
                : null,
          ),
        if (item.actionType != GuideActionType.none)
          Padding(
            padding: EdgeInsets.only(left: tickable ? 40 : 16),
            child: _ActionButton(
              type: item.actionType,
              label: item.actionLabel,
              onPressed: onAction,
            ),
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final GuideTimelineItem item;
  final VoidCallback onAction;

  const _TimelineTile({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.weekLabel != null)
              Text(
                item.weekLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.description != null) ...[
              const SizedBox(height: 4),
              Text(item.description!, style: theme.textTheme.bodyMedium),
            ],
            if (item.actionType != GuideActionType.none)
              _ActionButton(
                type: item.actionType,
                label: item.actionLabel,
                onPressed: onAction,
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
