import 'guide_models.dart';
import 'pregnancy_model.dart';

/// Where a guide timeline milestone stands relative to today.
enum MilestoneStatus { upcoming, dueNow, past, done }

/// A guide timeline item placed on the calendar of the active pregnancy.
class ScheduledMilestone {
  final GuideTimelineItem item;
  final String guideId;
  final bool isVaccination;

  /// First day of week `weekFrom` (pregnancy start + weekFrom * 7 days).
  final DateTime startDate;

  /// Last day of week `weekTo` (pregnancy start + (weekTo + 1) * 7 - 1 days).
  final DateTime endDate;
  final MilestoneStatus status;

  /// Date the user marked the milestone done (only when [status] is done).
  final DateTime? doneDate;

  /// Calendar days from today to [startDate]; negative once started.
  final int daysUntilStart;

  const ScheduledMilestone({
    required this.item,
    required this.guideId,
    required this.isVaccination,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.daysUntilStart,
    this.doneDate,
  });

  String get id => item.id;

  bool get isDone => status == MilestoneStatus.done;

  /// Offer "Thêm vào lịch hẹn" only for appointment items still ahead/open.
  bool get canAddAppointment =>
      item.actionType == GuideActionType.addAppointment &&
      (status == MilestoneStatus.upcoming || status == MilestoneStatus.dueNow);
}

/// Pure date maths for a guide timeline against a pregnancy (no IO).
class MilestoneSchedule {
  final List<ScheduledMilestone> items;

  const MilestoneSchedule(this.items);

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Places every timeline item of [guide] that has a week on the calendar.
  /// [done] maps item id -> done date and overrides the date-based status.
  static MilestoneSchedule build({
    required GuideArticle guide,
    required PregnancyModel pregnancy,
    required DateTime now,
    Map<String, DateTime> done = const {},
  }) {
    final start = _dateOnly(pregnancy.pregnancyStartDate);
    final today = _dateOnly(now);
    final isVaccination = guide.category == GuideCategory.vaccination;
    final items = <ScheduledMilestone>[];

    for (final item in guide.timeline) {
      final from = item.weekFrom ?? item.weekTo;
      final to = item.weekTo ?? item.weekFrom;
      if (from == null || to == null) continue;
      final lastWeek = to < from ? from : to;
      // Raw days (no 0..42 clamp); DateTime normalises day overflow.
      final startDate = DateTime(start.year, start.month, start.day + from * 7);
      final endDate = DateTime(
        start.year,
        start.month,
        start.day + (lastWeek + 1) * 7 - 1,
      );
      final doneDate = done[item.id];
      final MilestoneStatus status;
      if (doneDate != null) {
        status = MilestoneStatus.done;
      } else if (today.isBefore(startDate)) {
        status = MilestoneStatus.upcoming;
      } else if (today.isAfter(endDate)) {
        status = MilestoneStatus.past;
      } else {
        status = MilestoneStatus.dueNow;
      }
      items.add(
        ScheduledMilestone(
          item: item,
          guideId: guide.id,
          isVaccination: isVaccination,
          startDate: startDate,
          endDate: endDate,
          status: status,
          doneDate: doneDate == null ? null : _dateOnly(doneDate),
          daysUntilStart: PregnancyModel.calendarDaysBetween(today, startDate),
        ),
      );
    }

    items.sort((a, b) {
      final byStart = a.startDate.compareTo(b.startDate);
      return byStart != 0 ? byStart : a.endDate.compareTo(b.endDate);
    });
    return MilestoneSchedule(List.unmodifiable(items));
  }

  ScheduledMilestone? byId(String id) {
    for (final m in items) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Items whose window contains today and that are not done.
  List<ScheduledMilestone> get dueNow =>
      items.where((m) => m.status == MilestoneStatus.dueNow).toList();

  /// The open item closing soonest, else the earliest upcoming item.
  ScheduledMilestone? next() {
    ScheduledMilestone? best;
    for (final m in dueNow) {
      if (best == null || m.endDate.isBefore(best.endDate)) best = m;
    }
    if (best != null) return best;
    for (final m in items) {
      if (m.status == MilestoneStatus.upcoming) return m;
    }
    return null;
  }
}
