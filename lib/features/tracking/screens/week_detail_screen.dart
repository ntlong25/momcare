import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/data/week_content_parser.dart';
import '../../../core/models/guide_models.dart';
import '../../../core/models/week_detail_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../guides/screens/guide_detail_screen.dart';
import '../../references/widgets/draft_content_note.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../widgets/week_image.dart';

/// Read-only week-by-week pages (weeks 0-42) from `weeks_v2.json`, falling
/// back to the legacy week data for weeks without a v2 entry.
class WeekDetailScreen extends StatefulWidget {
  static const int minWeek = WeekContentParser.minWeek;
  static const int maxWeek = WeekContentParser.maxWeek;

  final int initialWeek;

  /// The pregnancy's current week (marker + jump-back); defaults to
  /// [initialWeek].
  final int? currentWeek;

  /// Overrides for tests; default to the loaded content pack.
  final Map<int, WeekDetail>? weeks;
  final Map<String, ContentSource>? sources;

  const WeekDetailScreen({
    super.key,
    required this.initialWeek,
    this.currentWeek,
    this.weeks,
    this.sources,
  });

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  late final PageController _controller;
  late int _week;

  int get _currentWeek => (widget.currentWeek ?? widget.initialWeek).clamp(
    WeekDetailScreen.minWeek,
    WeekDetailScreen.maxWeek,
  );

  @override
  void initState() {
    super.initState();
    _week = widget.initialWeek.clamp(
      WeekDetailScreen.minWeek,
      WeekDetailScreen.maxWeek,
    );
    _controller = PageController(initialPage: _week);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int week) {
    final target = week.clamp(
      WeekDetailScreen.minWeek,
      WeekDetailScreen.maxWeek,
    );
    if ((target - _week).abs() > 1) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  WeekDetail _detail(int week) => widget.weeks != null
      ? ContentPackService.resolveWeekDetail(week, widget.weeks!)
      : ContentPackService.weekDetail(week);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = _week == _currentWeek;

    return Scaffold(
      appBar: AppBar(title: Text('Tuần $_week')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Tuần trước',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _week > WeekDetailScreen.minWeek
                      ? () => _goTo(_week - 1)
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: isCurrent
                        ? Chip(
                            key: const ValueKey('week-current-chip'),
                            avatar: Icon(
                              Icons.favorite,
                              size: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                            label: const Text('Tuần hiện tại'),
                            backgroundColor: AppTheme.primaryTint(
                              theme.colorScheme,
                            ),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: () => _goTo(_currentWeek),
                            icon: const Icon(Icons.my_location, size: 18),
                            label: Text(
                              'Về tuần hiện tại ($_currentWeek)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tuần sau',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _week < WeekDetailScreen.maxWeek
                      ? () => _goTo(_week + 1)
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: WeekDetailScreen.maxWeek + 1,
              onPageChanged: (page) => setState(() => _week = page),
              itemBuilder: (context, index) => _WeekPage(
                detail: _detail(index),
                sources: widget.sources ?? ContentPackService.sources,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPage extends StatelessWidget {
  final WeekDetail detail;
  final Map<String, ContentSource> sources;

  const _WeekPage({required this.detail, required this.sources});

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[
      if (detail.sizeCompare != null)
        _StatChip(
          icon: Icons.spa,
          label: 'Kích thước',
          value: detail.sizeCompare!,
        ),
      if (detail.lengthText != null)
        _StatChip(
          icon: Icons.straighten,
          label: 'Chiều dài',
          value: detail.lengthText!,
        ),
      if (detail.weightText != null)
        _StatChip(
          icon: Icons.monitor_weight_outlined,
          label: 'Cân nặng',
          value: detail.weightText!,
        ),
    ];

    return ListView(
      key: PageStorageKey('week-page-${detail.week}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        WeekImage(detail: detail),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: stats),
        ],
        if (detail.isDraft) ...[
          const SizedBox(height: 12),
          const DraftContentNote(),
        ],
        _TextSection(
          icon: Icons.child_care,
          title: 'Sự phát triển của bé',
          text: detail.babyDevelopment,
        ),
        _TextSection(
          icon: Icons.pregnant_woman,
          title: 'Thay đổi của mẹ',
          text: detail.motherChanges,
        ),
        _BulletSection(
          icon: Icons.healing,
          title: 'Triệu chứng thường gặp',
          items: detail.commonSymptoms,
        ),
        _BulletSection(
          icon: Icons.task_alt,
          title: 'Việc nên làm tuần này',
          items: detail.todoThisWeek,
        ),
        _BulletSection(
          icon: Icons.medical_services_outlined,
          title: 'Khám thai tuần này',
          items: detail.examsThisWeek,
        ),
        _BulletSection(
          icon: Icons.restaurant,
          title: 'Dinh dưỡng trọng tâm',
          items: detail.nutritionFocus,
        ),
        if (detail.redFlags.isNotEmpty)
          _RedFlagsSection(items: detail.redFlags),
        const SizedBox(height: 24),
        SourceMetadataCard.custom(
          sourceNames: GuideDetailScreen.sourceNames(detail.sources, sources),
          lastUpdated: detail.lastUpdated,
          note:
              'Các mốc phát triển là ước tính tham khảo, mỗi thai kỳ có thể khác nhau. Thông tin không thay thế tư vấn của bác sĩ.',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const _SectionHeader({required this.icon, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.primaryColor;
    return Row(
      children: [
        Icon(icon, size: 22, color: tint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TextSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: icon, title: title),
          const SizedBox(height: 6),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _BulletSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: icon, title: title),
          for (final item in items) _Bullet(text: item),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color? color;

  const _Bullet({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style?.copyWith(color: color)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _RedFlagsSection extends StatelessWidget {
  final List<String> items;

  const _RedFlagsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            title: 'Dấu hiệu cần đi khám ngay',
            color: red,
          ),
          for (final item in items) _Bullet(text: item, color: red),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => NavigationHelper.toEmergencyWarning(context),
              icon: Icon(Icons.chevron_right, color: red),
              label: Text(
                'Xem hướng dẫn cấp cứu',
                style: TextStyle(color: red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
