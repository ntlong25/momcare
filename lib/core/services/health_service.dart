import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/menstrual_cycle_model.dart';
import '../utils/app_logger.dart';

/// Regularity state of the recorded cycles.
enum CycleRegularity {
  /// Not enough cycles recorded to judge regularity.
  insufficientData,
  regular,
  irregular,
}

/// Service to interact with Apple Health (iOS) and Health Connect (Android)
/// for menstrual cycle data, plus pure cycle prediction helpers.
class HealthService {
  static final AppLogger _logger = AppLogger.instance;
  static Health? _health;
  static Future<void>? _initFuture;

  /// Minimum number of cycles before regularity is evaluated.
  static const int minCyclesForRegularity = 3;

  /// Initialize the health service. Safe to call more than once; errors are
  /// logged and never thrown so app startup is not blocked.
  static Future<void> init() {
    return _initFuture ??= _initInternal();
  }

  static Future<void> _initInternal() async {
    if (kIsWeb || !isAvailable) {
      _logger.info('HealthService skipped: platform not supported');
      return;
    }
    try {
      final health = Health();
      await health.configure();
      _health = health;
      _logger.info('HealthService initialized');
    } catch (e, stackTrace) {
      _logger.error(
        'HealthService initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Allow a later retry.
      _initFuture = null;
    }
  }

  static Future<Health?> _client() async {
    await init();
    return _health;
  }

  /// Check if health data access is available on this platform
  static bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check whether Android Health Connect is available.
  static Future<bool> isHealthConnectAvailable() async {
    if (!isAvailable) return false;
    if (!Platform.isAndroid) return true;

    try {
      final health = await _client();
      return await health?.isHealthConnectAvailable() ?? false;
    } catch (e, stackTrace) {
      _logger.error(
        'Error checking Health Connect availability',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Open the Health Connect install flow on Android.
  static Future<void> openHealthConnectInstall() async {
    if (!isAvailable || !Platform.isAndroid) return;

    try {
      final health = await _client();
      await health?.installHealthConnect();
    } catch (e, stackTrace) {
      _logger.error(
        'Error opening Health Connect install flow',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Request authorization to access menstrual cycle data
  static Future<bool> requestAuthorization() async {
    if (!isAvailable) {
      _logger.warning('Health data not available on this platform');
      return false;
    }

    try {
      final types = [HealthDataType.MENSTRUATION_FLOW];
      final permissions = [HealthDataAccess.READ];
      final health = await _client();
      final bool? authorized = await health?.requestAuthorization(
        types,
        permissions: permissions,
      );

      _logger.info('Health authorization result: $authorized');
      return authorized ?? false;
    } catch (e, stackTrace) {
      _logger.error(
        'Error requesting health authorization',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if we have permission to access health data
  static Future<bool> hasPermissions() async {
    if (!isAvailable) return false;

    try {
      final types = [HealthDataType.MENSTRUATION_FLOW];
      final permissions = [HealthDataAccess.READ];
      final health = await _client();
      final hasPermission = await health?.hasPermissions(
        types,
        permissions: permissions,
      );
      return hasPermission ?? false;
    } catch (e, stackTrace) {
      _logger.error(
        'Error checking health permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Fetch menstrual cycle data from HealthKit/Health Connect.
  /// Returns cycles (one per period) from the last [days] days. Each cycle has
  /// a stable id derived from its start date so re-syncing is idempotent.
  static Future<List<MenstrualCycleModel>> fetchMenstrualData({
    int days = 365,
  }) async {
    if (!isAvailable) {
      _logger.warning('Health data not available on this platform');
      return [];
    }

    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: days));
      final types = [HealthDataType.MENSTRUATION_FLOW];
      final permissions = [HealthDataAccess.READ];
      final health = await _client();

      final bool? hasPermission = await health?.hasPermissions(
        types,
        permissions: permissions,
      );
      if (hasPermission != true) {
        _logger.warning('No permission to access health data');
        return [];
      }

      final List<HealthDataPoint> healthData =
          await health?.getHealthDataFromTypes(
            startTime: startTime,
            endTime: now,
            types: types,
          ) ??
          [];

      _logger.info('Fetched ${healthData.length} menstrual data points');

      final cycles = buildCyclesFromPeriodDays(
        healthData.map((point) => point.dateFrom).toList(),
        now: now,
      );
      _logger.info('Converted to ${cycles.length} menstrual cycles');
      return cycles;
    } catch (e, stackTrace) {
      _logger.error(
        'Error fetching menstrual data',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Stable id for a cycle imported from a health platform.
  static String healthCycleId(DateTime startDate) {
    final d = _dateOnly(startDate);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'health_${d.year}-$month-$day';
  }

  /// Groups bleeding days into periods. Days at most 2 days apart belong to
  /// the same period. Cycle lengths are the gap between consecutive starts.
  static List<MenstrualCycleModel> buildCyclesFromPeriodDays(
    List<DateTime> days, {
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final sortedDays = days.map(_dateOnly).toSet().toList()..sort();
    final periods = <List<DateTime>>[];

    for (final day in sortedDays) {
      if (periods.isEmpty || _daysBetween(periods.last.last, day) > 2) {
        periods.add([day]);
      } else {
        periods.last.add(day);
      }
    }

    final cycles = <MenstrualCycleModel>[];
    for (var i = 0; i < periods.length; i++) {
      final start = periods[i].first;
      final end = periods[i].last;
      final cycleLength = i == 0
          ? null
          : _daysBetween(periods[i - 1].first, start);
      cycles.add(
        MenstrualCycleModel(
          id: healthCycleId(start),
          startDate: start,
          endDate: end,
          cycleLengthDays: cycleLength,
          periodLengthDays: _daysBetween(start, end) + 1,
          isFromHealthKit: true,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    return cycles;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _daysBetween(DateTime from, DateTime to) {
    return DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
      final length = _daysBetween(sorted[i - 1].startDate, sorted[i].startDate);
      if (length > 0) lengths.add(length);
    }
    return lengths;
  }

  /// Returns copies of [cycles] (oldest first) whose `cycleLengthDays` is the
  /// gap to the previous recorded start date (null for the oldest cycle).
  static List<MenstrualCycleModel> withRecomputedCycleLengths(
    List<MenstrualCycleModel> cycles,
  ) {
    final sorted = sortedByStart(cycles);
    final result = <MenstrualCycleModel>[];
    for (var i = 0; i < sorted.length; i++) {
      final cycle = sorted[i];
      final length = i == 0
          ? null
          : _daysBetween(sorted[i - 1].startDate, cycle.startDate);
      result.add(
        MenstrualCycleModel(
          id: cycle.id,
          startDate: cycle.startDate,
          endDate: cycle.endDate,
          cycleLengthDays: length != null && length > 0 ? length : null,
          periodLengthDays: cycle.periodLengthDays,
          flowIntensity: cycle.flowIntensity,
          symptoms: cycle.symptoms,
          notes: cycle.notes,
          isFromHealthKit: cycle.isFromHealthKit,
          createdAt: cycle.createdAt,
          updatedAt: cycle.updatedAt,
        ),
      );
    }
    return result;
  }

  /// Calculate average cycle length from a list of cycles
  static int calculateAverageCycleLength(List<MenstrualCycleModel> cycles) {
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
  static CycleRegularity cycleRegularity(List<MenstrualCycleModel> cycles) {
    if (cycles.length < minCyclesForRegularity) {
      return CycleRegularity.insufficientData;
    }
    final lengths = cycleLengths(cycles);
    if (lengths.isEmpty) return CycleRegularity.insufficientData;

    final averageLength = calculateAverageCycleLength(cycles);
    final regularCount = lengths
        .where((length) => (length - averageLength).abs() <= 3)
        .length;
    return (regularCount / lengths.length) >= 0.7
        ? CycleRegularity.regular
        : CycleRegularity.irregular;
  }

  /// Check if cycles are regular (more than 70% within 3 days of average)
  static bool areCyclesRegular(List<MenstrualCycleModel> cycles) {
    return cycleRegularity(cycles) == CycleRegularity.regular;
  }

  /// Get next predicted period date. When [today] is given (or by default,
  /// the current date) the prediction rolls forward by whole cycles so it is
  /// never in the past.
  static DateTime? predictNextPeriod(
    List<MenstrualCycleModel> cycles, {
    DateTime? today,
  }) {
    if (cycles.isEmpty) return null;

    final sorted = sortedByStart(cycles);
    final lastStart = _dateOnly(sorted.last.startDate);
    final averageLength = calculateAverageCycleLength(cycles);
    final reference = _dateOnly(today ?? DateTime.now());

    var next = DateTime(
      lastStart.year,
      lastStart.month,
      lastStart.day + averageLength,
    );
    while (next.isBefore(reference)) {
      next = DateTime(next.year, next.month, next.day + averageLength);
    }
    return next;
  }

  /// Get next predicted ovulation date
  static DateTime? predictNextOvulation(
    List<MenstrualCycleModel> cycles, {
    DateTime? today,
  }) {
    final nextPeriod = predictNextPeriod(cycles, today: today);
    if (nextPeriod == null) return null;

    // Ovulation is typically 14 days before next period
    return DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day - 14);
  }

  /// Get fertile window for next cycle
  static List<DateTime>? predictFertileWindow(
    List<MenstrualCycleModel> cycles, {
    DateTime? today,
  }) {
    final ovulationDate = predictNextOvulation(cycles, today: today);
    if (ovulationDate == null) return null;

    final fertileWindow = <DateTime>[];
    // 5 days before ovulation
    for (int i = 5; i >= 0; i--) {
      fertileWindow.add(
        DateTime(
          ovulationDate.year,
          ovulationDate.month,
          ovulationDate.day - i,
        ),
      );
    }
    // 1 day after ovulation
    fertileWindow.add(
      DateTime(ovulationDate.year, ovulationDate.month, ovulationDate.day + 1),
    );

    return fertileWindow;
  }
}
