import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/guide_models.dart';
import '../models/week_detail_model.dart';
import '../utils/app_logger.dart';

/// Parses `assets/content/weeks_v2.json` per CONTENT_SCHEMA.md section 4.
///
/// Never throws: a missing/invalid file yields an empty map, entries with a
/// missing or out-of-range (0..42) `week` are skipped, and the first entry
/// wins when a week is duplicated.
class WeekContentParser {
  static const String weeksAssetPath = 'assets/content/weeks_v2.json';
  static const int minWeek = 0;
  static const int maxWeek = 42;

  static final AppLogger _logger = AppLogger.instance;

  static Future<Map<int, WeekDetail>> loadWeekDetails(
    AssetBundle bundle,
  ) async {
    try {
      return parseWeekDetails(await bundle.loadString(weeksAssetPath));
    } catch (e) {
      _logger.warning('weeks_v2.json missing or invalid', error: e);
      return const {};
    }
  }

  static Map<int, WeekDetail> parseWeekDetails(String rawJson) {
    Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      _logger.warning('weeks_v2.json is not valid JSON', error: e);
      return const {};
    }
    if (decoded is! Map) return const {};
    final weeks = decoded['weeks'];
    if (weeks is! List) return const {};

    final lastUpdated = _string(decoded['lastUpdated']);
    final reviewStatus = GuideEnums.reviewFromJson(decoded['reviewStatus']);

    final result = <int, WeekDetail>{};
    for (final entry in weeks) {
      if (entry is! Map) continue;
      final week = _int(entry['week']);
      if (week == null || week < minWeek || week > maxWeek) continue;
      if (result.containsKey(week)) continue;
      result[week] = WeekDetail(
        week: week,
        image: _string(entry['image']),
        sizeCompare: _string(entry['sizeCompare']),
        lengthCm: _double(entry['lengthCm']),
        weightG: _double(entry['weightG']),
        babyDevelopment: _string(entry['babyDevelopment']) ?? '',
        motherChanges: _string(entry['motherChanges']) ?? '',
        commonSymptoms: _stringList(entry['commonSymptoms']),
        todoThisWeek: _stringList(entry['todoThisWeek']),
        examsThisWeek: _stringList(entry['examsThisWeek']),
        nutritionFocus: _stringList(entry['nutritionFocus']),
        redFlags: _stringList(entry['redFlags']),
        sources: _stringList(entry['sources']),
        lastUpdated: lastUpdated,
        reviewStatus: reviewStatus,
      );
    }
    return result;
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is double && value == value.roundToDouble()) {
      return value.round();
    }
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _double(Object? value) {
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value.trim())
        : null;
    return number != null && number.isFinite ? number : null;
  }

  static List<String> _stringList(Object? value) => value is List
      ? value.map(_string).whereType<String>().toList()
      : const [];
}
