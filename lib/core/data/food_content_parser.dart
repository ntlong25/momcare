import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/food_model.dart';
import '../models/guide_models.dart';
import '../utils/app_logger.dart';

/// Parses `assets/content/foods.json` per CONTENT_SCHEMA.md section 5.
///
/// Never throws: a missing/invalid file (or a missing `foods` list) yields an
/// empty pack; items without `id`/`name` or with an unknown `verdict` are
/// skipped, and the first item wins when an id is duplicated.
class FoodContentParser {
  static const String foodsAssetPath = 'assets/content/foods.json';

  static final AppLogger _logger = AppLogger.instance;

  static Future<FoodPack> loadFoods(AssetBundle bundle) async {
    try {
      return parseFoods(await bundle.loadString(foodsAssetPath));
    } catch (e) {
      _logger.warning('foods.json missing or invalid', error: e);
      return const FoodPack.empty();
    }
  }

  static FoodPack parseFoods(String rawJson) {
    Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      _logger.warning('foods.json is not valid JSON', error: e);
      return const FoodPack.empty();
    }
    if (decoded is! Map) return const FoodPack.empty();
    final rawItems = decoded['foods'];
    if (rawItems is! List) return const FoodPack.empty();

    final items = <FoodItem>[];
    final seenIds = <String>{};
    for (final entry in rawItems) {
      if (entry is! Map) continue;
      final id = _string(entry['id']);
      final name = _string(entry['name']);
      final verdict = FoodVerdictX.fromJson(entry['verdict']);
      if (id == null || name == null || verdict == null) continue;
      if (!seenIds.add(id)) {
        _logger.warning('Duplicate food id "$id" ignored');
        continue;
      }
      items.add(
        FoodItem(
          id: id,
          name: name,
          aliases: _stringList(entry['aliases']),
          group: _string(entry['group']) ?? '',
          verdict: verdict,
          reason: _string(entry['reason']) ?? '',
          tip: _string(entry['tip']) ?? '',
          sources: _stringList(entry['sources']),
        ),
      );
    }

    return FoodPack(
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

  static List<String> _stringList(Object? value) => value is List
      ? value.map(_string).whereType<String>().toList()
      : const [];
}
