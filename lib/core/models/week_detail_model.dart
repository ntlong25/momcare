/// Detailed week page model for `assets/content/weeks_v2.json`
/// (see CONTENT_SCHEMA.md, section 4).
library;

import '../data/pregnancy_weeks_data.dart';
import 'guide_models.dart';

class WeekDetail {
  final int week;

  /// Asset path of the illustration; may point to a file that is not bundled
  /// yet (the UI then shows a placeholder).
  final String? image;
  final String? sizeCompare;
  final double? lengthCm;
  final double? weightG;

  /// Pre-formatted length/weight text used when the numeric values are
  /// unknown (fallback data from `pregnancy_weeks.json`).
  final String? lengthLabel;
  final String? weightLabel;

  final String babyDevelopment;
  final String motherChanges;
  final List<String> commonSymptoms;
  final List<String> todoThisWeek;
  final List<String> examsThisWeek;
  final List<String> nutritionFocus;
  final List<String> redFlags;
  final List<String> sources;
  final String? lastUpdated;
  final ReviewStatus reviewStatus;

  const WeekDetail({
    required this.week,
    this.image,
    this.sizeCompare,
    this.lengthCm,
    this.weightG,
    this.lengthLabel,
    this.weightLabel,
    this.babyDevelopment = '',
    this.motherChanges = '',
    this.commonSymptoms = const [],
    this.todoThisWeek = const [],
    this.examsThisWeek = const [],
    this.nutritionFocus = const [],
    this.redFlags = const [],
    this.sources = const [],
    this.lastUpdated,
    this.reviewStatus = ReviewStatus.draftRequiresMedicalReview,
  });

  /// Builds a detail page from the legacy week data when `weeks_v2.json` has
  /// no entry for [data.week].
  factory WeekDetail.fromPregnancyWeek(PregnancyWeekData data) {
    String? nonEmpty(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return WeekDetail(
      week: data.week,
      sizeCompare: nonEmpty(data.babySize),
      lengthLabel: nonEmpty(data.babyLength),
      weightLabel: nonEmpty(data.babyWeight),
      babyDevelopment: data.development,
      motherChanges: data.motherChanges.join('\n'),
      todoThisWeek: data.tips,
      nutritionFocus: [
        if (data.nutritionFocus.trim().isNotEmpty) data.nutritionFocus.trim(),
      ],
      redFlags: data.redFlags,
      sources: data.sourceRefs,
      lastUpdated: data.lastUpdated,
    );
  }

  bool get isDraft => reviewStatus != ReviewStatus.approved;

  /// e.g. `25.6 cm`; null when unknown.
  String? get lengthText =>
      lengthCm != null ? '${_formatNumber(lengthCm!)} cm' : lengthLabel;

  /// e.g. `300 g`; null when unknown.
  String? get weightText =>
      weightG != null ? '${_formatNumber(weightG!)} g' : weightLabel;

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
