import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/daily_item_model.dart';
import '../models/food_model.dart';
import '../models/guide_models.dart';
import '../models/nutrition_model.dart';
import '../models/recipe_model.dart';
import '../models/week_detail_model.dart';
import 'daily_content_parser.dart';
import 'food_content_parser.dart';
import 'guide_content_parser.dart';
import 'pregnancy_weeks_data.dart';
import 'sample_nutrition_data.dart';
import 'week_content_parser.dart';

class ContentPackService {
  static const String pregnancyAssetPath =
      'assets/content/pregnancy_weeks.json';
  static const String nutritionAssetPath =
      'assets/content/nutrition_guides.json';

  static const String sourcesAssetPath = GuideContentParser.sourcesAssetPath;
  static const String guidesIndexAssetPath =
      GuideContentParser.guidesIndexAssetPath;
  static const String foodsAssetPath = FoodContentParser.foodsAssetPath;

  static Map<int, PregnancyWeekData>? _pregnancyWeeks;
  static List<NutritionModel>? _nutritionGuides;
  static List<RecipeModel>? _recipes;
  static String? _nutritionContentVersion;
  static List<GuideArticle> _guides = const [];
  static Map<String, ContentSource> _sources = const {};
  static Map<int, WeekDetail> _weekDetails = const {};
  static DailyPack _thaiGiaoPack = const DailyPack.empty(
    DailyPack.thaiGiaoType,
  );
  static DailyPack _dailyTipsPack = const DailyPack.empty(
    DailyPack.dailyTipType,
  );
  static FoodPack _foodPack = const FoodPack.empty();

  static Map<int, PregnancyWeekData> get pregnancyWeeks =>
      _pregnancyWeeks ?? _buildFallbackPregnancyWeeks();

  static List<NutritionModel> get nutritionGuides =>
      _nutritionGuides ?? SampleNutritionData.getNutritionGuides();

  static List<RecipeModel> get recipes =>
      _recipes ?? SampleNutritionData.getRecipes();

  /// Identifies the bundled nutrition content (its `lastUpdated`); used to
  /// re-seed Hive for existing users when the content pack changes.
  static String get nutritionContentVersion =>
      _nutritionContentVersion ?? 'sample';

  /// Cẩm nang guides (empty when the guide pack is missing or invalid).
  static List<GuideArticle> get guides => _guides;

  /// Guide with [id], or null when it is not loaded.
  static GuideArticle? guideById(String id) {
    for (final guide in _guides) {
      if (guide.id == id) return guide;
    }
    return null;
  }

  /// Replaces the loaded guides (tests only).
  @visibleForTesting
  static set debugGuides(List<GuideArticle> value) => _guides = value;

  /// Source metadata by id from `sources.json` (empty when missing).
  static Map<String, ContentSource> get sources => _sources;

  /// Detailed week pages from `weeks_v2.json` (empty when missing/invalid).
  static Map<int, WeekDetail> get weekDetails => _weekDetails;

  /// Week page for [week] (clamped to 0..42). Falls back to the legacy
  /// `pregnancy_weeks` data when `weeks_v2.json` has no entry for it.
  static WeekDetail weekDetail(int week) =>
      resolveWeekDetail(week, _weekDetails);

  /// Replaces the loaded week pages (tests only).
  @visibleForTesting
  static set debugWeekDetails(Map<int, WeekDetail> value) =>
      _weekDetails = value;

  /// Daily thai giáo activities (empty when the pack is missing/invalid).
  static DailyPack get thaiGiaoPack => _thaiGiaoPack;

  /// Daily tips (empty when the pack is missing/invalid).
  static DailyPack get dailyTipsPack => _dailyTipsPack;

  /// Replaces the loaded thai giáo pack (tests only).
  @visibleForTesting
  static set debugThaiGiaoPack(DailyPack value) => _thaiGiaoPack = value;

  /// Replaces the loaded daily tips pack (tests only).
  @visibleForTesting
  static set debugDailyTipsPack(DailyPack value) => _dailyTipsPack = value;

  /// "Bầu ăn được không?" foods (empty when the pack is missing/invalid).
  static FoodPack get foodPack => _foodPack;

  /// Replaces the loaded food pack (tests only).
  @visibleForTesting
  static set debugFoodPack(FoodPack value) => _foodPack = value;

  static WeekDetail resolveWeekDetail(int week, Map<int, WeekDetail> details) {
    final clamped = week.clamp(
      WeekContentParser.minWeek,
      WeekContentParser.maxWeek,
    );
    return details[clamped] ??
        WeekDetail.fromPregnancyWeek(
          PregnancyWeeksDatabase.getWeekData(clamped),
        );
  }

  static Future<void> init() async {
    _pregnancyWeeks = await loadPregnancyWeeks(rootBundle);
    _nutritionGuides = await loadNutritionGuides(rootBundle);
    _nutritionContentVersion = await loadNutritionContentVersion(rootBundle);
    _recipes = SampleNutritionData.getRecipes();
    _sources = await loadSources(rootBundle);
    _guides = await loadGuides(rootBundle);
    _weekDetails = await loadWeekDetails(rootBundle);
    _thaiGiaoPack = await DailyContentParser.loadThaiGiao(rootBundle);
    _dailyTipsPack = await DailyContentParser.loadDailyTips(rootBundle);
    _foodPack = await FoodContentParser.loadFoods(rootBundle);
  }

  /// Loads `weeks_v2.json`; never throws (missing/invalid -> empty map).
  static Future<Map<int, WeekDetail>> loadWeekDetails(AssetBundle bundle) =>
      WeekContentParser.loadWeekDetails(bundle);

  static Map<int, WeekDetail> parseWeekDetails(String rawJson) =>
      WeekContentParser.parseWeekDetails(rawJson);

  static Future<String?> loadNutritionContentVersion(AssetBundle bundle) async {
    try {
      final raw = await bundle.loadString(nutritionAssetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final lastUpdated = json['lastUpdated']?.toString();
      final count = (json['guides'] as List<dynamic>?)?.length ?? 0;
      return lastUpdated == null ? null : '$lastUpdated#$count';
    } catch (_) {
      return null;
    }
  }

  /// Loads `sources.json`; missing/invalid file yields an empty map.
  static Future<Map<String, ContentSource>> loadSources(AssetBundle bundle) =>
      GuideContentParser.loadSources(bundle);

  /// Loads `guides/index.json` and each listed guide; invalid files are
  /// skipped, a missing index yields an empty list. Never throws.
  static Future<List<GuideArticle>> loadGuides(AssetBundle bundle) =>
      GuideContentParser.loadGuides(bundle);

  static Map<String, ContentSource> parseSources(String rawJson) =>
      GuideContentParser.parseSources(rawJson);

  static List<String> parseGuideIndex(String rawJson) =>
      GuideContentParser.parseGuideIndex(rawJson);

  static GuideArticle? parseGuide(String rawJson) =>
      GuideContentParser.parseGuide(rawJson);

  static Future<Map<int, PregnancyWeekData>> loadPregnancyWeeks(
    AssetBundle bundle,
  ) async {
    try {
      final raw = await bundle.loadString(pregnancyAssetPath);
      return parsePregnancyWeeks(raw);
    } catch (_) {
      return _buildFallbackPregnancyWeeks();
    }
  }

  static Map<int, PregnancyWeekData> parsePregnancyWeeks(String rawJson) {
    final json = jsonDecode(rawJson) as Map<String, dynamic>;
    final lastUpdated = json['lastUpdated'] as String? ?? '2026-09-12';
    final sourceRefs = (json['sourceRefs'] as List<dynamic>? ?? const [])
        .map((source) => source.toString())
        .toList();
    final redFlags = (json['redFlags'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    final nutritionFocus = Map<String, dynamic>.from(
      json['nutritionFocusByTrimester'] as Map<String, dynamic>? ?? const {},
    );
    final weeks = (json['weeks'] as List<dynamic>)
        .map((week) => week as int)
        .toSet();

    if (weeks.length != 43 ||
        !List.generate(43, (i) => i).every(weeks.contains)) {
      throw const FormatException('Pregnancy content must cover weeks 0-42');
    }

    return {
      for (final week in weeks)
        week: _buildWeekData(
          week,
          lastUpdated,
          sourceRefs,
          redFlags,
          nutritionFocus,
        ),
    };
  }

  static Future<List<NutritionModel>> loadNutritionGuides(
    AssetBundle bundle,
  ) async {
    try {
      final raw = await bundle.loadString(nutritionAssetPath);
      return parseNutritionGuides(raw);
    } catch (_) {
      return SampleNutritionData.getNutritionGuides();
    }
  }

  static List<NutritionModel> parseNutritionGuides(String rawJson) {
    final json = jsonDecode(rawJson) as Map<String, dynamic>;
    final guides = json['guides'] as List<dynamic>;
    final now = DateTime.now();

    return guides.map((entry) {
      final guide = entry as Map<String, dynamic>;
      final comparison = guide['supplementComparison']?.toString();
      final benefits = (guide['benefits'] as List<dynamic>)
          .map((item) => item.toString())
          .toList();
      if (comparison != null && comparison.isNotEmpty) {
        benefits.add('So sánh: $comparison');
      }

      return NutritionModel(
        id: guide['id']?.toString() ?? const Uuid().v4(),
        title: guide['title'].toString(),
        category: guide['category'].toString(),
        description: guide['description'].toString(),
        benefits: benefits,
        recommendedFoods: (guide['recommendedFoods'] as List<dynamic>)
            .map((item) => item.toString())
            .toList(),
        foodsToAvoid: (guide['foodsToAvoid'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  static Map<int, PregnancyWeekData> _buildFallbackPregnancyWeeks() {
    return {
      for (var week = 0; week <= 42; week++)
        week: _buildWeekData(
          week,
          '2026-09-12',
          const ['MOH-MCH', 'WHO-ANC'],
          const ['Nếu có dấu hiệu bất thường, hãy liên hệ bác sĩ.'],
          const {},
        ),
    };
  }

  static PregnancyWeekData _buildWeekData(
    int week,
    String lastUpdated,
    List<String> sourceRefs,
    List<String> redFlags,
    Map<String, dynamic> nutritionFocus,
  ) {
    final trimester = _trimesterForWeek(week);
    final focus =
        nutritionFocus['$trimester']?.toString() ??
        'Ăn đa dạng, uống đủ nước và dùng vi chất theo hướng dẫn của bác sĩ.';
    final size = PregnancyWeeksDatabase.getBabySizeComparison(week);

    return PregnancyWeekData(
      week: week,
      babySize: size,
      babyWeight: _estimatedWeight(week),
      babyLength: _estimatedLength(week),
      development: _developmentForWeek(week),
      motherChanges: _motherChangesForWeek(week),
      tips: [
        focus,
        'Theo dõi cơ thể và ghi lại triệu chứng khiến bạn lo lắng.',
        'Đi khám thai theo lịch hẹn hoặc sớm hơn nếu có dấu hiệu bất thường.',
      ],
      redFlags: redFlags,
      nutritionFocus: focus,
      sourceRefs: sourceRefs,
      lastUpdated: lastUpdated,
    );
  }

  static int _trimesterForWeek(int week) {
    if (week <= 0) return 0;
    if (week <= 13) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  // Size comparisons live in weeks_v2 (sizeCompare); keep them out of this
  // fallback text so it can never contradict the week page.
  static String _developmentForWeek(int week) {
    if (week == 0) {
      return 'Cơ thể đang chuẩn bị cho thai kỳ. Đây là giai đoạn nên tối ưu lối sống và trao đổi với bác sĩ khi cần.';
    }
    if (week <= 4) {
      return 'Thai kỳ ở giai đoạn rất sớm. Các mốc phát triển có thể chưa thấy rõ và cần được xác nhận qua chăm sóc y tế phù hợp.';
    }
    if (week <= 13) {
      return 'Các cấu trúc chính đang hình thành nhanh. Mỗi thai kỳ có thể phát triển khác nhau.';
    }
    if (week <= 27) {
      return 'Bé tiếp tục phát triển giác quan, vận động và tăng trưởng.';
    }
    if (week <= 36) {
      return 'Bé tăng cân, hoàn thiện dần các cơ quan và mẹ có thể cảm nhận thai máy rõ hơn.';
    }
    return 'Thai kỳ bước vào giai đoạn gần sinh. Bé tiếp tục hoàn thiện và mẹ nên theo dõi dấu hiệu chuyển dạ theo hướng dẫn y tế.';
  }

  static List<String> _motherChangesForWeek(int week) {
    if (week == 0) {
      return ['Có thể chưa mang thai', 'Nên chuẩn bị dinh dưỡng và lịch khám'];
    }
    if (week <= 13) {
      return [
        'Có thể mệt mỏi hoặc buồn nôn',
        'Ngực căng tức',
        'Tâm trạng thay đổi',
      ];
    }
    if (week <= 27) {
      return [
        'Bụng lớn dần',
        'Có thể cảm nhận thai máy',
        'Có thể đau lưng hoặc chuột rút',
      ];
    }
    return [
      'Bụng lớn hơn',
      'Đi tiểu thường xuyên',
      'Có thể khó ngủ hoặc phù nhẹ',
    ];
  }

  static String _estimatedWeight(int week) {
    if (week <= 8) return '< 1g';
    if (week <= 12) return '${week + 2}g';
    if (week <= 20) return '${(week - 10) * 30}g';
    if (week <= 30) return '${((week - 20) * 90 + 300).round()}g';
    if (week <= 36) return '${((week - 30) * 250 + 1200) / 1000}kg';
    return '${((week - 36) * 150 + 2700) / 1000}kg';
  }

  static String _estimatedLength(int week) {
    if (week <= 4) return '< 2mm';
    if (week <= 12) return '${(week * 0.45).toStringAsFixed(1)}cm';
    if (week <= 20) return '${(week * 1.2).toStringAsFixed(1)}cm';
    if (week <= 36) return '${(week * 1.3).toStringAsFixed(1)}cm';
    return '${(48 + (week - 36) * 0.8).toStringAsFixed(1)}cm';
  }
}
