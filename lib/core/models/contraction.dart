/// One timed contraction (Phase 20, B10 "Đếm cơn co").
/// Stored locally only (see `ContractionService`).
class Contraction {
  final DateTime startedAt;
  final DateTime? endedAt;

  const Contraction({required this.startedAt, this.endedAt});

  bool get isActive => endedAt == null;

  /// Length of a completed contraction; null while it is running.
  Duration? get duration => endedAt?.difference(startedAt);

  /// Running time up to [now] while active, else [duration].
  Duration elapsed(DateTime now) {
    final value = (endedAt ?? now).difference(startedAt);
    return value.isNegative ? Duration.zero : value;
  }

  Contraction end(DateTime at) => Contraction(
    startedAt: startedAt,
    endedAt: at.isBefore(startedAt) ? startedAt : at,
  );

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
  };

  /// Never throws: returns null without a valid `startedAt`, or when
  /// `endedAt` is before `startedAt`.
  static Contraction? fromJson(Object? json) {
    if (json is! Map) return null;
    DateTime? date(String key) {
      final value = json[key];
      return value is String ? DateTime.tryParse(value) : null;
    }

    final startedAt = date('startedAt');
    if (startedAt == null) return null;
    final rawEnd = json['endedAt'];
    final endedAt = date('endedAt');
    if (rawEnd != null && endedAt == null) return null;
    if (endedAt != null && endedAt.isBefore(startedAt)) return null;
    return Contraction(startedAt: startedAt, endedAt: endedAt);
  }

  @override
  bool operator ==(Object other) =>
      other is Contraction &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(startedAt, endedAt);
}
