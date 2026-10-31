import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../models/fertility_log_model.dart';
import 'database_service.dart';

/// Reads and writes the daily fertility signals and the preferences of that
/// screen. Everything stays in encrypted Hive boxes, never in
/// SharedPreferences, and this class deliberately logs nothing.
///
/// A closed box (isolated widget tests) reads as empty.
class FertilityLogService {
  const FertilityLogService._();

  static const String _showIntimacyKey = 'show_intimacy';

  static bool get _logsOpen => Hive.isBoxOpen(AppConstants.fertilityLogBox);

  /// Valid records, newest day first.
  static List<FertilityLogModel> all() {
    if (!_logsOpen) return const [];
    return DatabaseService.fertilityLogBox.values
        .where((log) => log.isValid)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static FertilityLogModel? forDay(DateTime day) {
    if (!_logsOpen) return null;
    final log = DatabaseService.fertilityLogBox.get(
      FertilityLogModel.dayKey(day),
    );
    return log != null && log.isValid ? log : null;
  }

  /// Days with a positive or peak LH test, oldest first.
  static List<DateTime> positiveLhDays() =>
      FertilityLogModel.positiveLhDays(all());

  /// Stores the record of its day, replacing an earlier one. A record with
  /// nothing in it removes the day. Future days are refused: a test that has
  /// not happened must not move today's estimate.
  static Future<bool> save(FertilityLogModel log, {DateTime? today}) async {
    if (!_logsOpen || !log.isValid) return false;
    final now = today ?? DateTime.now();
    if (log.date.isAfter(DateTime(now.year, now.month, now.day))) return false;
    if (log.isEmpty) {
      await deleteDay(log.date);
      return true;
    }
    await DatabaseService.fertilityLogBox.put(
      FertilityLogModel.dayKey(log.date),
      log,
    );
    return true;
  }

  static Future<void> deleteDay(DateTime day) async {
    if (!_logsOpen) return;
    await DatabaseService.fertilityLogBox.delete(FertilityLogModel.dayKey(day));
  }

  /// Off by default: "Ngày gần gũi" and its marker stay hidden until enabled.
  static bool get showIntimacy {
    if (!Hive.isBoxOpen(AppConstants.fertilityPrefsBox)) return false;
    return DatabaseService.fertilityPrefsBox.get(_showIntimacyKey) == true;
  }

  static Future<void> setShowIntimacy(bool value) async {
    if (!Hive.isBoxOpen(AppConstants.fertilityPrefsBox)) return;
    await DatabaseService.fertilityPrefsBox.put(_showIntimacyKey, value);
  }
}
