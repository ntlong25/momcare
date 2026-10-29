import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/contraction_service.dart';
import '../../../core/services/kick_counter_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/navigation_helper.dart';

/// "Bộ đếm" tab of Công cụ (pregnancy mode): entry points to the kick
/// counter and the contraction timer.
class CounterToolsScreen extends ConsumerWidget {
  const CounterToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(kickCounterProvider);
    final contractions = ref.watch(contractionProvider);

    final activeKick = sessions.where((s) => s.isActive).firstOrNull;
    final lastKick = sessions.where((s) => !s.isActive).firstOrNull;
    final kickSubtitle = activeKick != null
        ? 'Đang đếm · ${activeKick.count} cử động'
        : lastKick != null
        ? 'Lần gần nhất: ${lastKick.count} cử động · '
              '${DateFormatter.formatDateTime(lastKick.startedAt)}'
        : 'Thường bắt đầu theo dõi từ khoảng tuần 28';

    final runningContraction = contractions.isNotEmpty
        ? (contractions.last.isActive ? contractions.last : null)
        : null;
    final lastContraction = contractions
        .where((entry) => !entry.isActive)
        .lastOrNull;
    final contractionSubtitle = runningContraction != null
        ? 'Đang ghi một cơn co'
        : lastContraction != null
        ? 'Lần gần nhất: ${DateFormatter.formatDateTime(lastContraction.startedAt)}'
              ' · Dài ${formatClock(lastContraction.duration!)}'
        : 'Ghi lại độ dài và khoảng cách giữa các cơn co';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ToolCard(
          key: const ValueKey('tools-kick'),
          icon: Icons.child_care,
          title: 'Đếm cử động thai',
          subtitle: kickSubtitle,
          onTap: () => NavigationHelper.toKickCounter(context),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('tools-contraction'),
          icon: Icons.timer_outlined,
          title: 'Đếm cơn co',
          subtitle: contractionSubtitle,
          onTap: () => NavigationHelper.toContractionTimer(context),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTint(scheme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
