/// One photo in "Nhật ký ảnh bụng bầu" (Phase 21, B10). The image file lives
/// in `<app documents>/bump_photos/`; only its [fileName] is stored (see
/// `BumpPhotoService`), because the iOS container path changes between
/// installs and updates.
class BumpPhoto {
  static const int minWeek = 0;
  static const int maxWeek = 42;

  final String id;
  final int week;
  final String fileName;
  final DateTime addedAt;
  final DateTime? takenAt;

  const BumpPhoto({
    required this.id,
    required this.week,
    required this.fileName,
    required this.addedAt,
    this.takenAt,
  });

  /// Date shown for the photo: [takenAt] when known, else [addedAt].
  DateTime get displayDate => takenAt ?? addedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'week': week,
    'fileName': fileName,
    'addedAt': addedAt.toIso8601String(),
    if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
  };

  /// Never throws: returns null for a missing id/fileName, a week outside
  /// [minWeek]-[maxWeek] or a bad date.
  static BumpPhoto? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final fileName = json['fileName'];
    final week = json['week'];
    final addedRaw = json['addedAt'];
    if (id is! String || id.isEmpty) return null;
    if (fileName is! String || fileName.isEmpty) return null;
    // A stored name must stay inside the photos folder.
    if (fileName.contains('/') || fileName.contains('\\')) return null;
    if (week is! int || week < minWeek || week > maxWeek) return null;
    final addedAt = addedRaw is String ? DateTime.tryParse(addedRaw) : null;
    if (addedAt == null) return null;
    final takenRaw = json['takenAt'];
    DateTime? takenAt;
    if (takenRaw != null) {
      takenAt = takenRaw is String ? DateTime.tryParse(takenRaw) : null;
      if (takenAt == null) return null;
    }
    return BumpPhoto(
      id: id,
      week: week,
      fileName: fileName,
      addedAt: addedAt,
      takenAt: takenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BumpPhoto &&
      other.id == id &&
      other.week == week &&
      other.fileName == fileName &&
      other.addedAt == addedAt &&
      other.takenAt == takenAt;

  @override
  int get hashCode => Object.hash(id, week, fileName, addedAt, takenAt);
}
