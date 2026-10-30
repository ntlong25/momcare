import 'dart:math' as math;

import '../models/menstrual_cycle_model.dart';

/// Regularity state of the recorded cycles.
enum CycleRegularity {
  /// Not enough cycles recorded to judge regularity.
  insufficientData,
  regular,
  irregular,
}

/// Chance of conceiving today, as an estimate. There is deliberately no
/// percentage behind it.
enum FertilityLevel { low, high, peak }

/// How far a [CyclePrediction] can be trusted. There is deliberately no
/// "high": a calendar estimate never earns that claim.
enum PredictionConfidence { low, medium }

/// Whether the recorded cycles can still give a current estimate. Every
/// screen reads this one state, so Hôm nay and Chu kỳ cannot disagree.
enum CycleStatus {
  /// No cycles, or the expected period has not passed.
  onTrack,

  /// The expected period has passed.
  late,

  /// Too long since the last recorded period to estimate anything.
  stale,
}

/// Where today falls relative to a range of dates.
enum DateRangePosition { upcoming, inside, past }

/// Today against a predicted range of dates, for both Hôm nay and Chu kỳ.
class RangeCountdown {
  final DateRangePosition position;

  /// Days to the range start; 0 unless [position] is upcoming.
  final int daysUntilStart;

  /// Days since the range end; 0 unless [position] is past.
  final int daysSinceEnd;

  /// The range is a single date.
  final bool isSingleDay;

  const RangeCountdown._(
    this.position, {
    required this.isSingleDay,
    this.daysUntilStart = 0,
    this.daysSinceEnd = 0,
  });

  factory RangeCountdown.of(DateTime start, DateTime end, DateTime today) {
    final isSingleDay = CycleStats.daysBetween(start, end) == 0;
    final untilStart = CycleStats.daysBetween(today, start);
    if (untilStart > 0) {
      return RangeCountdown._(
        DateRangePosition.upcoming,
        isSingleDay: isSingleDay,
        daysUntilStart: untilStart,
      );
    }
    final sinceEnd = CycleStats.daysBetween(end, today);
    if (sinceEnd > 0) {
      return RangeCountdown._(
        DateRangePosition.past,
        isSingleDay: isSingleDay,
        daysSinceEnd: sinceEnd,
      );
    }
    return RangeCountdown._(DateRangePosition.inside, isSingleDay: isSingleDay);
  }

  /// Label of the inside state: [inRangeLabel] for a real range, otherwise
  /// 'Hôm nay'.
  String insideLabel(String inRangeLabel) =>
      isSingleDay || inRangeLabel.isEmpty ? 'Hôm nay' : inRangeLabel;

  /// One-line text: 'N ngày nữa', the inside label, or 'Đã qua N ngày'.
  String label(String inRangeLabel) => switch (position) {
    DateRangePosition.upcoming => '$daysUntilStart ngày nữa',
    DateRangePosition.inside => insideLabel(inRangeLabel),
    DateRangePosition.past => 'Đã qua $daysSinceEnd ngày',
  };
}

/// Pure cycle arithmetic shared by [CyclePrediction] and `HealthService`.
class CycleStats {
  const CycleStats._();

  /// Minimum number of cycles before regularity is evaluated.
  static const int minCyclesForRegularity = 3;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static int daysBetween(DateTime from, DateTime to) {
    return DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }

  /// Cycles sorted by start date (oldest first).
  static List<MenstrualCycleModel> sortedByStart(
    List<MenstrualCycleModel> cycles,
  ) {
    return List<MenstrualCycleModel>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Cycle lengths derived from consecutive start dates after sorting, so the
  /// order in which periods were entered never produces negative lengths.
  static List<int> cycleLengths(List<MenstrualCycleModel> cycles) {
    final sorted = sortedByStart(cycles);
    final lengths = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      final length = daysBetween(sorted[i - 1].startDate, sorted[i].startDate);
      if (length > 0) lengths.add(length);
    }
    return lengths;
  }

  /// Average cycle length; 28 when nothing is recorded.
  static int averageCycleLength(List<MenstrualCycleModel> cycles) {
    if (cycles.isEmpty) return 28; // Default average

    var lengths = cycleLengths(cycles);
    if (lengths.isEmpty) {
      lengths = cycles
          .where((c) => c.cycleLengthDays != null && c.cycleLengthDays! > 0)
          .map((c) => c.cycleLengthDays!)
          .toList();
    }
    if (lengths.isEmpty) return 28;

    final total = lengths.fold<int>(0, (sum, length) => sum + length);
    return (total / lengths.length).round();
  }

  /// Regularity with an explicit "not enough data" state.
  static CycleRegularity regularity(List<MenstrualCycleModel> cycles) {
    if (cycles.length < minCyclesForRegularity) {
      return CycleRegularity.insufficientData;
    }
    final lengths = cycleLengths(cycles);
    if (lengths.isEmpty) return CycleRegularity.insufficientData;

    final averageLength = averageCycleLength(cycles);
    final regularCount = lengths
        .where((length) => (length - averageLength).abs() <= 3)
        .length;
    return (regularCount / lengths.length) >= 0.7
        ? CycleRegularity.regular
        : CycleRegularity.irregular;
  }

  /// Next predicted period, rolled forward by whole cycles so it is never
  /// before [today].
  static DateTime? predictNextPeriod(
    List<MenstrualCycleModel> cycles, {
    required DateTime today,
  }) {
    if (cycles.isEmpty) return null;

    final lastStart = dateOnly(sortedByStart(cycles).last.startDate);
    final averageLength = averageCycleLength(cycles);
    final reference = dateOnly(today);

    var next = addDays(lastStart, averageLength);
    while (next.isBefore(reference)) {
      next = addDays(next, averageLength);
    }
    return next;
  }

  /// Expected start of the period after the most recent recorded one: last
  /// start + average cycle length. Unlike [predictNextPeriod] it never rolls
  /// forward, so it can be in the past (used for the late-period estimate).
  static DateTime? expectedPeriodDate(List<MenstrualCycleModel> cycles) {
    if (cycles.isEmpty) return null;
    final lastStart = dateOnly(sortedByStart(cycles).last.startDate);
    return addDays(lastStart, averageCycleLength(cycles));
  }

  /// Days past [expectedPeriodDate] as of [today]; 0 when not late or when
  /// there are no cycles.
  static int daysLate(
    List<MenstrualCycleModel> cycles, {
    required DateTime today,
  }) {
    final expected = expectedPeriodDate(cycles);
    if (expected == null) return 0;
    final late = daysBetween(expected, dateOnly(today));
    return late > 0 ? late : 0;
  }

  /// Whether the cycle data is too old to estimate a late period: more than
  /// two average cycles have passed since the last recorded start (e.g. on a
  /// 28-day average, 56 days is still an estimate and 57 asks the user to
  /// update their cycle data).
  static bool isDataStale(
    List<MenstrualCycleModel> cycles, {
    required DateTime today,
  }) {
    if (cycles.isEmpty) return false;
    final lastStart = dateOnly(sortedByStart(cycles).last.startDate);
    final elapsed = daysBetween(lastStart, dateOnly(today));
    return elapsed > 2 * averageCycleLength(cycles);
  }
}

/// Calendar estimate of the next period, ovulation and fertile window.
///
/// Dates are ranges from the shortest and longest of the last
/// [recentCycleCount] cycle lengths, because ovulation about
/// [lutealDays] days before the next period is only an estimate. The
/// fertile window runs from [fertileDaysBeforeOvulation] days before the
/// earliest ovulation to the latest ovulation (6 days ending on ovulation
/// when the lengths do not vary, ASRM 2021).
class CyclePrediction {
  /// How many recent cycle lengths form the range.
  static const int recentCycleCount = 6;
  static const int lutealDays = 14;
  static const int fertileDaysBeforeOvulation = 5;
  static const int peakDaysBeforeOvulation = 2;

  /// Cycle lengths outside this range are worth raising with a doctor.
  static const int typicalMinCycleLength = 21;
  static const int typicalMaxCycleLength = 35;

  /// Rolled-forward mid estimate; equals `HealthService.predictNextPeriod`.
  final DateTime nextPeriod;
  final DateTime earliestPeriod;
  final DateTime latestPeriod;

  /// [nextPeriod] minus [lutealDays].
  final DateTime ovulation;
  final DateTime earliestOvulation;
  final DateTime latestOvulation;

  final DateTime fertileStart;
  final DateTime fertileEnd;

  /// [peakDaysBeforeOvulation] days before [ovulation] through [ovulation].
  final DateTime peakStart;
  final DateTime peakEnd;

  final PredictionConfidence confidence;
  final CycleRegularity regularity;

  /// A recent cycle (or the average) is outside the typical 21-35 days.
  final bool hasCycleOutsideTypicalRange;

  /// Whether this estimate is current. When it is not, the dates here are
  /// rolled forward by whole cycles and must not be shown as current.
  final CycleStatus status;

  /// Today's estimate; null when late or stale, because a level from a
  /// rolled-forward cycle would contradict the late-period card. The card
  /// shows from the first day past the mid estimate, which is never later
  /// than [latestPeriod].
  final FertilityLevel? todayLevel;

  const CyclePrediction._({
    required this.nextPeriod,
    required this.earliestPeriod,
    required this.latestPeriod,
    required this.ovulation,
    required this.earliestOvulation,
    required this.latestOvulation,
    required this.fertileStart,
    required this.fertileEnd,
    required this.peakStart,
    required this.peakEnd,
    required this.confidence,
    required this.regularity,
    required this.hasCycleOutsideTypicalRange,
    required this.status,
    required this.todayLevel,
  });

  /// See [CycleStatus]; [CycleStatus.onTrack] when there are no cycles.
  static CycleStatus statusOf(
    List<MenstrualCycleModel> cycles, {
    required DateTime today,
  }) {
    if (CycleStats.isDataStale(cycles, today: today)) return CycleStatus.stale;
    return CycleStats.daysLate(cycles, today: today) >= 1
        ? CycleStatus.late
        : CycleStatus.onTrack;
  }

  bool get isLateOrStale => status != CycleStatus.onTrack;

  /// Null when there are no cycles.
  static CyclePrediction? compute(
    List<MenstrualCycleModel> cycles, {
    required DateTime today,
  }) {
    final nextPeriod = CycleStats.predictNextPeriod(cycles, today: today);
    if (nextPeriod == null) return null;

    final day = CycleStats.dateOnly(today);
    final average = CycleStats.averageCycleLength(cycles);
    final lengths = CycleStats.cycleLengths(cycles);
    final recent = lengths
        .skip(math.max(0, lengths.length - recentCycleCount))
        .toList();
    // The average covers all cycles, so include it: the range must always
    // contain the mid estimate.
    final considered = [...recent, average];
    final shortest = considered.reduce(math.min);
    final longest = considered.reduce(math.max);

    final cycleStart = CycleStats.addDays(nextPeriod, -average);
    final earliestPeriod = CycleStats.addDays(cycleStart, shortest);
    final latestPeriod = CycleStats.addDays(cycleStart, longest);
    final ovulation = CycleStats.addDays(nextPeriod, -lutealDays);
    final earliestOvulation = CycleStats.addDays(earliestPeriod, -lutealDays);
    final latestOvulation = CycleStats.addDays(latestPeriod, -lutealDays);
    final fertileStart = CycleStats.addDays(
      earliestOvulation,
      -fertileDaysBeforeOvulation,
    );
    final peakStart = CycleStats.addDays(ovulation, -peakDaysBeforeOvulation);

    final regularity = CycleStats.regularity(cycles);
    final isRegular =
        cycles.length >= CycleStats.minCyclesForRegularity &&
        regularity == CycleRegularity.regular;
    final status = statusOf(cycles, today: day);

    bool within(DateTime start, DateTime end) =>
        !day.isBefore(start) && !day.isAfter(end);

    FertilityLevel? level;
    if (status == CycleStatus.onTrack) {
      if (isRegular && within(peakStart, ovulation)) {
        level = FertilityLevel.peak;
      } else if (within(fertileStart, latestOvulation)) {
        level = FertilityLevel.high;
      } else {
        level = FertilityLevel.low;
      }
    }

    return CyclePrediction._(
      nextPeriod: nextPeriod,
      earliestPeriod: earliestPeriod,
      latestPeriod: latestPeriod,
      ovulation: ovulation,
      earliestOvulation: earliestOvulation,
      latestOvulation: latestOvulation,
      fertileStart: fertileStart,
      fertileEnd: latestOvulation,
      peakStart: peakStart,
      peakEnd: ovulation,
      confidence: isRegular
          ? PredictionConfidence.medium
          : PredictionConfidence.low,
      regularity: regularity,
      hasCycleOutsideTypicalRange: considered.any(
        (length) =>
            length < typicalMinCycleLength || length > typicalMaxCycleLength,
      ),
      status: status,
      todayLevel: level,
    );
  }

  /// Every day of the fertile window, in order.
  List<DateTime> get fertileDays => [
    for (
      var day = fertileStart;
      !day.isAfter(fertileEnd);
      day = CycleStats.addDays(day, 1)
    )
      day,
  ];
}
