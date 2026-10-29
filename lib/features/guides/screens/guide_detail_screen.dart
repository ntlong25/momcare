import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/content_pack_service.dart';
import '../../../core/models/guide_models.dart';
import '../../../core/models/milestone_schedule.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/guide_price_service.dart';
import '../../../core/services/guide_progress_service.dart';
import '../../../core/services/milestone_progress_service.dart';
import '../../../core/utils/date_picker_utils.dart';
import '../../../core/utils/vnd_format.dart';
import '../../../core/widgets/hive_boxes_listener.dart';
import '../../references/widgets/draft_content_note.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../guide_actions.dart';
import '../widgets/guide_updated_banner.dart';
import '../widgets/milestone_status_chip.dart';

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

  /// Opens a date picker (LMP..today) and stores the chosen done date.
  static Future<void> markMilestoneDone(
    BuildContext context,
    WidgetRef ref,
    PregnancyModel pregnancy,
    ScheduledMilestone milestone,
  ) async {
    final now = DateTime.now();
    final picked = await DatePickerUtils.pickDate(
      context: context,
      initialDate: now,
      firstDate: pregnancy.pregnancyStartDate,
      lastDate: now,
    );
    if (picked == null || !context.mounted) return;
    await ref
        .read(milestoneProgressProvider.notifier)
        .markDone(milestone.id, picked);
  }

  /// Opens the "Giá (VND)" dialog for [item] and stores the result.
  static Future<void> editPrice(
    BuildContext context,
    WidgetRef ref,
    GuideChecklistItem item,
    int? current,
  ) async {
    final result = await showDialog<_PriceResult>(
      context: context,
      builder: (_) => _PriceDialog(itemText: item.text, initial: current),
    );
    if (result == null) return;
    await ref.read(guidePriceProvider.notifier).setPrice(item.id, result.price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild when the due date is edited in another tab.
    return HiveBoxesListener(
      boxNames: const [AppConstants.pregnancyBox],
      builder: (context) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final ticked = ref.watch(guideChecklistProvider);
    final done = ref.watch(milestoneProgressProvider);
    final tracksPrices = guide.tracksPrices;
    final prices = tracksPrices
        ? ref.watch(guidePriceProvider)
        : const <String, int>{};
    final theme = Theme.of(context);
    final progress = guide.progress(ticked);
    final pregnancy = guide.stage == GuideStage.pregnant
        ? DatabaseService.getActivePregnancy()
        : null;
    final schedule = pregnancy == null
        ? null
        : MilestoneSchedule.build(
            guide: guide,
            pregnancy: pregnancy,
            now: DateTime.now(),
            done: done,
          );

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
          if (guide.category == GuideCategory.documents) ...[
            const SizedBox(height: 12),
            GuideUpdatedBanner(lastUpdated: guide.lastUpdated),
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
                    guide.tracksProgress ? 'Việc cần làm' : 'Việc nên làm',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (progress != null)
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 6),
            ],
            if (tracksPrices) ...[
              const SizedBox(height: 8),
              _BoughtTotal(guide: guide, ticked: ticked, prices: prices),
            ],
            const SizedBox(height: 4),
            for (final item in guide.checklist)
              _ChecklistTile(
                item: item,
                tickable: guide.tracksProgress,
                checked: ticked.contains(item.id),
                price: prices[item.id],
                onPrice: tracksPrices
                    ? () => editPrice(context, ref, item, prices[item.id])
                    : null,
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
                milestone: schedule?.byId(item.id),
                onMarkDone: (m) =>
                    markMilestoneDone(context, ref, pregnancy!, m),
                onUnmark: (m) =>
                    ref.read(milestoneProgressProvider.notifier).unmark(m.id),
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
          for (final bullet in section.bullets) _Bullet(text: bullet),
        ],
      ),
    );
  }
}

/// Plain bullet shared by section bullets and non-tickable checklist items.
class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(text, style: style)),
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

  /// Saved price (VND) shown on the price button.
  final int? price;

  /// Non-null shows the price button (shopping / hospital-bag guides).
  final VoidCallback? onPrice;

  const _ChecklistTile({
    required this.item,
    this.tickable = true,
    required this.checked,
    required this.onChanged,
    required this.onAction,
    this.price,
    this.onPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!tickable)
          _Bullet(text: item.text)
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
        if (tickable && onPrice != null)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: TextButton.icon(
              key: ValueKey('price-${item.id}'),
              onPressed: onPrice,
              icon: const Icon(Icons.sell_outlined, size: 18),
              label: Text(price == null ? 'Thêm giá' : formatVnd(price!)),
            ),
          ),
      ],
    );
  }
}

/// "Đã mua X/Y món · Đã chi Z" line for guides that track prices.
class _BoughtTotal extends StatelessWidget {
  final GuideArticle guide;
  final Set<String> ticked;
  final Map<String, int> prices;

  const _BoughtTotal({
    required this.guide,
    required this.ticked,
    required this.prices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bought = guide.checklist
        .where((item) => ticked.contains(item.id))
        .length;
    final total = guide.boughtTotal(ticked, prices);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đã mua $bought/${guide.checklist.length} món · '
          'Đã chi ${formatVnd(total)}',
          key: const ValueKey('guide-bought-total'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (guide.pricedCount(prices) == 0) ...[
          const SizedBox(height: 2),
          Text(
            'Ghi giá để xem tổng chi phí',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Result of [_PriceDialog]; a null [price] removes the saved price.
class _PriceResult {
  final int? price;

  const _PriceResult(this.price);
}

class _PriceDialog extends StatefulWidget {
  final String itemText;
  final int? initial;

  const _PriceDialog({required this.itemText, this.initial});

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = parseVndInput(_controller.text);
    return AlertDialog(
      title: const Text('Giá (VND)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.itemText, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('price-input'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(vndMaxDigits),
              ],
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                hintText: 'Ví dụ: 350000',
                suffixText: 'đ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              parsed == null ? 'Nhập số tiền lớn hơn 0' : formatVnd(parsed),
              key: const ValueKey('price-preview'),
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _PriceResult(null)),
            child: const Text('Xóa giá'),
          ),
        TextButton(
          onPressed: parsed == null
              ? null
              : () => Navigator.pop(context, _PriceResult(parsed)),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final GuideTimelineItem item;

  /// Calendar placement for the active pregnancy; null renders the plain
  /// tile (no pregnancy, or not a pregnant-stage guide).
  final ScheduledMilestone? milestone;
  final ValueChanged<ScheduledMilestone> onMarkDone;
  final ValueChanged<ScheduledMilestone> onUnmark;
  final VoidCallback onAction;

  const _TimelineTile({
    required this.item,
    required this.onAction,
    required this.onMarkDone,
    required this.onUnmark,
    this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    if (m != null) return _buildScheduled(context, m);
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
                  color: theme.colorScheme.primary,
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

  Widget _buildScheduled(BuildContext context, ScheduledMilestone m) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      key: ValueKey('milestone-${item.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.weekLabel != null)
                  Text(
                    item.weekLabel!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                Text(
                  MilestoneLabels.dateRange(m),
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            MilestoneStatusChip(milestone: m),
            if (m.isVaccination) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.medical_services_outlined, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      MilestoneLabels.doctorAdvice,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 6),
              Text(item.description!, style: theme.textTheme.bodyMedium),
            ],
            Wrap(
              spacing: 4,
              children: [
                if (m.canAddAppointment)
                  _ActionButton(
                    type: item.actionType,
                    label: item.actionLabel,
                    onPressed: onAction,
                  ),
                if (m.isDone)
                  TextButton.icon(
                    key: ValueKey('milestone-unmark-${item.id}'),
                    onPressed: () => onUnmark(m),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text(MilestoneLabels.unmark),
                  )
                else
                  TextButton.icon(
                    key: ValueKey('milestone-done-${item.id}'),
                    onPressed: () => onMarkDone(m),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(MilestoneLabels.markDone(m)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
