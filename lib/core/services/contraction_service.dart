import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/contraction.dart';

/// Last-hour figures shown on the contraction timer.
class ContractionSummary {
  final int count;
  final Duration? averageDuration;
  final Duration? averageInterval;

  const ContractionSummary({
    required this.count,
    this.averageDuration,
    this.averageInterval,
  });
}

/// Persists timed contractions as JSON under [AppConstants.contractionsKey],
/// oldest first, plus pure helpers for the summary and the 5-1-1 pattern.
class ContractionService {
  static const int maxEntries = 300;

  /// Window used by [summarize].
  static const Duration summaryWindow = Duration(minutes: 60);

  /// 5-1-1: contractions at most 5 minutes apart (start to start)...
  static const Duration fiveOneOneMaxInterval = Duration(minutes: 5);

  /// ...each lasting at least 1 minute...
  static const Duration fiveOneOneMinDuration = Duration(minutes: 1);

  /// ...for at least 1 hour (first start to last start).
  static const Duration fiveOneOneMinSpan = Duration(minutes: 60);

  /// Oldest first, at most [maxEntries], and only the newest entry may be
  /// running.
  static List<Contraction> normalize(Iterable<Contraction> entries) {
    final sorted = entries.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final result = <Contraction>[
      for (var i = 0; i < sorted.length; i++)
        if (!sorted[i].isActive || i == sorted.length - 1) sorted[i],
    ];
    if (result.length <= maxEntries) return result;
    return result.sublist(result.length - maxEntries);
  }

  /// Never throws: corrupt values give an empty list and invalid entries
  /// are skipped.
  static List<Contraction> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return normalize(
        decoded.map(Contraction.fromJson).whereType<Contraction>(),
      );
    } catch (_) {
      return const [];
    }
  }

  static String encode(List<Contraction> entries) =>
      jsonEncode(entries.map((entry) => entry.toJson()).toList());

  static Future<List<Contraction>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(AppConstants.contractionsKey));
  }

  static Future<void> save(List<Contraction> entries) async {
    final prefs = await SharedPreferences.getInstance();
    if (entries.isEmpty) {
      await prefs.remove(AppConstants.contractionsKey);
      return;
    }
    await prefs.setString(AppConstants.contractionsKey, encode(entries));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.contractionsKey);
  }

  /// Start-to-start time from the previous entry in [entries] (oldest
  /// first); null for the first one.
  static Duration? intervalBefore(List<Contraction> entries, int index) {
    if (index <= 0 || index >= entries.length) return null;
    return entries[index].startedAt.difference(entries[index - 1].startedAt);
  }

  /// Completed contractions that started within [summaryWindow] before
  /// [now]: count, average duration and average start-to-start interval.
  static ContractionSummary summarize(List<Contraction> entries, DateTime now) {
    final from = now.subtract(summaryWindow);
    final recent = entries
        .where((entry) => !entry.isActive && !entry.startedAt.isBefore(from))
        .toList();
    if (recent.isEmpty) return const ContractionSummary(count: 0);
    final totalDuration = recent.fold<int>(
      0,
      (sum, entry) => sum + entry.duration!.inMilliseconds,
    );
    Duration? averageInterval;
    if (recent.length > 1) {
      final span = recent.last.startedAt.difference(recent.first.startedAt);
      averageInterval = Duration(
        milliseconds: span.inMilliseconds ~/ (recent.length - 1),
      );
    }
    return ContractionSummary(
      count: recent.length,
      averageDuration: Duration(milliseconds: totalDuration ~/ recent.length),
      averageInterval: averageInterval,
    );
  }

  /// True when the newest run of completed contractions, each at most
  /// [fiveOneOneMaxInterval] apart and each lasting at least
  /// [fiveOneOneMinDuration], spans at least [fiveOneOneMinSpan].
  /// A running contraction is ignored.
  static bool matches511(List<Contraction> entries) {
    final completed = entries.where((entry) => !entry.isActive).toList();
    if (completed.isEmpty) return false;
    final last = completed.last;
    if (last.duration! < fiveOneOneMinDuration) return false;
    var first = last;
    for (var i = completed.length - 2; i >= 0; i--) {
      final previous = completed[i];
      final interval = completed[i + 1].startedAt.difference(
        previous.startedAt,
      );
      if (interval > fiveOneOneMaxInterval) break;
      if (previous.duration! < fiveOneOneMinDuration) break;
      first = previous;
    }
    return last.startedAt.difference(first.startedAt) >= fiveOneOneMinSpan;
  }
}

/// Contraction log state, oldest first.
class ContractionNotifier extends StateNotifier<List<Contraction>> {
  ContractionNotifier({DateTime Function()? now})
    : now = now ?? DateTime.now,
      super(const []) {
    _loading = _load();
  }

  /// Clock used for new events and running time (fixed in tests).
  final DateTime Function() now;

  late final Future<void> _loading;

  Future<void> _load() async {
    final entries = await ContractionService.load();
    if (mounted) state = entries;
  }

  /// Completes once the persisted log is loaded.
  Future<void> get ready => _loading;

  Contraction? get active =>
      state.isNotEmpty && state.last.isActive ? state.last : null;

  Future<void> _set(Iterable<Contraction> entries) async {
    state = ContractionService.normalize(entries);
    await ContractionService.save(state);
  }

  /// Starts a contraction, or ends the running one.
  Future<void> toggle() async {
    await _loading;
    final current = active;
    if (current == null) {
      await _set([...state, Contraction(startedAt: now())]);
    } else {
      await _set([...state.sublist(0, state.length - 1), current.end(now())]);
    }
  }

  Future<void> delete(Contraction entry) async {
    await _loading;
    await _set(state.where((item) => item != entry));
  }

  /// Removes completed contractions; a running one is kept.
  Future<void> clearHistory() async {
    await _loading;
    await _set(state.where((entry) => entry.isActive));
  }

  /// Clears the in-memory log (the persisted one is removed by the caller,
  /// e.g. the delete-all-data flow).
  void resetLocal() {
    state = const [];
  }
}

final contractionProvider =
    StateNotifierProvider<ContractionNotifier, List<Contraction>>(
      (ref) => ContractionNotifier(),
    );
