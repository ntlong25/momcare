/// Content engine models for `assets/content/sources.json` and
/// `assets/content/guides/**` (see CONTENT_SCHEMA.md, sections 1-2).
library;

enum GuideStage { pre, pregnant, postpartum }

enum GuideCategory {
  health,
  nutrition,
  vaccination,
  mental,
  finance,
  lifestyle,
  partner,
  signs,
  checkup,
  shopping,
  documents,
  hospitalBag,
  warning,
}

enum GuideActionType { none, addAppointment, openMaps, call }

enum ReviewStatus { draftRequiresMedicalReview, approved }

class GuideEnums {
  static GuideStage? stageFromJson(Object? value) => switch (value) {
    'pre' => GuideStage.pre,
    'pregnant' => GuideStage.pregnant,
    'postpartum' => GuideStage.postpartum,
    _ => null,
  };

  static GuideCategory? categoryFromJson(Object? value) => switch (value) {
    'health' => GuideCategory.health,
    'nutrition' => GuideCategory.nutrition,
    'vaccination' => GuideCategory.vaccination,
    'mental' => GuideCategory.mental,
    'finance' => GuideCategory.finance,
    'lifestyle' => GuideCategory.lifestyle,
    'partner' => GuideCategory.partner,
    'signs' => GuideCategory.signs,
    'checkup' => GuideCategory.checkup,
    'shopping' => GuideCategory.shopping,
    'documents' => GuideCategory.documents,
    'hospital_bag' => GuideCategory.hospitalBag,
    'warning' => GuideCategory.warning,
    _ => null,
  };

  /// Unknown or missing action types fall back to [GuideActionType.none].
  static GuideActionType actionFromJson(Object? value) => switch (value) {
    'addAppointment' => GuideActionType.addAppointment,
    'openMaps' => GuideActionType.openMaps,
    'call' => GuideActionType.call,
    _ => GuideActionType.none,
  };

  /// Only an explicit `approved` counts as reviewed; anything else is draft.
  static ReviewStatus reviewFromJson(Object? value) => value == 'approved'
      ? ReviewStatus.approved
      : ReviewStatus.draftRequiresMedicalReview;

  static const Map<GuideCategory, String> categoryLabels = {
    GuideCategory.health: 'Sức khỏe',
    GuideCategory.nutrition: 'Dinh dưỡng',
    GuideCategory.vaccination: 'Tiêm phòng',
    GuideCategory.mental: 'Tinh thần',
    GuideCategory.finance: 'Tài chính',
    GuideCategory.lifestyle: 'Lối sống',
    GuideCategory.partner: 'Dành cho bố',
    GuideCategory.signs: 'Dấu hiệu',
    GuideCategory.checkup: 'Lịch khám',
    GuideCategory.shopping: 'Mua sắm',
    GuideCategory.documents: 'Giấy tờ & quyền lợi',
    GuideCategory.hospitalBag: 'Túi đồ đi sinh',
    GuideCategory.warning: 'Cần đi khám',
  };

  static String categoryLabel(GuideCategory category) =>
      categoryLabels[category] ?? category.name;
}

class ContentSource {
  final String id;
  final String title;
  final String organization;
  final String? url;

  const ContentSource({
    required this.id,
    required this.title,
    required this.organization,
    this.url,
  });
}

class GuideSection {
  final String? heading;
  final String? body;
  final List<String> bullets;

  const GuideSection({this.heading, this.body, this.bullets = const []});

  bool get isEmpty =>
      (heading == null || heading!.isEmpty) &&
      (body == null || body!.isEmpty) &&
      bullets.isEmpty;
}

class GuideChecklistItem {
  final String id;
  final String text;
  final int? weekDue;
  final GuideActionType actionType;
  final String? actionLabel;
  final String? actionValue;

  const GuideChecklistItem({
    required this.id,
    required this.text,
    this.weekDue,
    this.actionType = GuideActionType.none,
    this.actionLabel,
    this.actionValue,
  });
}

class GuideTimelineItem {
  final String id;
  final int? weekFrom;
  final int? weekTo;
  final String title;
  final String? description;
  final GuideActionType actionType;
  final String? actionLabel;
  final String? actionValue;

  const GuideTimelineItem({
    required this.id,
    required this.title,
    this.weekFrom,
    this.weekTo,
    this.description,
    this.actionType = GuideActionType.none,
    this.actionLabel,
    this.actionValue,
  });

  String? get weekLabel {
    if (weekFrom == null && weekTo == null) return null;
    if (weekFrom != null && weekTo != null && weekFrom != weekTo) {
      return 'Tuần $weekFrom-$weekTo';
    }
    return 'Tuần ${weekFrom ?? weekTo}';
  }
}

class GuideArticle {
  final String id;
  final GuideStage stage;
  final GuideCategory category;
  final String title;
  final String summary;
  final int order;
  final int? weekFrom;
  final int? weekTo;
  final List<GuideSection> sections;
  final List<GuideChecklistItem> checklist;
  final List<GuideTimelineItem> timeline;
  final List<String> sources;
  final String? lastUpdated;
  final ReviewStatus reviewStatus;

  const GuideArticle({
    required this.id,
    required this.stage,
    required this.category,
    required this.title,
    this.summary = '',
    this.order = 0,
    this.weekFrom,
    this.weekTo,
    this.sections = const [],
    this.checklist = const [],
    this.timeline = const [],
    this.sources = const [],
    this.lastUpdated,
    this.reviewStatus = ReviewStatus.draftRequiresMedicalReview,
  });

  bool get isDraft => reviewStatus != ReviewStatus.approved;

  /// Whether checklist items are tickable to-dos with a progress bar.
  /// Warning guides list danger signs, so ticking them makes no sense; their
  /// checklist renders as plain bullets instead.
  bool get tracksProgress =>
      checklist.isNotEmpty && category != GuideCategory.warning;

  /// Checklist completion ratio 0..1, or null when the guide has no
  /// checklist or does not track progress (see [tracksProgress]).
  double? progress(Set<String> tickedIds) {
    if (!tracksProgress) return null;
    final done = checklist.where((item) => tickedIds.contains(item.id)).length;
    return done / checklist.length;
  }

  /// Whether checklist items take an optional price (VND) and show a total
  /// for bought (ticked) items: shopping and hospital-bag guides only.
  bool get tracksPrices =>
      tracksProgress &&
      (category == GuideCategory.shopping ||
          category == GuideCategory.hospitalBag);

  /// Sum of [prices] for ticked items of this guide's checklist; ids from
  /// other guides are ignored.
  int boughtTotal(Set<String> tickedIds, Map<String, int> prices) {
    var total = 0;
    for (final item in checklist) {
      if (tickedIds.contains(item.id)) total += prices[item.id] ?? 0;
    }
    return total;
  }

  /// Number of this guide's checklist items that have a price.
  int pricedCount(Map<String, int> prices) =>
      checklist.where((item) => prices.containsKey(item.id)).length;
}
