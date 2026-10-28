import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists Cẩm nang checklist ticks by globally unique item id, following the
/// SharedPreferences pattern of `MaternalHabitService`.
class GuideProgressService {
  static Future<Set<String>> loadTicked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.guideChecklistKey);
    if (raw == null) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toSet();
    } catch (_) {
      // Corrupt value: start fresh rather than crash.
    }
    return <String>{};
  }

  static Future<void> saveTicked(Set<String> ticked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.guideChecklistKey,
      jsonEncode(ticked.toList()..sort()),
    );
  }

  static Future<Set<String>> setTicked(String itemId, bool ticked) async {
    final current = await loadTicked();
    if (ticked) {
      current.add(itemId);
    } else {
      current.remove(itemId);
    }
    await saveTicked(current);
    return current;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.guideChecklistKey);
  }
}

/// Shared tick state so the Cẩm nang grid and detail screen stay in sync.
class GuideChecklistNotifier extends StateNotifier<Set<String>> {
  GuideChecklistNotifier() : super(const <String>{}) {
    _loading = _load();
  }

  late final Future<void> _loading;

  Future<void> _load() async {
    final ticked = await GuideProgressService.loadTicked();
    if (mounted) state = ticked;
  }

  /// Completes once persisted ticks are loaded.
  Future<void> get ready => _loading;

  Future<void> toggle(String itemId, bool ticked) async {
    await _loading;
    final next = {...state};
    if (ticked) {
      next.add(itemId);
    } else {
      next.remove(itemId);
    }
    state = next;
    await GuideProgressService.saveTicked(next);
  }

  /// Clears in-memory ticks (persisted ticks are removed by the caller, e.g.
  /// the delete-all-data flow).
  void resetLocal() {
    state = const <String>{};
  }
}

final guideChecklistProvider =
    StateNotifierProvider<GuideChecklistNotifier, Set<String>>(
      (ref) => GuideChecklistNotifier(),
    );
