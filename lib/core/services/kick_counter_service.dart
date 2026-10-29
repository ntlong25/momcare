import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/kick_session.dart';

/// Persists kick counting sessions as JSON under
/// [AppConstants.kickSessionsKey], newest first.
class KickCounterService {
  /// Completed sessions kept; the active session comes on top of this.
  static const int maxHistory = 100;

  /// Newest first, at most one active session (the newest one) and at most
  /// [maxHistory] completed sessions.
  static List<KickSession> normalize(Iterable<KickSession> sessions) {
    final sorted = sessions.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final result = <KickSession>[];
    var hasActive = false;
    var completed = 0;
    for (final session in sorted) {
      if (session.isActive) {
        if (hasActive) continue;
        hasActive = true;
        result.add(session);
      } else {
        if (completed >= maxHistory) continue;
        completed++;
        result.add(session);
      }
    }
    return result;
  }

  /// Never throws: corrupt values give an empty list and invalid entries
  /// are skipped.
  static List<KickSession> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return normalize(
        decoded.map(KickSession.fromJson).whereType<KickSession>(),
      );
    } catch (_) {
      return const [];
    }
  }

  static String encode(List<KickSession> sessions) =>
      jsonEncode(sessions.map((session) => session.toJson()).toList());

  static Future<List<KickSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(AppConstants.kickSessionsKey));
  }

  static Future<void> save(List<KickSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    if (sessions.isEmpty) {
      await prefs.remove(AppConstants.kickSessionsKey);
      return;
    }
    await prefs.setString(AppConstants.kickSessionsKey, encode(sessions));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kickSessionsKey);
  }
}

/// Kick counter state: all sessions, newest first.
class KickCounterNotifier extends StateNotifier<List<KickSession>> {
  KickCounterNotifier({DateTime Function()? now})
    : now = now ?? DateTime.now,
      super(const []) {
    _loading = _load();
  }

  /// Clock used for new events and elapsed time (fixed in tests).
  final DateTime Function() now;

  late final Future<void> _loading;

  Future<void> _load() async {
    final sessions = await KickCounterService.load();
    if (mounted) state = sessions;
  }

  /// Completes once the persisted sessions are loaded.
  Future<void> get ready => _loading;

  KickSession? get active {
    for (final session in state) {
      if (session.isActive) return session;
    }
    return null;
  }

  /// Completed sessions, newest first.
  List<KickSession> get history =>
      state.where((session) => !session.isActive).toList();

  Future<void> _set(Iterable<KickSession> sessions) async {
    state = KickCounterService.normalize(sessions);
    await KickCounterService.save(state);
  }

  Future<void> _updateActive(KickSession Function(KickSession) update) async {
    await _loading;
    final current = active;
    if (current == null) return;
    await _set([
      for (final session in state)
        session.id == current.id ? update(session) : session,
    ]);
  }

  /// Starts a session unless one is already running.
  Future<void> start() async {
    await _loading;
    if (active != null) return;
    await _set([KickSession.start(now()), ...state]);
  }

  Future<void> kick() => _updateActive((session) => session.addKick(now()));

  Future<void> undo() => _updateActive((session) => session.undoKick());

  /// Ends the active session; a session with no movements is discarded.
  Future<void> stop() async {
    await _loading;
    final current = active;
    if (current == null) return;
    if (current.count == 0) {
      await _set(state.where((session) => session.id != current.id));
      return;
    }
    final stopped = current.stop(now());
    await _set([
      for (final session in state) session.id == current.id ? stopped : session,
    ]);
  }

  Future<void> delete(String id) async {
    await _loading;
    await _set(state.where((session) => session.id != id));
  }

  /// Removes completed sessions; a running session is kept.
  Future<void> clearHistory() async {
    await _loading;
    await _set(state.where((session) => session.isActive));
  }

  /// Clears the in-memory sessions (the persisted ones are removed by the
  /// caller, e.g. the delete-all-data flow).
  void resetLocal() {
    state = const [];
  }
}

final kickCounterProvider =
    StateNotifierProvider<KickCounterNotifier, List<KickSession>>(
      (ref) => KickCounterNotifier(),
    );
