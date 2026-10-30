import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/menstrual_cycle_model.dart';
import '../utils/app_logger.dart';
import 'cycle_prediction.dart';

export 'cycle_prediction.dart' show CycleRegularity;

/// Service to interact with Apple Health (iOS) and Health Connect (Android)
/// for menstrual cycle data, plus pure cycle prediction helpers.
class HealthService {
  static final AppLogger _logger = AppLogger.instance;
  static Health? _health;
  static Future<void>? _initFuture;

  /// Minimum number of cycles before regularity is evaluated.
  static const int minCyclesForRegularity = CycleStats.minCyclesForRegularity;

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

  static DateTime _dateOnly(DateTime date) => CycleStats.dateOnly(date);

  static int _daysBetween(DateTime from, DateTime to) =>
      CycleStats.daysBetween(from, to);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Cycles sorted by start date (oldest first).
  static List<MenstrualCycleModel> sortedByStart(
    List<MenstrualCycleModel> cycles,
  ) => CycleStats.sortedByStart(cycles);

  /// Cycle lengths derived from consecutive start dates after sorting.
  static List<int> cycleLengths(List<MenstrualCycleModel> cycles) =>
      CycleStats.cycleLengths(cycles);

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
  static int calculateAverageCycleLength(List<MenstrualCycleModel> cycles) =>
      CycleStats.averageCycleLength(cycles);

  /// Regularity with an explicit "not enough data" state.
  static CycleRegularity cycleRegularity(List<MenstrualCycleModel> cycles) =>
      CycleStats.regularity(cycles);

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
  }) => CycleStats.predictNextPeriod(cycles, today: today ?? DateTime.now());

  /// See [CycleStats.expectedPeriodDate].
  static DateTime? expectedPeriodDate(List<MenstrualCycleModel> cycles) =>
      CycleStats.expectedPeriodDate(cycles);

  /// Days past [expectedPeriodDate] as of [today] (default: now); 0 when not
  /// late or when there are no cycles.
  static int daysLate(List<MenstrualCycleModel> cycles, {DateTime? today}) =>
      CycleStats.daysLate(cycles, today: today ?? DateTime.now());

  /// See [CycleStats.isDataStale].
  static bool isCycleDataStale(
    List<MenstrualCycleModel> cycles, {
    DateTime? today,
  }) => CycleStats.isDataStale(cycles, today: today ?? DateTime.now());

  /// Mid estimate of the next ovulation; see [CyclePrediction].
  static DateTime? predictNextOvulation(
    List<MenstrualCycleModel> cycles, {
    DateTime? today,
  }) => CyclePrediction.compute(
    cycles,
    today: today ?? DateTime.now(),
  )?.ovulation;

  /// Every day of the fertile window; see [CyclePrediction].
  static List<DateTime>? predictFertileWindow(
    List<MenstrualCycleModel> cycles, {
    DateTime? today,
  }) => CyclePrediction.compute(
    cycles,
    today: today ?? DateTime.now(),
  )?.fertileDays;
}
