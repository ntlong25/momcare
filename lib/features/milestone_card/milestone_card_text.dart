import '../../core/models/week_detail_model.dart';

/// Text of the shareable milestone card (Phase 21). Only content values, no
/// personal data and no medical advice.
class MilestoneCardText {
  const MilestoneCardText._();

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// `Tuần X – bé to bằng [sizeCompare]`, or "Tuần X thai kỳ của mẹ" when
  /// the week has no size comparison.
  static String headline(WeekDetail detail) {
    final size = _nonBlank(detail.sizeCompare);
    if (size == null) return 'Tuần ${detail.week} thai kỳ của mẹ';
    return 'Tuần ${detail.week} – bé to bằng $size';
  }

  /// `Dài khoảng [length] · Nặng khoảng [weight]` from whichever exists;
  /// empty when neither does.
  static String details(WeekDetail detail) {
    final length = _nonBlank(detail.lengthText);
    final weight = _nonBlank(detail.weightText);
    return [
      if (length != null) 'Dài khoảng $length',
      if (weight != null) 'Nặng khoảng $weight',
    ].join(' · ');
  }

  /// Name of the shared PNG.
  static String fileName(WeekDetail detail) =>
      'momcare_tuan_${detail.week}.png';
}
