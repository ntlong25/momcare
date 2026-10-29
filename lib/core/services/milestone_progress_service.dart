import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'thai_giao_progress_service.dart';

/// Persists the date each checkup/vaccination milestone was marked done, as a
/// JSON map `{itemId: 'yyyy-MM-dd'}` (see `GuideProgressService`).
class MilestoneProgressService {
  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Parses a strict `yyyy-MM-dd` local date; null for anything else.
  static DateTime? parseDate(Object? value) {
    if (value is! String) return null;
    final match = _datePattern.firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // Reject overflowing dates such as 2026-02-31.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static Map<String, DateTime> decode(String? raw) {
    if (raw == null) return <String, DateTime>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, DateTime>{};
      final result = <String, DateTime>{};
      decoded.forEach((key, value) {
        final date = parseDate(value);
        if (key is String && key.isNotEmpty && date != null) {
          result[key] = date;
        }
      });
      return result;
    } catch (_) {
      // Corrupt value: start fresh rather than crash.
      return <String, DateTime>{};
    }
  }

  static String encode(Map<String, DateTime> done) {
    final ids = done.keys.toList()..sort();
    return jsonEncode({
      for (final id in ids) id: ThaiGiaoProgressService.dateKey(done[id]!),
    });
  }

  static Future<Map<String, DateTime>> loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(AppConstants.milestoneDoneKey));
  }

  static Future<void> saveDone(Map<String, DateTime> done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.milestoneDoneKey, encode(done));
  }

  static Future<Map<String, DateTime>> setDone(String id, DateTime date) async {
    final current = await loadDone();
    current[id] = DateTime(date.year, date.month, date.day);
    await saveDone(current);
    return current;
  }

  static Future<Map<String, DateTime>> clearDone(String id) async {
    final current = await loadDone();
    current.remove(id);
    await saveDone(current);
    return current;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.milestoneDoneKey);
  }
}

/// Shared done-dates so the guide timeline and the Hôm nay card stay in sync.
class MilestoneProgressNotifier extends StateNotifier<Map<String, DateTime>> {
  MilestoneProgressNotifier() : super(const <String, DateTime>{}) {
    _loading = _load();
  }

  late final Future<void> _loading;

  Future<void> _load() async {
    final done = await MilestoneProgressService.loadDone();
    if (mounted) state = done;
  }

  /// Completes once persisted done dates are loaded.
  Future<void> get ready => _loading;

  Future<void> markDone(String id, DateTime date) async {
    await _loading;
    final next = {...state, id: DateTime(date.year, date.month, date.day)};
    state = next;
    await MilestoneProgressService.saveDone(next);
  }

  Future<void> unmark(String id) async {
    await _loading;
    final next = {...state}..remove(id);
    state = next;
    await MilestoneProgressService.saveDone(next);
  }

  /// Clears in-memory state (persisted dates are removed by the caller, e.g.
  /// the delete-all-data flow).
  void resetLocal() {
    state = const <String, DateTime>{};
  }
}

final milestoneProgressProvider =
    StateNotifierProvider<MilestoneProgressNotifier, Map<String, DateTime>>(
      (ref) => MilestoneProgressNotifier(),
    );
