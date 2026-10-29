import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists the local dates (`yyyy-MM-dd`) on which the daily thai giáo
/// activity was marked done, following `GuideProgressService`.
class ThaiGiaoProgressService {
  /// Local calendar date key, e.g. `2026-10-29`.
  static String dateKey(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${two(date.month)}-${two(date.day)}';
  }

  static Future<Set<String>> loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.thaiGiaoDoneKey);
    if (raw == null) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toSet();
    } catch (_) {
      // Corrupt value: start fresh rather than crash.
    }
    return <String>{};
  }

  static Future<void> saveDone(Set<String> done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.thaiGiaoDoneKey,
      jsonEncode(done.toList()..sort()),
    );
  }

  static Future<Set<String>> setDone(DateTime day, bool done) async {
    final current = await loadDone();
    if (done) {
      current.add(dateKey(day));
    } else {
      current.remove(dateKey(day));
    }
    await saveDone(current);
    return current;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.thaiGiaoDoneKey);
  }

  /// Consecutive done days ending today (when today is done) or yesterday
  /// (otherwise, so the streak is not lost before the day is over).
  static int streakAt(Set<String> done, DateTime now) {
    if (done.isEmpty) return 0;
    var cursor = DateTime(now.year, now.month, now.day);
    if (!done.contains(dateKey(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var streak = 0;
    while (done.contains(dateKey(cursor))) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }
}

/// Shared done-dates state so the Hôm nay card updates immediately.
class ThaiGiaoProgressNotifier extends StateNotifier<Set<String>> {
  ThaiGiaoProgressNotifier() : super(const <String>{}) {
    _loading = _load();
  }

  late final Future<void> _loading;

  Future<void> _load() async {
    final done = await ThaiGiaoProgressService.loadDone();
    if (mounted) state = done;
  }

  /// Completes once persisted done dates are loaded.
  Future<void> get ready => _loading;

  bool isDone(DateTime day) =>
      state.contains(ThaiGiaoProgressService.dateKey(day));

  int streakAt(DateTime now) => ThaiGiaoProgressService.streakAt(state, now);

  Future<void> setDone(DateTime day, bool done) async {
    await _loading;
    final key = ThaiGiaoProgressService.dateKey(day);
    final next = {...state};
    if (done) {
      next.add(key);
    } else {
      next.remove(key);
    }
    state = next;
    await ThaiGiaoProgressService.saveDone(next);
  }

  /// Clears in-memory state (persisted dates are removed by the caller, e.g.
  /// the delete-all-data flow).
  void resetLocal() {
    state = const <String>{};
  }
}

final thaiGiaoProgressProvider =
    StateNotifierProvider<ThaiGiaoProgressNotifier, Set<String>>(
      (ref) => ThaiGiaoProgressNotifier(),
    );
