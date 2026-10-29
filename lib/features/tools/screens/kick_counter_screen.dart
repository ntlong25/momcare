import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/medical_references.dart';
import '../../../core/models/kick_session.dart';
import '../../../core/services/kick_counter_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_format.dart';
import '../../references/widgets/source_metadata_card.dart';
import '../tool_guidance.dart';
import '../widgets/tool_confirm_dialog.dart';
import '../widgets/tool_guidance_card.dart';

/// "Đếm cử động thai" (Phase 20, B10): counts movements and records how
/// long they took. It never interprets the result.
class KickCounterScreen extends ConsumerStatefulWidget {
  const KickCounterScreen({super.key});

  @override
  ConsumerState<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends ConsumerState<KickCounterScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    ref.listenManual<List<KickSession>>(
      kickCounterProvider,
      (_, sessions) => _syncTicker(sessions.any((s) => s.isActive)),
      fireImmediately: true,
    );
  }

  /// The 1 s ticker only runs while a session is active.
  void _syncTicker(bool active) {
    if (active) {
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
    final sessions = ref.watch(kickCounterProvider);
    final notifier = ref.read(kickCounterProvider.notifier);
    final active = sessions.where((s) => s.isActive).firstOrNull;
    final history = sessions.where((s) => !s.isActive).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Đếm cử động thai')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          active == null
              ? _buildIntro(context, notifier)
              : _buildSession(context, notifier, active),
          const SizedBox(height: 16),
          ToolGuidanceCard(
            title: 'Khi nào cần đi khám',
            paragraphs: [ToolGuidance.kickGuidance()],
          ),
          const SizedBox(height: 16),
          _buildHistoryHeader(context, notifier, history),
          const SizedBox(height: 4),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Chưa có lượt đếm nào.'),
            )
          else
            ...history.map((s) => _buildHistoryRow(context, notifier, s)),
          const SizedBox(height: 16),
          const SourceMetadataCard(group: MedicalReferenceGroup.urgentWarning),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context, KickCounterNotifier notifier) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đếm cử động của bé',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn lúc bé hay cử động, ngồi hoặc nằm nghiêng thoải mái. '
              'Mỗi lần bạn cảm nhận bé đạp, xoay hoặc trườn, hãy bấm "Bé đạp". '
              'Ứng dụng ghi lại số lần và thời gian để bạn theo dõi và trao đổi với bác sĩ.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('kick-start'),
                onPressed: notifier.start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu đếm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSession(
    BuildContext context,
    KickCounterNotifier notifier,
    KickSession session,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeToTen = session.timeToTen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Thời gian đã đếm', style: theme.textTheme.bodyMedium),
            Text(
              formatClock(session.elapsed(notifier.now())),
              key: const ValueKey('kick-elapsed'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              height: 180,
              child: FilledButton(
                key: const ValueKey('kick-tap'),
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: scheme.primary,
                  foregroundColor: AppTheme.textPrimaryColor,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  notifier.kick();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${session.count}',
                      key: const ValueKey('kick-count'),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Bé đạp',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (timeToTen != null) ...[
              const SizedBox(height: 12),
              Text(
                'Đã đếm ${KickSession.target} cử động sau ${formatMinutes(timeToTen)}',
                key: const ValueKey('kick-ten-line'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('kick-undo'),
                  onPressed: session.count > 0 ? notifier.undo : null,
                  icon: const Icon(Icons.undo),
                  label: const Text('Hoàn tác'),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('kick-stop'),
                  style: AppTheme.tonalButtonStyle(scheme),
                  onPressed: notifier.stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Kết thúc'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(
    BuildContext context,
    KickCounterNotifier notifier,
    List<KickSession> history,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Lịch sử',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (history.isNotEmpty)
          TextButton(
            key: const ValueKey('kick-clear'),
            onPressed: () async {
              final confirmed = await confirmToolDelete(
                context,
                title: 'Xóa lịch sử đếm cử động?',
                message: 'Tất cả lượt đếm đã kết thúc sẽ bị xóa.',
              );
              if (confirmed) await notifier.clearHistory();
            },
            child: const Text('Xóa lịch sử'),
          ),
      ],
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    KickCounterNotifier notifier,
    KickSession session,
  ) {
    final timeToTen = session.timeToTen;
    final subtitle = [
      DateFormatter.formatDateTime(session.startedAt),
      if (timeToTen != null)
        '${KickSession.target} cử động sau ${formatMinutes(timeToTen)}',
    ].join(' · ');

    return Card(
      key: ValueKey('kick-row-${session.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${session.count} cử động · ${formatMinutes(session.elapsed(notifier.now()))}',
        ),
        subtitle: Text(subtitle),
        trailing: IconButton(
          key: ValueKey('kick-delete-${session.id}'),
          tooltip: 'Xóa',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirmed = await confirmToolDelete(
              context,
              title: 'Xóa lượt đếm này?',
            );
            if (confirmed) await notifier.delete(session.id);
          },
        ),
      ),
    );
  }
}
