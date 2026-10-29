import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/medical_references.dart';
import '../../../core/models/contraction.dart';
import '../../../core/services/contraction_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_format.dart';
import '../../guides/guide_actions.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../../settings/widgets/my_clinic_card.dart';
import '../tool_guidance.dart';
import '../widgets/tool_button_styles.dart';
import '../widgets/tool_confirm_dialog.dart';
import '../widgets/tool_guidance_card.dart';
import '../../../core/widgets/empty_state.dart';

/// "Đếm cơn co" (Phase 20, B10): times contractions and the gaps between
/// them. It never interprets the result beyond the neutral 5-1-1 hint.
class ContractionTimerScreen extends ConsumerStatefulWidget {
  const ContractionTimerScreen({super.key});

  /// Gaps longer than this show as "—" in the history.
  static const Duration maxShownInterval = Duration(hours: 2);

  @override
  ConsumerState<ContractionTimerScreen> createState() =>
      _ContractionTimerScreenState();
}

class _ContractionTimerScreenState
    extends ConsumerState<ContractionTimerScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    ref.listenManual<List<Contraction>>(
      contractionProvider,
      (_, entries) => _syncTicker(entries.isNotEmpty),
      fireImmediately: true,
    );
  }

  /// Ticks while a contraction runs and for "Từ cơn trước" while idle.
  void _syncTicker(bool needed) {
    if (needed) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(contractionProvider);
    final notifier = ref.read(contractionProvider.notifier);
    final now = notifier.now();
    final showHint = ContractionService.matches511(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Đếm cơn co')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTimer(context, notifier, entries, now),
          if (showHint) ...[
            const SizedBox(height: 16),
            _buildHint(context),
            const SizedBox(height: 12),
            const MyClinicCard(emergency: true),
          ],
          const SizedBox(height: 16),
          ToolGuidanceCard(
            title: 'Khi nào cần đến viện',
            paragraphs: [
              ToolGuidance.fiveOneOne(),
              ToolGuidance.whenToGo(),
              ToolGuidance.under37Weeks,
            ],
          ),
          const SizedBox(height: 16),
          ..._buildHistory(context, notifier, entries),
          const SizedBox(height: 16),
          const SourceMetadataCard(group: MedicalReferenceGroup.urgentWarning),
        ],
      ),
    );
  }

  Widget _buildTimer(
    BuildContext context,
    ContractionNotifier notifier,
    List<Contraction> entries,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final active = notifier.active;
    final last = entries.isEmpty ? null : entries.last;
    final summary = ContractionService.summarize(entries, now);

    final summaryParts = <String>[
      '${summary.count} cơn trong 1 giờ qua',
      if (summary.averageDuration != null)
        'Dài TB ${formatClock(summary.averageDuration!)}',
      if (summary.averageInterval != null)
        'Cách TB ${formatClock(summary.averageInterval!)}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (active != null) ...[
              Text('Cơn co đang diễn ra', style: theme.textTheme.bodyMedium),
              Text(
                formatClock(active.elapsed(now)),
                key: const ValueKey('contraction-running'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ] else if (last != null) ...[
              Text('Từ cơn trước', style: theme.textTheme.bodyMedium),
              Text(
                formatClock(now.difference(last.startedAt)),
                key: const ValueKey('contraction-since-last'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ] else
              Text(
                'Bấm khi cơn co bắt đầu và bấm lại khi cơn co kết thúc. '
                'Ứng dụng ghi lại độ dài mỗi cơn và khoảng cách giữa các cơn.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('contraction-toggle'),
                style: ToolButtonStyles.mainAction(
                  context,
                  danger: active != null,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  notifier.toggle();
                },
                icon: Icon(active == null ? Icons.play_arrow : Icons.stop),
                label: Text(
                  active == null ? 'Bắt đầu cơn co' : 'Kết thúc cơn co',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              summaryParts.join(' · '),
              key: const ValueKey('contraction-summary'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: const ValueKey('contraction-511-hint'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Các cơn co gần đây khớp mốc 5-1-1',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các cơn co bạn ghi lại cách nhau khoảng 5 phút trở xuống, mỗi cơn '
            'khoảng 1 phút trở lên, trong ít nhất 1 giờ. Đây là mốc nhiều nơi '
            'dùng để khuyên đến viện. Hãy liên hệ bác sĩ hoặc nơi bạn dự định '
            'đến khám, hoặc gọi 115 nếu cần hỗ trợ khẩn cấp.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('contraction-call-115'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () =>
                  GuideActions.launchUri(context, GuideActions.phoneUri('115')),
              icon: const Icon(Icons.call),
              label: const Text('Gọi 115'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHistory(
    BuildContext context,
    ContractionNotifier notifier,
    List<Contraction> entries,
  ) {
    final theme = Theme.of(context);
    final completed = entries.any((entry) => !entry.isActive);

    // Newest day first, newest entry first within a day.
    final byDay = <DateTime, List<int>>{};
    for (var i = entries.length - 1; i >= 0; i--) {
      final start = entries[i].startedAt;
      byDay
          .putIfAbsent(DateTime(start.year, start.month, start.day), () => [])
          .add(i);
    }

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              'Lịch sử',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (completed)
            TextButton(
              key: const ValueKey('contraction-clear'),
              onPressed: () async {
                final confirmed = await confirmToolDelete(
                  context,
                  title: 'Xóa lịch sử cơn co?',
                  message: 'Tất cả cơn co đã ghi sẽ bị xóa.',
                );
                if (confirmed) await notifier.clearHistory();
              },
              child: const Text('Xóa lịch sử'),
            ),
        ],
      ),
      const SizedBox(height: 4),
      if (entries.isEmpty)
        const Center(
          child: AppEmptyState.compact(
            icon: Icons.timer_outlined,
            title: 'Chưa có cơn co nào được ghi.',
          ),
        ),
      for (final day in byDay.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            DateFormatter.formatDate(day.key),
            style: theme.textTheme.labelLarge,
          ),
        ),
        for (final index in day.value)
          _buildRow(context, notifier, entries, index),
      ],
    ];
  }

  Widget _buildRow(
    BuildContext context,
    ContractionNotifier notifier,
    List<Contraction> entries,
    int index,
  ) {
    final entry = entries[index];
    final interval = ContractionService.intervalBefore(entries, index);
    final intervalText =
        interval == null || interval > ContractionTimerScreen.maxShownInterval
        ? '—'
        : formatClock(interval);
    final durationText = entry.duration == null
        ? 'đang diễn ra'
        : formatClock(entry.duration!);

    return Card(
      key: ValueKey('contraction-row-${entry.startedAt.toIso8601String()}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(DateFormatter.formatTime(entry.startedAt)),
        subtitle: Text('Dài $durationText · Cách $intervalText'),
        trailing: entry.isActive
            ? null
            : IconButton(
                key: ValueKey(
                  'contraction-delete-${entry.startedAt.toIso8601String()}',
                ),
                tooltip: 'Xóa',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await confirmToolDelete(
                    context,
                    title: 'Xóa cơn co này?',
                  );
                  if (confirmed) await notifier.delete(entry);
                },
              ),
      ),
    );
  }
}
