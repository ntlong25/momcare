import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/guide_models.dart';
import '../utils/app_logger.dart';

/// Parses `sources.json` and the Cẩm nang guide pack exactly per
/// CONTENT_SCHEMA.md. Philosophy matches `ContentPackService`: missing or
/// invalid content degrades to an empty result, it never crashes the app.
///
/// Validation rules:
/// - A guide needs a non-empty `id`, `title`, and a known `stage` and
///   `category`; otherwise the whole guide is skipped.
/// - Checklist items need `id` + `text`; timeline items need `id` + `title`.
///   Invalid items are skipped, the rest of the guide is kept.
/// - Unknown `actionType` falls back to `none`; any `reviewStatus` other than
///   `approved` is treated as draft.
class GuideContentParser {
  static const String sourcesAssetPath = 'assets/content/sources.json';
  static const String guidesDirectory = 'assets/content/guides/';
  static const String guidesIndexAssetPath = 'assets/content/guides/index.json';

  static final AppLogger _logger = AppLogger.instance;

  // ---------------------------------------------------------------- sources

  static Future<Map<String, ContentSource>> loadSources(
    AssetBundle bundle,
  ) async {
    try {
      final raw = await bundle.loadString(sourcesAssetPath);
      return parseSources(raw);
    } catch (e) {
      _logger.warning('sources.json missing or invalid', error: e);
      return const {};
    }
  }

  /// Throws [FormatException] for invalid JSON / wrong root shape; invalid
  /// individual entries are skipped.
  static Map<String, ContentSource> parseSources(String rawJson) {
    final root = _decodeObject(rawJson);
    final list = root['sources'];
    if (list is! List) {
      throw const FormatException('sources.json: "sources" must be a list');
    }
    final result = <String, ContentSource>{};
    for (final entry in list) {
      if (entry is! Map) continue;
      final id = _string(entry['id']);
      if (id == null) continue;
      final title = _string(entry['title']);
      final organization = _string(entry['organization']);
      if (title == null && organization == null) continue;
      result[id] = ContentSource(
        id: id,
        title: title ?? organization!,
        organization: organization ?? title!,
        url: _string(entry['url']),
      );
    }
    return result;
  }

  // ----------------------------------------------------------------- guides

  static Future<List<GuideArticle>> loadGuides(AssetBundle bundle) async {
    List<String> files;
    try {
      files = parseGuideIndex(await bundle.loadString(guidesIndexAssetPath));
    } catch (e) {
      _logger.warning('guides/index.json missing or invalid', error: e);
      return const [];
    }

    final guides = <GuideArticle>[];
    final seenIds = <String>{};
    final seenItemIds = <String>{};
    for (final file in files) {
      try {
        final guide = parseGuide(
          await bundle.loadString('$guidesDirectory$file'),
        );
        if (guide == null) {
          _logger.warning('Guide $file skipped: missing/invalid fields');
          continue;
        }
        if (!seenIds.add(guide.id)) {
          _logger.warning('Guide $file skipped: duplicate id ${guide.id}');
          continue;
        }
        for (final id in [
          ...guide.checklist.map((i) => i.id),
          ...guide.timeline.map((i) => i.id),
        ]) {
          if (!seenItemIds.add(id)) {
            _logger.warning('Guide item id "$id" is not globally unique');
          }
        }
        guides.add(guide);
      } catch (e) {
        _logger.warning('Guide $file could not be loaded', error: e);
      }
    }
    return sortGuides(guides);
  }

  static List<GuideArticle> sortGuides(List<GuideArticle> guides) {
    return List<GuideArticle>.from(guides)..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
    });
  }

  /// Returns the guide file names listed in `index.json`. Throws
  /// [FormatException] for invalid JSON / wrong root shape.
  static List<String> parseGuideIndex(String rawJson) {
    final root = _decodeObject(rawJson);
    final list = root['guides'];
    if (list is! List) {
      throw const FormatException('guides/index.json: "guides" must be a list');
    }
    return list
        .whereType<String>()
        .map((name) => name.trim())
        .where(
          (name) =>
              name.endsWith('.json') &&
              !name.contains('..') &&
              name != 'index.json',
        )
        .toList();
  }

  /// Parses one guide file. Returns null when required fields are missing or
  /// an enum value is unknown. Throws [FormatException] for invalid JSON.
  static GuideArticle? parseGuide(String rawJson) {
    final json = _decodeObject(rawJson);
    return guideFromJson(json);
  }

  static GuideArticle? guideFromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    final title = _string(json['title']);
    final stage = GuideEnums.stageFromJson(json['stage']);
    final category = GuideEnums.categoryFromJson(json['category']);
    if (id == null || title == null || stage == null || category == null) {
      return null;
    }

    return GuideArticle(
      id: id,
      stage: stage,
      category: category,
      title: title,
      summary: _string(json['summary']) ?? '',
      order: _int(json['order']) ?? 0,
      weekFrom: _int(json['weekFrom']),
      weekTo: _int(json['weekTo']),
      sections: _list(
        json['sections'],
      ).map(_section).whereType<GuideSection>().toList(),
      checklist: _list(
        json['checklist'],
      ).map(_checklistItem).whereType<GuideChecklistItem>().toList(),
      timeline: _list(
        json['timeline'],
      ).map(_timelineItem).whereType<GuideTimelineItem>().toList(),
      sources: _stringList(json['sources']),
      lastUpdated: _string(json['lastUpdated']),
      reviewStatus: GuideEnums.reviewFromJson(json['reviewStatus']),
    );
  }

  static GuideSection? _section(Object? value) {
    if (value is! Map) return null;
    final section = GuideSection(
      heading: _string(value['heading']),
      body: _string(value['body']),
      bullets: _stringList(value['bullets']),
    );
    return section.isEmpty ? null : section;
  }

  static GuideChecklistItem? _checklistItem(Object? value) {
    if (value is! Map) return null;
    final id = _string(value['id']);
    final text = _string(value['text']);
    if (id == null || text == null) return null;
    return GuideChecklistItem(
      id: id,
      text: text,
      weekDue: _int(value['weekDue']),
      actionType: GuideEnums.actionFromJson(value['actionType']),
      actionLabel: _string(value['actionLabel']),
      actionValue: _string(value['actionValue']),
    );
  }

  static GuideTimelineItem? _timelineItem(Object? value) {
    if (value is! Map) return null;
    final id = _string(value['id']);
    final title = _string(value['title']);
    if (id == null || title == null) return null;
    return GuideTimelineItem(
      id: id,
      title: title,
      weekFrom: _int(value['weekFrom']),
      weekTo: _int(value['weekTo']),
      description: _string(value['description']),
      actionType: GuideEnums.actionFromJson(value['actionType']),
      actionLabel: _string(value['actionLabel']),
      actionValue: _string(value['actionValue']),
    );
  }

  // ---------------------------------------------------------------- helpers

  static Map<String, dynamic> _decodeObject(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded;
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static List<Object?> _list(Object? value) => value is List ? value : const [];

  static List<String> _stringList(Object? value) =>
      _list(value).map(_string).whereType<String>().toList();
}
