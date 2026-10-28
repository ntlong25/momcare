/// Filter chips for nutrition guides and recipes.
///
/// Bundled guides use week-range categories ("Tuần 0-12") while recipes use
/// trimester labels ("Tam cá nguyệt 1"). A chip matches either form.
class NutritionStage {
  final String label;
  final int? weekStart;
  final int? weekEnd;

  const NutritionStage(this.label, {this.weekStart, this.weekEnd});
}

class NutritionFilter {
  static const String all = 'Tất cả';

  static const List<NutritionStage> stages = [
    NutritionStage('Tam cá nguyệt 1', weekStart: 1, weekEnd: 13),
    NutritionStage('Tam cá nguyệt 2', weekStart: 14, weekEnd: 27),
    NutritionStage('Tam cá nguyệt 3', weekStart: 28, weekEnd: 42),
    NutritionStage('Sau sinh'),
  ];

  static final RegExp _weekRange = RegExp(r'Tuần\s*(\d+)\s*[-–]\s*(\d+)');

  /// Parses "Tuần a-b" into (a, b). Returns null for other categories.
  static (int, int)? weekRangeOf(String category) {
    final match = _weekRange.firstMatch(category);
    if (match == null) return null;
    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2)!);
    return start <= end ? (start, end) : (end, start);
  }

  static bool matches(String category, String chip) {
    if (chip == all) return true;
    if (category == chip) return true;
    final stage = stages.where((s) => s.label == chip).firstOrNull;
    if (stage == null || stage.weekStart == null || stage.weekEnd == null) {
      return false;
    }
    final range = weekRangeOf(category);
    if (range == null) return false;
    return range.$1 <= stage.weekEnd! && range.$2 >= stage.weekStart!;
  }

  /// "Tất cả" plus only the chips that match at least one category, so no
  /// chip leads to an empty list.
  static List<String> chipsFor(Iterable<String> categories) {
    final list = categories.toList();
    return [
      all,
      for (final stage in stages)
        if (list.any((c) => matches(c, stage.label))) stage.label,
    ];
  }
}
