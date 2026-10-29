import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/daily_item_model.dart';
import '../models/guide_models.dart';
import '../utils/app_logger.dart';

/// Parses the daily packs `assets/content/daily/thai_giao.json` and
/// `assets/content/daily/daily_tips.json` per CONTENT_SCHEMA.md section 3.
///
/// Never throws: a missing/invalid file yields an empty pack; items with a
/// day outside 1..294, an empty title/body or an unknown category are
/// skipped, and the first item wins when a day is duplicated.
class DailyContentParser {
  static const String thaiGiaoAssetPath = 'assets/content/daily/thai_giao.json';
  static const String dailyTipsAssetPath =
      'assets/content/daily/daily_tips.json';

  static final AppLogger _logger = AppLogger.instance;

  static Future<DailyPack> loadThaiGiao(AssetBundle bundle) => loadDailyPack(
    bundle,
    thaiGiaoAssetPath,
    expectedType: DailyPack.thaiGiaoType,
  );

  static Future<DailyPack> loadDailyTips(AssetBundle bundle) => loadDailyPack(
    bundle,
    dailyTipsAssetPath,
    expectedType: DailyPack.dailyTipType,
  );

  static Future<DailyPack> loadDailyPack(
    AssetBundle bundle,
    String path, {
    required String expectedType,
  }) async {
    try {
      return parseDailyPack(
        await bundle.loadString(path),
        expectedType: expectedType,
      );
    } catch (e) {
      _logger.warning('$path missing or invalid', error: e);
      return DailyPack.empty(expectedType);
    }
  }

  static DailyPack parseDailyPack(
    String rawJson, {
    required String expectedType,
  }) {
    final empty = DailyPack.empty(expectedType);
    Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      _logger.warning('$expectedType pack is not valid JSON', error: e);
      return empty;
    }
    if (decoded is! Map) return empty;
    final type = _string(decoded['type']);
    if (type != null && type != expectedType) {
      _logger.warning('Daily pack type "$type" != "$expectedType"');
      return empty;
    }
    final rawItems = decoded['items'];
    if (rawItems is! List) return empty;

    final categories = DailyPack.categoriesByType[expectedType] ?? const [];
    final byDay = <int, DailyItem>{};
    for (final entry in rawItems) {
      if (entry is! Map) continue;
      final day = _int(entry['day']);
      if (day == null || day < DailyPack.minDay || day > DailyPack.maxDay) {
        continue;
      }
      final category = _string(entry['category']);
      final title = _string(entry['title']);
      final body = _string(entry['body']);
      if (category == null || !categories.contains(category)) continue;
      if (title == null || body == null) continue;
      if (byDay.containsKey(day)) {
        _logger.warning('Duplicate $expectedType day $day ignored');
        continue;
      }
      byDay[day] = DailyItem(
        day: day,
        week: _int(entry['week']) ?? (day - 1) ~/ 7,
        category: category,
        title: title,
        body: body,
        durationMin: _duration(entry['durationMin']),
        sources: _stringList(entry['sources']),
      );
    }

    final items = byDay.values.toList()..sort((a, b) => a.day - b.day);
    return DailyPack(
      type: expectedType,
      lastUpdated: _string(decoded['lastUpdated']),
      reviewStatus: GuideEnums.reviewFromJson(decoded['reviewStatus']),
      items: List.unmodifiable(items),
    );
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
    return null;
  }

  static int? _duration(Object? value) {
    if (value is int) return value > 0 ? value : null;
    if (value is double && value.isFinite && value > 0) {
      final rounded = value.round();
      return rounded > 0 ? rounded : null;
    }
    return null;
  }

  static List<String> _stringList(Object? value) => value is List
      ? value.map(_string).whereType<String>().toList()
      : const [];
}
