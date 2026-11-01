import 'dart:convert';

import '../services/cycle_prediction.dart';
import 'fertility_log_model.dart';
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
    'lh_label',
    'lh_negative',
    'lh_positive',
    'lh_peak',
    'lh_source',
    'lh_note',
    'mucus_label',
    'mucus_dry',
    'mucus_sticky',
    'mucus_creamy',
    'mucus_watery',
    'mucus_egg_white',
    'temperature_label',
    'temperature_hint',
    'temperature_invalid',
    'intimacy_label',
    'intimacy_setting',
    'intimacy_setting_note',
    'signals_title',
    'signals_empty',
    'signals_log_today',
    'signals_log_day',
    'signals_settings',
    'signals_history_hint',
    'signals_history_note',
    'signals_privacy',
    'log_done',
    'log_delete',
    'log_delete_confirm',
    'log_delete_cancel',
    'reminder_title',
    'reminder_window',
    'reminder_lh',
    'reminder_time',
    'reminder_note',
    'reminder_denied',
    'reminder_text',
    'notify_window',
    'notify_peak',
    'notify_update',
    'style_label',
    'style_discreet',
    'style_full',
    'style_note',
    'doctor_title',
    'doctor_cycles',
    'doctor_trying',
    'doctor_age',
    'doctor_anytime',
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

  String lhLabel(LhResult result) => text(switch (result) {
    LhResult.negative => 'lh_negative',
    LhResult.positive => 'lh_positive',
    LhResult.peak => 'lh_peak',
  });

  String mucusLabel(CervicalMucus mucus) => text(switch (mucus) {
    CervicalMucus.dry => 'mucus_dry',
    CervicalMucus.sticky => 'mucus_sticky',
    CervicalMucus.creamy => 'mucus_creamy',
    CervicalMucus.watery => 'mucus_watery',
    CervicalMucus.eggWhite => 'mucus_egg_white',
  });

  /// One history line, as logged and without any reading of the values.
  String logSummary(FertilityLogModel log, {required bool showIntimacy}) {
    final lh = log.lh;
    final mucus = log.mucus;
    final temperature = log.temperatureC;
    return [
      if (lh != null) '${text('lh_label')}: ${lhLabel(lh)}',
      if (mucus != null) '${text('mucus_label')}: ${mucusLabel(mucus)}',
      if (temperature != null)
        '${text('temperature_label')}: '
            '${FertilityLogModel.formatTemperature(temperature)}°C',
      if (showIntimacy && log.intimacy) text('intimacy_label'),
    ].join(' · ');
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
