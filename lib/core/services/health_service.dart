import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/menstrual_cycle_model.dart';
import '../utils/app_logger.dart';

/// Service to interact with Apple Health (iOS) and Google Fit (Android)
/// for menstrual cycle data
class HealthService {
  static final AppLogger _logger = AppLogger();
  static Health? _health;

  /// Initialize the health service
  static Future<void> init() async {
    _health = Health();
    _logger.info('HealthService initialized');
  }

  /// Check if health data access is available on this platform
  static bool get isAvailable {
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Request authorization to access menstrual cycle data
  static Future<bool> requestAuthorization() async {
    if (!isAvailable) {
      _logger.warning('Health data not available on this platform');
      return false;
    }

    try {
      final types = [
        HealthDataType.MENSTRUATION,
      ];

      final permissions = [
        HealthDataAccess.READ,
      ];

      final bool? authorized = await _health?.requestAuthorization(
        types,
        permissions: permissions,
      );

      _logger.info('Health authorization result: $authorized');
      return authorized ?? false;
    } catch (e, stackTrace) {
      _logger.error('Error requesting health authorization',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Check if we have permission to access health data
  static Future<bool> hasPermissions() async {
    if (!isAvailable) return false;

    try {
      final types = [HealthDataType.MENSTRUATION];
      final permissions = await _health?.hasPermissions(types);
      return permissions ?? false;
    } catch (e, stackTrace) {
      _logger.error('Error checking health permissions',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Fetch menstrual cycle data from HealthKit/Google Fit
  /// Returns list of MenstrualCycleModel from the last [days] days
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

      final types = [HealthDataType.MENSTRUATION];

      final bool? hasPermission = await _health?.hasPermissions(types);
      if (hasPermission != true) {
        _logger.warning('No permission to access health data');
        return [];
      }

      final List<HealthDataPoint> healthData =
          await _health?.getHealthDataFromTypes(
                startDate: startTime,
                endDate: now,
                types: types,
              ) ??
              [];

      _logger.info('Fetched ${healthData.length} menstrual data points');

      // Group data points by start date to create cycles
      final Map<DateTime, List<HealthDataPoint>> groupedByDate = {};

      for (var point in healthData) {
        final date = DateTime(
          point.dateFrom.year,
          point.dateFrom.month,
          point.dateFrom.day,
        );

        if (!groupedByDate.containsKey(date)) {
          groupedByDate[date] = [];
        }
        groupedByDate[date]!.add(point);
      }

      // Convert to MenstrualCycleModel
      final List<MenstrualCycleModel> cycles = [];
      final sortedDates = groupedByDate.keys.toList()..sort();

      DateTime? currentCycleStart;
      DateTime? previousCycleStart;

      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final points = groupedByDate[date]!;

        // Check if this is a new cycle (gap of more than 2 days)
        if (currentCycleStart == null ||
            date.difference(currentCycleStart).inDays > 2) {
          // Save previous cycle if exists
          if (currentCycleStart != null) {
            int? cycleLength;
            if (previousCycleStart != null) {
              cycleLength = currentCycleStart.difference(previousCycleStart).inDays;
            }

            cycles.add(MenstrualCycleModel(
              id: const Uuid().v4(),
              startDate: previousCycleStart ?? currentCycleStart,
              endDate: currentCycleStart.subtract(const Duration(days: 1)),
              cycleLengthDays: cycleLength,
              periodLengthDays: null, // Will be calculated below
              isFromHealthKit: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }

          previousCycleStart = currentCycleStart;
          currentCycleStart = date;
        }
      }

      // Add the last cycle
      if (currentCycleStart != null) {
        int? cycleLength;
        if (previousCycleStart != null) {
          cycleLength = currentCycleStart.difference(previousCycleStart).inDays;
        }

        cycles.add(MenstrualCycleModel(
          id: const Uuid().v4(),
          startDate: previousCycleStart ?? currentCycleStart,
          cycleLengthDays: cycleLength,
          isFromHealthKit: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      _logger.info('Converted to ${cycles.length} menstrual cycles');
      return cycles;
    } catch (e, stackTrace) {
      _logger.error('Error fetching menstrual data',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Calculate average cycle length from a list of cycles
  static int calculateAverageCycleLength(List<MenstrualCycleModel> cycles) {
    if (cycles.isEmpty) return 28; // Default average

    final validCycles = cycles
        .where((c) => c.cycleLengthDays != null && c.cycleLengthDays! > 0)
        .toList();

    if (validCycles.isEmpty) return 28;

    final total = validCycles.fold<int>(
      0,
      (sum, cycle) => sum + cycle.cycleLengthDays!,
    );

    return (total / validCycles.length).round();
  }

  /// Check if cycles are regular (more than 70% within 3 days of average)
  static bool areCyclesRegular(List<MenstrualCycleModel> cycles) {
    if (cycles.length < 3) return false; // Need at least 3 cycles

    final averageLength = calculateAverageCycleLength(cycles);
    final regularCycles =
        cycles.where((c) => c.isRegular(averageLength)).length;

    return (regularCycles / cycles.length) >= 0.7; // 70% threshold
  }

  /// Get next predicted period date
  static DateTime? predictNextPeriod(List<MenstrualCycleModel> cycles) {
    if (cycles.isEmpty) return null;

    // Sort by start date descending
    final sortedCycles = List<MenstrualCycleModel>.from(cycles)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final lastCycle = sortedCycles.first;
    final averageLength = calculateAverageCycleLength(cycles);

    return lastCycle.startDate.add(Duration(days: averageLength));
  }

  /// Get next predicted ovulation date
  static DateTime? predictNextOvulation(List<MenstrualCycleModel> cycles) {
    final nextPeriod = predictNextPeriod(cycles);
    if (nextPeriod == null) return null;

    // Ovulation is typically 14 days before next period
    return nextPeriod.subtract(const Duration(days: 14));
  }

  /// Get fertile window for next cycle
  static List<DateTime>? predictFertileWindow(
      List<MenstrualCycleModel> cycles) {
    final ovulationDate = predictNextOvulation(cycles);
    if (ovulationDate == null) return null;

    final fertileWindow = <DateTime>[];
    // 5 days before ovulation
    for (int i = 5; i >= 0; i--) {
      fertileWindow.add(ovulationDate.subtract(Duration(days: i)));
    }
    // 1 day after ovulation
    fertileWindow.add(ovulationDate.add(const Duration(days: 1)));

    return fertileWindow;
  }
}
