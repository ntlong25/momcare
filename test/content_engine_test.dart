import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/services/guide_progress_service.dart';
import 'package:momcare/features/guides/guide_actions.dart';
import 'package:momcare/features/guides/screens/guide_detail_screen.dart';
import 'package:momcare/features/guides/screens/guides_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves `assets/content/...` keys from a directory on disk.
class _DirectoryAssetBundle extends CachingAssetBundle {
  final String root;

  _DirectoryAssetBundle(this.root);

  @override
  Future<ByteData> load(String key) async {
    final file = File(_resolve(key));
    if (!file.existsSync()) throw FlutterError('Missing asset: $key');
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final file = File(_resolve(key));
    if (!file.existsSync()) throw FlutterError('Missing asset: $key');
    return file.readAsString();
  }

  String _resolve(String key) =>
      '$root/${key.replaceFirst('assets/content/', '')}';
}

const _fixtureRoot = 'test/fixtures/content';

void main() {
  group('sources.json parser', () {
    test('parses valid entries and skips invalid ones', () async {
      final sources = await ContentPackService.loadSources(
        _DirectoryAssetBundle(_fixtureRoot),
      );

      expect(sources.keys, ['WHO-ANC', 'MOH-MCH']);
      expect(sources['WHO-ANC']!.organization, 'World Health Organization');
      expect(sources['MOH-MCH']!.url, isNull);
    });

    test('missing or invalid file yields an empty map', () async {
      expect(
        await ContentPackService.loadSources(
          _DirectoryAssetBundle('test/fixtures/does_not_exist'),
        ),
        isEmpty,
      );
      expect(
        () => ContentPackService.parseSources('{not json'),
        throwsFormatException,
      );
      expect(
        () => ContentPackService.parseSources('{"sources": "x"}'),
        throwsFormatException,
      );
    });
  });

  group('guide parser', () {
    test('loads valid guides and skips invalid files', () async {
      final guides = await ContentPackService.loadGuides(
        _DirectoryAssetBundle(_fixtureRoot),
      );

      // valid_pre (order 5) before valid_pregnant (order 10).
      expect(guides.map((g) => g.id), ['pre_health', 'pregnant_checkups']);

      final checkups = guides.last;
      expect(checkups.stage, GuideStage.pregnant);
      expect(checkups.category, GuideCategory.checkup);
      expect(checkups.isDraft, isTrue);
      expect(checkups.sections, hasLength(1), reason: 'empty section dropped');
      expect(checkups.sections.first.bullets, hasLength(2));
      expect(checkups.checklist.map((i) => i.id), [
        'chk_test_book',
        'chk_test_call',
        'chk_test_maps',
      ]);
      expect(checkups.checklist[0].actionType, GuideActionType.addAppointment);
      expect(checkups.checklist[0].weekDue, 8);
      expect(checkups.checklist[1].actionType, GuideActionType.call);
      expect(checkups.checklist[1].actionValue, '115');
      expect(checkups.checklist[2].actionType, GuideActionType.openMaps);
      expect(checkups.timeline, hasLength(2));
      expect(checkups.timeline.first.weekLabel, 'Tuần 11-13');
      expect(checkups.sources, ['WHO-ANC', 'MOH-MCH', 'UNKNOWN-SRC']);
      expect(checkups.lastUpdated, '2026-10-29');

      expect(guides.first.isDraft, isFalse);
      expect(guides.first.checklist, isEmpty);
    });

    test('unknown actionType falls back to none, numeric strings parse', () {
      final raw = File(
        '$_fixtureRoot/guides/valid_pregnant.json',
      ).readAsStringSync();
      final guide = ContentPackService.parseGuide(raw)!;
      final weird = guide.timeline.last;

      expect(weird.actionType, GuideActionType.none);
      expect(weird.weekFrom, 20);
    });

    test('missing required fields returns null', () {
      final raw = File(
        '$_fixtureRoot/guides/missing_fields.json',
      ).readAsStringSync();
      expect(ContentPackService.parseGuide(raw), isNull);
    });

    test('unknown stage/category enum returns null', () {
      final raw = File(
        '$_fixtureRoot/guides/unknown_enum.json',
      ).readAsStringSync();
      expect(ContentPackService.parseGuide(raw), isNull);
      expect(
        ContentPackService.parseGuide(
          '{"id":"x","title":"T","stage":"pre","category":"astrology"}',
        ),
        isNull,
      );
    });

    test('invalid JSON throws FormatException', () {
      final raw = File(
        '$_fixtureRoot/guides/invalid_json.json',
      ).readAsStringSync();
      expect(() => ContentPackService.parseGuide(raw), throwsFormatException);
    });

    test('index filters unsafe and non-json names', () {
      expect(
        ContentPackService.parseGuideIndex(
          '{"guides": ["a.json", "../b.json", "index.json", 3, "c.txt"]}',
        ),
        ['a.json'],
      );
    });

    test('missing index yields an empty list', () async {
      expect(
        await ContentPackService.loadGuides(
          _DirectoryAssetBundle('test/fixtures/does_not_exist'),
        ),
        isEmpty,
      );
    });

    test('bundled guide pack parses against CONTENT_SCHEMA.md', () async {
      final indexFile = File('assets/content/guides/index.json');
      if (!indexFile.existsSync()) {
        markTestSkipped('No bundled guide pack yet');
        return;
      }
      final bundle = _DirectoryAssetBundle('assets/content');
      final listed = ContentPackService.parseGuideIndex(
        indexFile.readAsStringSync(),
      );
      final rejected = <String>[];
      for (final file in listed) {
        final path = 'assets/content/guides/$file';
        try {
          if (ContentPackService.parseGuide(File(path).readAsStringSync()) ==
              null) {
            rejected.add('$file: missing/invalid required field');
          }
        } catch (e) {
          rejected.add('$file: $e');
        }
      }
      expect(rejected, isEmpty, reason: rejected.join('\n'));

      final guides = await ContentPackService.loadGuides(bundle);
      expect(guides, hasLength(listed.length));

      final sources = await ContentPackService.loadSources(bundle);
      if (File('assets/content/sources.json').existsSync()) {
        expect(sources, isNotEmpty);
      }
    });
  });

  group('checklist persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('ticks persist by item id and can be cleared', () async {
      await GuideProgressService.setTicked('chk_a', true);
      await GuideProgressService.setTicked('chk_b', true);
      await GuideProgressService.setTicked('chk_a', false);

      expect(await GuideProgressService.loadTicked(), {'chk_b'});

      await GuideProgressService.clear();
      expect(await GuideProgressService.loadTicked(), isEmpty);
    });

    test('notifier toggles persist and reload', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(guideChecklistProvider.notifier);
      await notifier.ready;

      await notifier.toggle('chk_book', true);
      expect(container.read(guideChecklistProvider), {'chk_book'});

      final second = ProviderContainer();
      addTearDown(second.dispose);
      await second.read(guideChecklistProvider.notifier).ready;
      expect(second.read(guideChecklistProvider), {'chk_book'});
    });

    test('progress is the ratio of ticked checklist items', () {
      const guide = GuideArticle(
        id: 'g',
        stage: GuideStage.pregnant,
        category: GuideCategory.shopping,
        title: 'Mua sắm',
        checklist: [
          GuideChecklistItem(id: 'a', text: 'A'),
          GuideChecklistItem(id: 'b', text: 'B'),
          GuideChecklistItem(id: 'c', text: 'C'),
          GuideChecklistItem(id: 'd', text: 'D'),
        ],
      );
      expect(guide.progress({'a', 'c', 'other'}), 0.5);
      expect(
        const GuideArticle(
          id: 'x',
          stage: GuideStage.pre,
          category: GuideCategory.health,
          title: 'X',
        ).progress({'a'}),
        isNull,
      );
    });
  });

  group('appointment prefill', () {
    PregnancyModel pregnancyDue(DateTime due) => PregnancyModel(
      id: 'p',
      dueDate: due,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('estimated date = pregnancy start + weekFrom * 7 days', () {
      // Start (LMP) = 2026-03-01 -> due 2026-12-06.
      final pregnancy = pregnancyDue(DateTime(2026, 12, 6));
      final date = GuideActions.estimatedDateForWeek(
        pregnancy,
        11,
        now: DateTime(2026, 4, 1),
      );
      expect(date, DateTime(2026, 5, 17));
    });

    test('past milestones are moved to today; missing data gives null', () {
      final pregnancy = pregnancyDue(DateTime(2026, 12, 6));
      expect(
        GuideActions.estimatedDateForWeek(
          pregnancy,
          6,
          now: DateTime(2026, 8, 20, 15),
        ),
        DateTime(2026, 8, 20),
      );
      expect(GuideActions.estimatedDateForWeek(null, 11), isNull);
      expect(GuideActions.estimatedDateForWeek(pregnancy, null), isNull);
    });

    test('maps and phone URIs', () {
      expect(
        GuideActions.mapsSearchUri('bệnh viện phụ sản').toString(),
        startsWith('https://www.google.com/maps/search/?api=1&query='),
      );
      expect(GuideActions.phoneUri('115').toString(), 'tel:115');
      expect(
        GuideActions.phoneUri('028 3829 5723').toString(),
        'tel:02838295723',
      );
    });
  });

  group('Cẩm nang UI', () {
    late List<GuideArticle> fixtureGuides;
    late Map<String, ContentSource> sources;

    setUpAll(() async {
      // Real file IO must happen outside testWidgets' fake async zone.
      fixtureGuides = await ContentPackService.loadGuides(
        _DirectoryAssetBundle(_fixtureRoot),
      );
      sources = await ContentPackService.loadSources(
        _DirectoryAssetBundle(_fixtureRoot),
      );
    });

    Future<void> pumpGuides(
      WidgetTester tester,
      Map<String, Object> prefs,
      List<GuideArticle> guides,
    ) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1290, 2796);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: GuidesScreen(guides: guides)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('pregnancy mode shows pregnant guides with progress', (
      tester,
    ) async {
      await pumpGuides(tester, {
        'app_mode': 'pregnancy',
        'guide_checklist_ticks': '["chk_test_book"]',
      }, fixtureGuides);

      expect(find.text('Cẩm nang'), findsOneWidget);
      expect(find.text('Lịch khám'), findsOneWidget);
      expect(find.text('Lịch khám thai định kỳ'), findsOneWidget);
      expect(find.text('Khám sức khỏe trước khi mang thai'), findsNothing);
      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('pre-pregnancy mode shows pre guides', (tester) async {
      await pumpGuides(tester, {'app_mode': 'prePregnancy'}, fixtureGuides);

      expect(find.text('Sức khỏe'), findsOneWidget);
      expect(find.text('Khám sức khỏe trước khi mang thai'), findsOneWidget);
      expect(find.text('Lịch khám thai định kỳ'), findsNothing);
    });

    testWidgets('empty state when no guides', (tester) async {
      await pumpGuides(tester, {'app_mode': 'pregnancy'}, const []);

      expect(find.text('Cẩm nang đang được cập nhật'), findsOneWidget);
    });

    testWidgets('detail shows draft note, sources and persists ticks', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1290, 2796);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final guide = fixtureGuides.firstWhere(
        (g) => g.id == 'pregnant_checkups',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: GuideDetailScreen(guide: guide, sources: sources),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);
      expect(find.text('Gọi 115'), findsOneWidget);
      expect(find.text('Thêm vào lịch hẹn'), findsWidgets);

      await tester.tap(find.text('Đặt lịch khám đầu tiên'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(await GuideProgressService.loadTicked(), {'chk_test_book'});
      expect(find.text('33%'), findsOneWidget);

      await tester.scrollUntilVisible(find.textContaining('Nguồn:'), 300);
      expect(find.textContaining('World Health Organization'), findsOneWidget);
      expect(find.textContaining('UNKNOWN-SRC'), findsOneWidget);
      expect(find.textContaining('2026-10-29'), findsOneWidget);
    });
  });
}
