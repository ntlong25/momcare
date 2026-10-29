/// Daily thai giáo activities and daily tips from
/// `assets/content/daily/thai_giao.json` and `daily/daily_tips.json`
/// (see CONTENT_SCHEMA.md, section 3).
library;

import 'guide_models.dart';

class DailyItem {
  final int day;
  final int week;
  final String category;
  final String title;
  final String body;
  final int? durationMin;
  final List<String> sources;

  const DailyItem({
    required this.day,
    required this.week,
    required this.category,
    required this.title,
    required this.body,
    this.durationMin,
    this.sources = const [],
  });

  /// Weekday slot 0..6 within the pregnancy week.
  int get slot => DailyPack.slotForDay(day);
}

class DailyPack {
  static const String thaiGiaoType = 'thai_giao';
  static const String dailyTipType = 'daily_tip';

  static const int minDay = 1;
  static const int maxDay = 294;

  static const Map<String, List<String>> categoriesByType = {
    thaiGiaoType: [
      'talk',
      'music',
      'movement',
      'reading',
      'breathing',
      'partner',
      'journal',
    ],
    dailyTipType: ['nutrition', 'body', 'mental', 'prep', 'safety'],
  };

  final String type;
  final String? lastUpdated;
  final ReviewStatus reviewStatus;

  /// Items sorted by day, one per day at most.
  final List<DailyItem> items;

  const DailyPack({
    required this.type,
    this.lastUpdated,
    this.reviewStatus = ReviewStatus.draftRequiresMedicalReview,
    this.items = const [],
  });

  const DailyPack.empty(this.type)
    : lastUpdated = null,
      reviewStatus = ReviewStatus.draftRequiresMedicalReview,
      items = const [];

  bool get isDraft => reviewStatus != ReviewStatus.approved;

  bool get isEmpty => items.isEmpty;

  static int slotForDay(int day) => (day - 1) % 7;

  static int clampDay(int day) => day.clamp(minDay, maxDay);

  /// Item for content [day] (clamped to 1..294): the exact day, else the
  /// nearest item of the category usually found on the same weekday slot,
  /// else the nearest item of any category. Ties go to the earlier day.
  /// Returns null for an empty pack.
  DailyItem? itemForDay(int day) {
    if (items.isEmpty) return null;
    final target = clampDay(day);
    for (final item in items) {
      if (item.day == target) return item;
    }

    final category = _usualCategoryForSlot(slotForDay(target));
    if (category != null) {
      final match = _nearest(
        target,
        items.where((item) => item.category == category),
      );
      if (match != null) return match;
    }
    return _nearest(target, items);
  }

  String? _usualCategoryForSlot(int slot) {
    final counts = <String, int>{};
    for (final item in items) {
      if (item.slot == slot) {
        counts[item.category] = (counts[item.category] ?? 0) + 1;
      }
    }
    String? best;
    var bestCount = 0;
    // Map preserves insertion order (by day), so a count tie keeps the
    // category seen first.
    counts.forEach((category, count) {
      if (count > bestCount) {
        best = category;
        bestCount = count;
      }
    });
    return best;
  }

  static DailyItem? _nearest(int day, Iterable<DailyItem> candidates) {
    DailyItem? best;
    var bestDistance = 1 << 30;
    for (final item in candidates) {
      final distance = (item.day - day).abs();
      if (distance < bestDistance ||
          (distance == bestDistance && best != null && item.day < best.day)) {
        best = item;
        bestDistance = distance;
      }
    }
    return best;
  }
}
