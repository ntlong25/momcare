/// One fetal movement counting session (Phase 20, B10 "Đếm cử động thai").
/// Stored locally only (see `KickCounterService`).
class KickSession {
  /// Count at which [tenthKickAt] is recorded.
  static const int target = 10;

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int count;

  /// When the [target]-th movement was counted, if reached.
  final DateTime? tenthKickAt;

  const KickSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.count = 0,
    this.tenthKickAt,
  });

  factory KickSession.start(DateTime at) =>
      KickSession(id: at.microsecondsSinceEpoch.toString(), startedAt: at);

  bool get isActive => endedAt == null;

  KickSession addKick(DateTime at) {
    final next = count + 1;
    return KickSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      count: next,
      tenthKickAt: tenthKickAt ?? (next == target ? at : null),
    );
  }

  /// Removes the last movement; going below [target] clears [tenthKickAt].
  KickSession undoKick() {
    if (count <= 0) return this;
    final next = count - 1;
    return KickSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      count: next,
      tenthKickAt: next < target ? null : tenthKickAt,
    );
  }

  KickSession stop(DateTime at) => KickSession(
    id: id,
    startedAt: startedAt,
    endedAt: at.isBefore(startedAt) ? startedAt : at,
    count: count,
    tenthKickAt: tenthKickAt,
  );

  /// Time since the start: up to [now] while active, else up to [endedAt].
  Duration elapsed(DateTime now) {
    final end = endedAt ?? now;
    final value = end.difference(startedAt);
    return value.isNegative ? Duration.zero : value;
  }

  /// Time from the start to the [target]-th movement, if reached.
  Duration? get timeToTen => tenthKickAt?.difference(startedAt);

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
    'count': count,
    if (tenthKickAt != null) 'tenthKickAt': tenthKickAt!.toIso8601String(),
  };

  /// Never throws: returns null when [json] has no valid `startedAt`.
  static KickSession? fromJson(Object? json) {
    if (json is! Map) return null;
    DateTime? date(String key) {
      final value = json[key];
      return value is String ? DateTime.tryParse(value) : null;
    }

    final startedAt = date('startedAt');
    if (startedAt == null) return null;
    final rawCount = json['count'];
    final count = rawCount is int && rawCount > 0 ? rawCount : 0;
    final rawId = json['id'];
    var endedAt = date('endedAt');
    if (endedAt != null && endedAt.isBefore(startedAt)) endedAt = startedAt;
    final tenth = date('tenthKickAt');
    return KickSession(
      id: rawId is String && rawId.isNotEmpty
          ? rawId
          : startedAt.microsecondsSinceEpoch.toString(),
      startedAt: startedAt,
      endedAt: endedAt,
      count: count,
      tenthKickAt: count >= target ? tenth : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KickSession &&
      other.id == id &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.count == count &&
      other.tenthKickAt == tenthKickAt;

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, count, tenthKickAt);
}
