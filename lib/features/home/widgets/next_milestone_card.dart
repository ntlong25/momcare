import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/milestone_schedule.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/services/milestone_progress_service.dart';
import '../../guides/guide_actions.dart';
import '../../guides/screens/guide_detail_screen.dart';
import '../../guides/widgets/milestone_status_chip.dart';

/// "Mốc khám tiếp theo": the next checkup milestone of the active pregnancy,
/// plus how many vaccines to ask about now. Hidden when nothing is due.
/// Includes its own top spacing so a hidden card leaves no gap.
class NextMilestoneCard extends ConsumerWidget {
  static const String checkupsGuideId = 'pregnant_checkups';
  static const String vaccinationGuideId = 'pregnant_vaccination';

  final PregnancyModel pregnancy;
  final DateTime now;

  const NextMilestoneCard({
    super.key,
    required this.pregnancy,
    required this.now,
  });

  void _openGuide(BuildContext context, String id) {
    final guide = ContentPackService.guideById(id);
    if (guide == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GuideDetailScreen(guide: guide)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(milestoneProgressProvider);
    final checkups = ContentPackService.guideById(checkupsGuideId);
    final vaccination = ContentPackService.guideById(vaccinationGuideId);

    final next = checkups == null
        ? null
        : MilestoneSchedule.build(
            guide: checkups,
            pregnancy: pregnancy,
            now: now,
            done: done,
          ).next();
    final vaccinesDue = vaccination == null
        ? 0
        : MilestoneSchedule.build(
            guide: vaccination,
            pregnancy: pregnancy,
            now: now,
            done: done,
          ).dueNow.length;
    if (next == null && vaccinesDue == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        key: const ValueKey('next-milestone-card'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mốc khám tiếp theo',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (next.item.weekLabel != null)
                      Text(
                        next.item.weekLabel!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                    Text(
                      MilestoneLabels.dateRange(next),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  next.item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                MilestoneStatusChip(milestone: next),
              ],
              if (vaccinesDue > 0) ...[
                const SizedBox(height: 8),
                InkWell(
                  key: const ValueKey('next-milestone-vaccines'),
                  onTap: () => _openGuide(context, vaccinationGuideId),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.vaccines_outlined, size: 18, color: muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tiêm phòng: $vaccinesDue mũi nên hỏi bác sĩ lúc này',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: muted),
                      ],
                    ),
                  ),
                ),
              ],
              Wrap(
                spacing: 4,
                children: [
                  if (next != null && next.canAddAppointment)
                    TextButton.icon(
                      key: const ValueKey('next-milestone-add'),
                      onPressed: () => GuideActions.run(
                        context,
                        type: next.item.actionType,
                        title: next.item.title,
                        value: next.item.actionValue,
                        week: next.item.weekFrom,
                      ),
                      icon: Icon(
                        GuideActions.icon(next.item.actionType),
                        size: 18,
                      ),
                      label: Text(
                        GuideActions.defaultLabel(next.item.actionType),
                      ),
                    ),
                  if (checkups != null)
                    TextButton(
                      key: const ValueKey('next-milestone-open'),
                      onPressed: () => _openGuide(context, checkupsGuideId),
                      child: const Text('Xem lịch khám'),
                    ),
                ],
              ),
              if ((next != null && checkups!.isDraft) ||
                  (vaccinesDue > 0 && vaccination!.isDraft))
                Text(
                  'Lịch tham khảo, đang chờ bác sĩ duyệt. '
                  'Hãy theo lịch hẹn của bác sĩ.',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
