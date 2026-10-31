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

/// What the ovulation dates of a [CyclePrediction] come from.
enum OvulationSource {
  /// Estimated from the recorded cycle lengths.
  calendar,

  /// Moved by a positive LH test in the current cycle. Still an expectation,
  /// never a confirmed ovulation.
  lhTest,
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
///
/// A positive LH test narrows the current cycle only: ovulation is then
/// expected within [lhOvulationDaysAfterPositive] days of the first positive.
/// The next period, and so every later cycle, stays calendar based, and a
/// late or stale status ignores the test.
class CyclePrediction {
  /// How many recent cycle lengths form the range.
  static const int recentCycleCount = 6;
  static const int lutealDays = 14;
  static const int fertileDaysBeforeOvulation = 5;
  static const int peakDaysBeforeOvulation = 2;
  static const int lhOvulationDaysAfterPositive = 2;

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

  final OvulationSource ovulationSource;

  /// The first positive LH test of the current cycle, when it set the dates.
  final DateTime? lhPositiveDate;

  bool get isFromLhTest => ovulationSource == OvulationSource.lhTest;

  /// Average cycle length behind these dates.
  final int cycleLength;

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
    required this.ovulationSource,
    required this.lhPositiveDate,
    required this.cycleLength,
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

  /// The first of [positiveDays] in the cycle started on [cycleStart], up to
  /// [today]; earlier cycles and future dates do not count.
  static DateTime? firstPositiveInCycle(
    Iterable<DateTime> positiveDays, {
    required DateTime cycleStart,
    required DateTime today,
  }) {
    DateTime? first;
    for (final positive in positiveDays) {
      final day = CycleStats.dateOnly(positive);
      if (day.isBefore(cycleStart) || day.isAfter(today)) continue;
      if (first == null || day.isBefore(first)) first = day;
    }
    return first;
  }

  static FertilityLevel _levelOn(
    DateTime day, {
    required bool fromLhTest,
    required bool isRegular,
    required DateTime peakStart,
    required DateTime peakEnd,
    required DateTime fertileStart,
    required DateTime fertileEnd,
  }) {
    bool within(DateTime start, DateTime end) =>
        !day.isBefore(start) && !day.isAfter(end);
    if (fromLhTest) {
      // The test replaces the calendar range.
      return within(peakStart, peakEnd)
          ? FertilityLevel.peak
          : FertilityLevel.low;
    }
    if (isRegular && within(peakStart, peakEnd)) return FertilityLevel.peak;
    if (within(fertileStart, fertileEnd)) return FertilityLevel.high;
    return FertilityLevel.low;
  }

  /// The level the Hôm nay card would show on [day] of this cycle, for an
  /// on-track estimate.
  FertilityLevel levelOn(DateTime day) => _levelOn(
    CycleStats.dateOnly(day),
    fromLhTest: isFromLhTest,
    isRegular: confidence == PredictionConfidence.medium,
    peakStart: peakStart,
    peakEnd: peakEnd,
    fertileStart: fertileStart,
    fertileEnd: fertileEnd,
  );

  /// These dates [count] average cycles later. Call on a calendar estimate:
  /// an LH test never reaches a later cycle.
  CyclePrediction laterCycle(int count) {
    DateTime shift(DateTime day) =>
        CycleStats.addDays(day, count * cycleLength);
    return CyclePrediction._(
      nextPeriod: shift(nextPeriod),
      earliestPeriod: shift(earliestPeriod),
      latestPeriod: shift(latestPeriod),
      ovulation: shift(ovulation),
      earliestOvulation: shift(earliestOvulation),
      latestOvulation: shift(latestOvulation),
      fertileStart: shift(fertileStart),
      fertileEnd: shift(fertileEnd),
      peakStart: shift(peakStart),
      peakEnd: shift(peakEnd),
      confidence: confidence,
      regularity: regularity,
      hasCycleOutsideTypicalRange: hasCycleOutsideTypicalRange,
      status: CycleStatus.onTrack,
      todayLevel: null,
      ovulationSource: OvulationSource.calendar,
      lhPositiveDate: null,
      cycleLength: cycleLength,
    );
  }

  /// Null when there are no cycles. [positiveLhDays] are the logged days with
  /// a positive or peak LH test, of any cycle and in any order.
  static CyclePrediction? compute(
    List<MenstrualCycleModel> cycles, {
    required DateTime today,
    Iterable<DateTime> positiveLhDays = const [],
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
    final status = statusOf(cycles, today: day);
    // Late and stale win: the dates then are rolled forward, not this cycle.
    final lhPositive = status == CycleStatus.onTrack
        ? firstPositiveInCycle(
            positiveLhDays,
            cycleStart: cycleStart,
            today: day,
          )
        : null;

    final DateTime ovulation;
    final DateTime earliestOvulation;
    final DateTime latestOvulation;
    final DateTime peakStart;
    final DateTime peakEnd;
    if (lhPositive != null) {
      earliestOvulation = lhPositive;
      latestOvulation = CycleStats.addDays(
        lhPositive,
        lhOvulationDaysAfterPositive,
      );
      ovulation = CycleStats.addDays(
        lhPositive,
        lhOvulationDaysAfterPositive ~/ 2,
      );
      peakStart = earliestOvulation;
      peakEnd = latestOvulation;
    } else {
      ovulation = CycleStats.addDays(nextPeriod, -lutealDays);
      earliestOvulation = CycleStats.addDays(earliestPeriod, -lutealDays);
      latestOvulation = CycleStats.addDays(latestPeriod, -lutealDays);
      peakStart = CycleStats.addDays(ovulation, -peakDaysBeforeOvulation);
      peakEnd = ovulation;
    }
    final fertileStart = CycleStats.addDays(
      earliestOvulation,
      -fertileDaysBeforeOvulation,
    );

    final regularity = CycleStats.regularity(cycles);
    final isRegular =
        cycles.length >= CycleStats.minCyclesForRegularity &&
        regularity == CycleRegularity.regular;

    FertilityLevel? level;
    if (status == CycleStatus.onTrack) {
      level = _levelOn(
        day,
        fromLhTest: lhPositive != null,
        isRegular: isRegular,
        peakStart: peakStart,
        peakEnd: peakEnd,
        fertileStart: fertileStart,
        fertileEnd: latestOvulation,
      );
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
      peakEnd: peakEnd,
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
      ovulationSource: lhPositive != null
          ? OvulationSource.lhTest
          : OvulationSource.calendar,
      lhPositiveDate: lhPositive,
      cycleLength: average,
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
