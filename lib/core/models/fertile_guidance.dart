import 'dart:convert';

import '../services/cycle_prediction.dart';
import 'guide_models.dart';

/// Reviewed wording of the fertile-window features, from
/// `assets/content/fertile_guidance.json` (also exported to the doctor
/// review packet, so the app and the packet cannot drift apart).
class FertileGuidance {
  /// A pack without one of these is treated as missing, so the card can
  /// never appear without, for example, its contraception warning.
  static const Set<String> requiredIds = {
    'title',
    'level_low',
    'level_high',
    'level_peak',
    'estimate_suffix',
    'message_low',
    'message_high',
    'message_peak',
    'window_label',
    'confidence_label',
    'confidence_low',
    'confidence_medium',
    'confidence_note_insufficient',
    'confidence_note_irregular',
    'confidence_note_medium',
    'ovulation_note',
    'ovulation_in_range',
    'frequency',
    'outside_range_note',
    'not_contraception',
  };

  final Map<String, String> _texts;
  final ReviewStatus reviewStatus;

  const FertileGuidance(
    this._texts, {
    this.reviewStatus = ReviewStatus.draftRequiresMedicalReview,
  });

  const FertileGuidance.empty()
    : _texts = const {},
      reviewStatus = ReviewStatus.draftRequiresMedicalReview;

  bool get isEmpty => _texts.isEmpty;
  bool get isDraft => reviewStatus != ReviewStatus.approved;

  /// Text of [id]; empty when the pack is missing.
  String text(String id) => _texts[id] ?? '';

  /// "Độ tin cậy: Thấp" line of [prediction].
  String confidenceLine(CyclePrediction prediction) {
    final level = text(switch (prediction.confidence) {
      PredictionConfidence.low => 'confidence_low',
      PredictionConfidence.medium => 'confidence_medium',
    });
    return '${text('confidence_label')}: $level';
  }

  /// Why [prediction] has its confidence.
  String confidenceNote(CyclePrediction prediction) {
    if (prediction.confidence == PredictionConfidence.medium) {
      return text('confidence_note_medium');
    }
    return text(
      prediction.regularity == CycleRegularity.irregular
          ? 'confidence_note_irregular'
          : 'confidence_note_insufficient',
    );
  }

  /// Never throws: invalid JSON or a missing required id gives an empty pack.
  static FertileGuidance parse(String rawJson) {
    try {
      final root = jsonDecode(rawJson) as Map<String, dynamic>;
      final texts = <String, String>{
        for (final item in root['items'] as List<dynamic>)
          (item as Map<String, dynamic>)['id'] as String:
              (item['text'] as String).trim(),
      };
      final complete = requiredIds.every(
        (id) => texts[id]?.isNotEmpty ?? false,
      );
      if (!complete) return const FertileGuidance.empty();
      return FertileGuidance(
        texts,
        reviewStatus: GuideEnums.reviewFromJson(root['reviewStatus']),
      );
    } catch (_) {
      return const FertileGuidance.empty();
    }
  }
}
