import 'package:flutter/material.dart';

import '../../../core/models/milestone_schedule.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';

/// Vietnamese labels shared by the guide timeline and the Hôm nay card.
class MilestoneLabels {
  static const String doctorAdvice = 'Theo chỉ định của bác sĩ';
  static const String unmark = 'Bỏ đánh dấu';

  static String _dm(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';

  /// `dd/MM – dd/MM/yyyy` (both years shown when the range crosses a year).
  static String dateRange(ScheduledMilestone m) {
    if (m.startDate.year != m.endDate.year) {
      return '${DateFormatter.formatDate(m.startDate)} – '
          '${DateFormatter.formatDate(m.endDate)}';
    }
    return '${_dm(m.startDate)} – ${DateFormatter.formatDate(m.endDate)}';
  }

  static String status(ScheduledMilestone m) => switch (m.status) {
    MilestoneStatus.upcoming => 'Sắp tới · còn ${m.daysUntilStart} ngày',
    MilestoneStatus.dueNow => 'Đến lúc rồi',
    MilestoneStatus.past => 'Đã qua',
    MilestoneStatus.done =>
      '${m.isVaccination ? 'Đã tiêm' : 'Đã khám'}'
          '${m.doneDate == null ? '' : ' ${DateFormatter.formatDate(m.doneDate!)}'}',
  };

  static String markDone(ScheduledMilestone m) =>
      m.isVaccination ? 'Đánh dấu đã tiêm' : 'Đánh dấu đã khám';
}

/// Small status pill. Container roles with onSurface text keep >= 4.5:1
/// contrast in light and dark themes.
class MilestoneStatusChip extends StatelessWidget {
  final ScheduledMilestone milestone;

  const MilestoneStatusChip({super.key, required this.milestone});

  static Color background(ColorScheme scheme, MilestoneStatus status) {
    final semantic = AppSemanticColors.of(scheme);
    return switch (status) {
      MilestoneStatus.dueNow => scheme.secondaryContainer,
      MilestoneStatus.upcoming => semantic.infoContainer,
      MilestoneStatus.past => scheme.surfaceContainerHighest,
      MilestoneStatus.done => semantic.successContainer,
    };
  }

  static IconData icon(MilestoneStatus status) => switch (status) {
    MilestoneStatus.dueNow => Icons.notifications_active_outlined,
    MilestoneStatus.upcoming => Icons.schedule,
    MilestoneStatus.past => Icons.history,
    MilestoneStatus.done => Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background(scheme, milestone.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon(milestone.status), size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              MilestoneLabels.status(milestone),
              style: theme.textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
