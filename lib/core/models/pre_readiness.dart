import 'guide_models.dart';

/// Checklist progress of one pre-pregnancy guide.
class PreReadinessEntry {
  final GuideArticle guide;
  final int done;
  final int total;

  const PreReadinessEntry({
    required this.guide,
    required this.done,
    required this.total,
  });

  bool get isComplete => total > 0 && done >= total;
}

/// "Sẵn sàng mang thai": aggregated checklist progress over the
/// pre-pregnancy (`stage: pre`) guides that track progress (A1).
class PreReadiness {
  /// Maximum number of incomplete guides suggested in [nextUp].
  static const int nextUpLimit = 3;

  final List<PreReadinessEntry> entries;
  final int done;
  final int total;
  final bool isDraft;

  const PreReadiness._({
    required this.entries,
    required this.done,
    required this.total,
    required this.isDraft,
  });

  /// Aggregates [guides] (any stage; only `pre` guides with a tickable
  /// checklist count) against [ticked] item ids. Ticks for ids outside those
  /// checklists are ignored.
  factory PreReadiness.compute(List<GuideArticle> guides, Set<String> ticked) {
    final pre =
        guides
            .where((g) => g.stage == GuideStage.pre && g.tracksProgress)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final entries = <PreReadinessEntry>[];
    var done = 0;
    var total = 0;
    for (final guide in pre) {
      final guideDone = guide.checklist
          .where((item) => ticked.contains(item.id))
          .length;
      entries.add(
        PreReadinessEntry(
          guide: guide,
          done: guideDone,
          total: guide.checklist.length,
        ),
      );
      done += guideDone;
      total += guide.checklist.length;
    }

    return PreReadiness._(
      entries: List.unmodifiable(entries),
      done: done,
      total: total,
      isDraft: pre.any((g) => g.isDraft),
    );
  }

  bool get isEmpty => total == 0;

  bool get isComplete => total > 0 && done >= total;

  /// Completion 0..100, rounded; 0 when there is nothing to track.
  int get percent => total == 0 ? 0 : (done * 100 / total).round();

  /// Completion ratio 0..1 for progress bars.
  double get ratio => total == 0 ? 0 : done / total;

  /// Up to [nextUpLimit] incomplete guides, in guide order.
  List<PreReadinessEntry> get nextUp =>
      entries.where((e) => !e.isComplete).take(nextUpLimit).toList();
}
