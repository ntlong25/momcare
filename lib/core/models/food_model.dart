/// "Bầu ăn được không?" food lookup model for `assets/content/foods.json`
/// (see CONTENT_SCHEMA.md, section 5).
library;

import 'package:flutter/material.dart';

import 'guide_models.dart';

enum FoodVerdict { ok, limit, avoid }

extension FoodVerdictX on FoodVerdict {
  String get label {
    switch (this) {
      case FoodVerdict.ok:
        return 'Nên ăn';
      case FoodVerdict.limit:
        return 'Hạn chế';
      case FoodVerdict.avoid:
        return 'Tránh';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodVerdict.ok:
        return Icons.check_circle_outline;
      case FoodVerdict.limit:
        return Icons.error_outline;
      case FoodVerdict.avoid:
        return Icons.block;
    }
  }

  /// Parses the JSON value; returns null for unknown verdicts.
  static FoodVerdict? fromJson(Object? value) {
    switch (value) {
      case 'ok':
        return FoodVerdict.ok;
      case 'limit':
        return FoodVerdict.limit;
      case 'avoid':
        return FoodVerdict.avoid;
    }
    return null;
  }
}

class FoodGroups {
  static const String otherLabel = 'Khác';

  /// Display labels for every group used in `foods.json`
  /// (content_source/CONTENT_NOTES.md).
  static const Map<String, String> labels = {
    'vegetable': 'Rau củ',
    'fruit': 'Trái cây',
    'meat': 'Thịt',
    'seafood': 'Hải sản',
    'egg': 'Trứng',
    'dairy': 'Sữa',
    'grain': 'Ngũ cốc',
    'legume_nut': 'Đậu, hạt',
    'drink': 'Đồ uống',
    'dish': 'Món ăn',
    'herb_spice': 'Gia vị, thảo mộc',
    'sweet': 'Đồ ngọt',
    'supplement': 'Thực phẩm bổ sung',
  };

  static String label(String group) => labels[group] ?? otherLabel;
}

class FoodItem {
  final String id;
  final String name;
  final List<String> aliases;
  final String group;
  final FoodVerdict verdict;
  final String reason;
  final String tip;
  final List<String> sources;

  const FoodItem({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.group,
    required this.verdict,
    this.reason = '',
    this.tip = '',
    this.sources = const [],
  });

  String get groupLabel => FoodGroups.label(group);
}

class FoodPack {
  final String? lastUpdated;
  final ReviewStatus reviewStatus;
  final List<FoodItem> items;

  const FoodPack({
    this.lastUpdated,
    this.reviewStatus = ReviewStatus.draftRequiresMedicalReview,
    this.items = const [],
  });

  const FoodPack.empty()
    : lastUpdated = null,
      reviewStatus = ReviewStatus.draftRequiresMedicalReview,
      items = const [];

  bool get isDraft => reviewStatus != ReviewStatus.approved;

  bool get isEmpty => items.isEmpty;
}
