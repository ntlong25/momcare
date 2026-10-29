import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/data/food_content_parser.dart';
import 'package:momcare/core/models/food_model.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/week_detail_model.dart';
import 'package:momcare/core/utils/food_filter.dart';
import 'package:momcare/core/utils/vietnamese_text.dart';
import 'package:momcare/features/guides/screens/guides_screen.dart';
import 'package:momcare/features/nutrition/screens/food_lookup_screen.dart';
import 'package:momcare/features/nutrition/screens/nutrition_screen.dart';
import 'package:momcare/features/nutrition/widgets/food_detail_sheet.dart';
import 'package:momcare/features/nutrition/widgets/weekly_nutrition_focus_card.dart';
import 'package:momcare/features/nutrition/widgets/food_verdict_badge.dart';

const _fixtureRoot = 'test/fixtures/content';
const _bundledRoot = 'assets/content';

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

FoodItem _food(
  String id,
  String name, {
  List<String> aliases = const [],
  String group = 'dish',
  FoodVerdict verdict = FoodVerdict.ok,
}) => FoodItem(
  id: id,
  name: name,
  aliases: aliases,
  group: group,
  verdict: verdict,
);

List<String> _ids(List<FoodItem> items) => items.map((i) => i.id).toList();

void main() {
  late FoodPack fixturePack;
  late FoodPack bundledPack;
  late Map<String, ContentSource> fixtureSources;
  late Map<String, ContentSource> bundledSources;
  late Map<int, WeekDetail> bundledWeeks;

  setUpAll(() async {
    // Real file IO must happen outside testWidgets' fake async zone.
    fixturePack = await FoodContentParser.loadFoods(
      _DirectoryAssetBundle(_fixtureRoot),
    );
    fixtureSources = await ContentPackService.loadSources(
      _DirectoryAssetBundle(_fixtureRoot),
    );
    bundledPack = await FoodContentParser.loadFoods(
      _DirectoryAssetBundle(_bundledRoot),
    );
    bundledSources = await ContentPackService.loadSources(
      _DirectoryAssetBundle(_bundledRoot),
    );
    bundledWeeks = await ContentPackService.loadWeekDetails(
      _DirectoryAssetBundle(_bundledRoot),
    );
  });

  tearDown(() {
    ContentPackService.debugFoodPack = const FoodPack.empty();
    ContentPackService.debugWeekDetails = const {};
  });

  // ------------------------------------------------------------- 18.1 model

  group('FoodContentParser', () {
    test('parses the fixture pack', () {
      expect(_ids(fixturePack.items), [
        'rau_ngot',
        'dau_bap',
        'ngot_ngao',
        'pate',
        'thit_bo',
        'ca_kiem',
      ]);
      expect(fixturePack.isDraft, isTrue);
      expect(fixturePack.lastUpdated, '2026-10-29');
      final rauNgot = fixturePack.items.first;
      expect(rauNgot.name, 'Rau ngót');
      expect(rauNgot.aliases, ['bồ ngót']);
      expect(rauNgot.group, 'vegetable');
      expect(rauNgot.groupLabel, 'Rau củ');
      expect(rauNgot.verdict, FoodVerdict.ok);
      expect(rauNgot.reason, 'Lý do rau ngót');
      expect(rauNgot.tip, 'Lời khuyên rau ngót');
      expect(rauNgot.sources, ['WHO-ANC']);
    });

    test('skips unknown verdicts, empty names and duplicate ids', () {
      final ids = _ids(fixturePack.items);
      expect(ids, isNot(contains('unknown_verdict')));
      expect(ids, isNot(contains('empty_name')));
      expect(ids.where((id) => id == 'rau_ngot'), hasLength(1));
      // The first duplicate wins.
      expect(fixturePack.items.first.verdict, FoodVerdict.ok);
    });

    test('invalid JSON or a missing foods list give an empty pack', () {
      expect(FoodContentParser.parseFoods('{ not json').isEmpty, isTrue);
      expect(FoodContentParser.parseFoods('[]').isEmpty, isTrue);
      expect(FoodContentParser.parseFoods('{"version": 1}').isEmpty, isTrue);
      expect(FoodContentParser.parseFoods('{"foods": 3}').isEmpty, isTrue);
    });

    test('missing file gives an empty pack without throwing', () async {
      final pack = await FoodContentParser.loadFoods(
        _DirectoryAssetBundle('test/fixtures/does_not_exist'),
      );
      expect(pack.isEmpty, isTrue);
    });

    test('approved pack is not draft', () {
      final pack = FoodContentParser.parseFoods(
        '{"reviewStatus": "approved", "foods": []}',
      );
      expect(pack.isDraft, isFalse);
    });

    test('verdict labels and group labels', () {
      expect(FoodVerdict.ok.label, 'Nên ăn');
      expect(FoodVerdict.limit.label, 'Hạn chế');
      expect(FoodVerdict.avoid.label, 'Tránh');
      expect(
        FoodVerdict.values.map((v) => v.tone).toSet(),
        hasLength(FoodVerdict.values.length),
      );
      expect(FoodGroups.labels, hasLength(13));
      expect(FoodGroups.label('something_new'), 'Khác');
    });

    test('bundled foods.json: counts, groups and source ids', () {
      final items = bundledPack.items;
      expect(items, hasLength(198));
      expect(items.map((i) => i.id).toSet(), hasLength(198));
      int count(FoodVerdict v) => items.where((i) => i.verdict == v).length;
      expect(count(FoodVerdict.ok), 103);
      expect(count(FoodVerdict.limit), 64);
      expect(count(FoodVerdict.avoid), 31);
      for (final item in items) {
        expect(
          FoodGroups.labels.containsKey(item.group),
          isTrue,
          reason: '${item.id} group ${item.group}',
        );
        for (final source in item.sources) {
          expect(
            bundledSources.containsKey(source),
            isTrue,
            reason: '${item.id} source $source',
          );
        }
      }
    });
  });

  // ------------------------------------------------------------ 18.2 search

  group('normalizeVi and FoodFilter', () {
    test('normalizeVi strips marks, maps đ and collapses spaces', () {
      expect(normalizeVi('Đậu Bắp'), 'dau bap');
      expect(normalizeVi('  RAU   NGÓT '), 'rau ngot');
      expect(normalizeVi('Cá kiếm, ỨC GÀ, quýt'), 'ca kiem, uc ga, quyt');
      // Decomposed (NFD) input.
      expect(normalizeVi('ngót'), 'ngot');
    });

    test('accent-insensitive name and alias search', () {
      for (final query in ['rau ngot', 'RAU NGÓT', 'bo ngot']) {
        expect(
          _ids(FoodFilter.apply(fixturePack.items, query: query)),
          contains('rau_ngot'),
          reason: query,
        );
      }
      expect(_ids(FoodFilter.apply(fixturePack.items, query: 'dau bap')), [
        'dau_bap',
      ]);
    });

    test('verdict and group combine with AND', () {
      final result = FoodFilter.apply(
        fixturePack.items,
        verdict: FoodVerdict.avoid,
        group: 'meat',
      );
      expect(_ids(result), ['pate']);
      expect(
        _ids(FoodFilter.apply(fixturePack.items, verdict: FoodVerdict.avoid)),
        unorderedEquals(['pate', 'ca_kiem']),
      );
    });

    test('blank query returns all, no match returns none', () {
      expect(FoodFilter.apply(fixturePack.items, query: '  '), hasLength(6));
      expect(FoodFilter.apply(fixturePack.items, query: 'xyzxyz'), isEmpty);
    });

    test('prefix matches come first, then name and id order', () {
      final items = [
        _food('b', 'Bánh canh'),
        _food('a2', 'Cá kiếm'),
        _food('a1', 'Cá kiếm'),
        _food('c', 'Thịt bò'),
      ];
      expect(_ids(FoodFilter.apply(items, query: 'ca')), ['a1', 'a2', 'b']);
      expect(_ids(FoodFilter.apply(items)), ['b', 'a1', 'a2', 'c']);
    });

    test('groupsIn lists the groups present in label order', () {
      expect(FoodFilter.groupsIn(fixturePack.items), [
        'vegetable',
        'meat',
        'seafood',
        'sweet',
      ]);
      expect(FoodFilter.groupsIn([_food('x', 'X', group: 'zzz')]), ['zzz']);
    });

    test('bundled data: pa te, and verdicts partition all items', () {
      expect(
        FoodFilter.apply(bundledPack.items, query: 'pa te').map((i) => i.name),
        contains('Pa tê'),
      );
      final seen = <String>{};
      for (final verdict in FoodVerdict.values) {
        for (final item in FoodFilter.apply(
          bundledPack.items,
          verdict: verdict,
        )) {
          expect(seen.add(item.id), isTrue, reason: item.id);
        }
      }
      expect(seen, hasLength(198));
    });
  });

  // ------------------------------------------------------- 18.3 lookup + sheet

  group('FoodLookupScreen', () {
    Future<void> pumpLookup(
      WidgetTester tester, {
      FoodPack? pack,
      Size size = const Size(400, 900),
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: FoodLookupScreen(
            pack: pack ?? fixturePack,
            sources: fixtureSources,
          ),
        ),
      );
      await tester.pump();
    }

    // Chip rows scroll horizontally; the wide test font pushes later chips
    // off-screen.
    Future<void> tapChip(WidgetTester tester, Finder chip) async {
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();
    }

    Future<void> search(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }

    testWidgets('lists everything with a count and a draft note', (
      tester,
    ) async {
      await pumpLookup(tester);
      expect(find.text('Bầu ăn được không?'), findsOneWidget);
      expect(find.text('6 kết quả'), findsOneWidget);
      expect(find.text('Rau ngót'), findsOneWidget);
      expect(find.text('bồ ngót'), findsOneWidget);
      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);
      // Verdict badges carry text, not only colour.
      expect(find.text('Tránh'), findsNWidgets(3)); // chip + 2 badges
    });

    testWidgets('search by name without accents and by alias', (tester) async {
      await pumpLookup(tester);
      await search(tester, 'dau bap');
      expect(find.text('Đậu bắp'), findsOneWidget);
      expect(find.text('Rau ngót'), findsNothing);
      expect(find.text('1 kết quả'), findsOneWidget);

      await search(tester, 'pate gan');
      expect(find.text('Pa tê'), findsOneWidget);
      expect(find.text('1 kết quả'), findsOneWidget);

      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pump();
      expect(find.text('6 kết quả'), findsOneWidget);
    });

    testWidgets('verdict chip filters and resets; combines with group', (
      tester,
    ) async {
      await pumpLookup(tester);
      final avoidChip = find.widgetWithText(FilterChip, 'Tránh');
      await tapChip(tester, avoidChip);
      expect(find.text('2 kết quả'), findsOneWidget);
      expect(find.text('Rau ngót'), findsNothing);

      await tapChip(tester, find.widgetWithText(FilterChip, 'Thịt'));
      expect(find.text('1 kết quả'), findsOneWidget);
      expect(find.text('Pa tê'), findsOneWidget);
      expect(find.text('Cá kiếm'), findsNothing);

      // Tapping the selected verdict chip again resets the verdict row.
      await tapChip(tester, avoidChip);
      expect(find.text('2 kết quả'), findsOneWidget);
      expect(find.text('Thịt bò'), findsOneWidget);
    });

    testWidgets('no-match text', (tester) async {
      await pumpLookup(tester);
      await search(tester, 'xyzxyz');
      expect(find.text('0 kết quả'), findsOneWidget);
      expect(find.text(FoodLookupScreen.noResultsText), findsOneWidget);
    });

    testWidgets('detail sheet shows reason, tip, sources and notes', (
      tester,
    ) async {
      await pumpLookup(tester);
      await tester.tap(find.text('Pa tê'));
      await tester.pumpAndSettle();

      final sheet = find.byType(FoodDetailSheet);
      expect(sheet, findsOneWidget);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      expect(inSheet(find.text('Vì sao')), findsOneWidget);
      expect(inSheet(find.text('Lý do pa tê')), findsOneWidget);
      expect(inSheet(find.text('Lời khuyên')), findsOneWidget);
      expect(inSheet(find.text('Lời khuyên pa tê')), findsOneWidget);
      expect(inSheet(find.text('Tránh')), findsOneWidget);
      expect(inSheet(find.text(FoodDetailSheet.seeDoctorText)), findsOneWidget);
      expect(
        inSheet(find.text('Nội dung đang chờ bác sĩ duyệt')),
        findsOneWidget,
      );
      expect(
        inSheet(find.textContaining('World Health Organization')),
        findsOneWidget,
      );
      expect(inSheet(find.textContaining('UNKNOWN-SRC')), findsOneWidget);
      expect(inSheet(find.textContaining('2026-10-29')), findsOneWidget);
      expect(inSheet(find.text(FoodDetailSheet.disclaimer)), findsOneWidget);
      expect(inSheet(find.text(FoodDetailSheet.noSourcesText)), findsNothing);
    });

    testWidgets('ok item without sources shows the fallback line', (
      tester,
    ) async {
      await pumpLookup(tester);
      await tester.tap(find.text('Đậu bắp'));
      await tester.pumpAndSettle();

      final sheet = find.byType(FoodDetailSheet);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      expect(inSheet(find.text(FoodDetailSheet.noSourcesText)), findsOneWidget);
      expect(inSheet(find.textContaining('Chưa gắn nguồn')), findsOneWidget);
      expect(inSheet(find.text(FoodDetailSheet.seeDoctorText)), findsNothing);
    });

    testWidgets('empty pack shows the empty text', (tester) async {
      await pumpLookup(tester, pack: const FoodPack.empty());
      expect(find.text(FoodLookupScreen.emptyPackText), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 360x640 (list and sheet)', (tester) async {
      await pumpLookup(tester, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      await search(tester, 'pa');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Pa tê'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ------------------------------------------------------ 18.4 weekly focus

  group('WeeklyNutritionFocusCard', () {
    final details = {
      0: const WeekDetail(week: 0, nutritionFocus: ['Bổ sung acid folic']),
      12: const WeekDetail(
        week: 12,
        nutritionFocus: ['Ăn đủ đạm', 'Uống đủ nước'],
      ),
      13: const WeekDetail(week: 13),
      14: const WeekDetail(
        week: 14,
        nutritionFocus: ['Đã duyệt'],
        reviewStatus: ReviewStatus.approved,
      ),
    };

    Future<void> pumpCard(WidgetTester tester, int? week) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyNutritionFocusCard(week: week, details: details),
          ),
        ),
      );
    }

    testWidgets('week 12 shows title, lines and draft note', (tester) async {
      await pumpCard(tester, 12);
      expect(find.text('Dinh dưỡng tuần 12'), findsOneWidget);
      expect(find.text('Ăn đủ đạm'), findsOneWidget);
      expect(find.text('Uống đủ nước'), findsOneWidget);
      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);
    });

    testWidgets('week 0 shows the pre-pregnancy title', (tester) async {
      await pumpCard(tester, 0);
      expect(find.text('Dinh dưỡng khi chuẩn bị mang thai'), findsOneWidget);
      expect(find.text('Bổ sung acid folic'), findsOneWidget);
    });

    testWidgets('null week or empty focus hides the card', (tester) async {
      await pumpCard(tester, null);
      expect(find.byType(Card), findsNothing);
      await pumpCard(tester, 13);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('approved content has no draft note', (tester) async {
      await pumpCard(tester, 14);
      expect(find.text('Dinh dưỡng tuần 14'), findsOneWidget);
      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsNothing);
    });

    test('every bundled week 0-42 has a focus line', () {
      for (var week = 0; week <= 42; week++) {
        expect(
          bundledWeeks[week]?.nutritionFocus ?? const <String>[],
          isNotEmpty,
          reason: 'week $week',
        );
      }
    });
  });

  // ------------------------------------------------------ 18.5 entry points

  group('NutritionScreen tabs', () {
    Future<void> pumpNutrition(
      WidgetTester tester, {
      int initialTab = 0,
      double width = 360,
      double height = 800,
      double textScale = 1.0,
    }) async {
      SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
      ContentPackService.debugFoodPack = fixturePack;
      ContentPackService.debugWeekDetails = {
        12: const WeekDetail(week: 12, nutritionFocus: ['Ăn đủ đạm']),
      };
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, height);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: NutritionScreen(initialTab: initialTab, focusWeek: 12),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('three tabs; guides tab shows the weekly focus card', (
      tester,
    ) async {
      await pumpNutrition(tester);
      expect(find.text('Hướng dẫn'), findsOneWidget);
      expect(find.text('Công thức'), findsOneWidget);
      expect(find.text('Ăn được không?'), findsOneWidget);
      expect(find.text('Dinh dưỡng tuần 12'), findsOneWidget);
      expect(find.text('Ăn đủ đạm'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The tab row is scrollable, so bring the third tab into view first.
      await tester.ensureVisible(find.text('Ăn được không?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn được không?'));
      await tester.pumpAndSettle();
      expect(find.byType(FoodLookupScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('6 kết quả'), findsOneWidget);
    });

    testWidgets('initialTab 2 opens the lookup; out of range is clamped', (
      tester,
    ) async {
      await pumpNutrition(tester, initialTab: 2);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('6 kết quả'), findsOneWidget);

      await pumpNutrition(tester, initialTab: 9);
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('tab labels are not truncated at 360x640, scale $scale', (
        tester,
      ) async {
        await pumpNutrition(tester, height: 640, textScale: scale);
        expect(tester.takeException(), isNull);
        for (final label in ['Hướng dẫn', 'Công thức', 'Ăn được không?']) {
          final textFinder = find.descendant(
            of: find.byType(TabBar),
            matching: find.text(label),
          );
          expect(textFinder, findsOneWidget, reason: label);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: textFinder, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          expect(
            paragraph.size.width,
            greaterThanOrEqualTo(
              paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
            ),
            reason: '$label is truncated',
          );
          final tabRect = tester.getRect(
            find.ancestor(of: textFinder, matching: find.byType(Tab)),
          );
          final labelRect = tester.getRect(textFinder);
          expect(
            labelRect.left >= tabRect.left - 0.5 &&
                labelRect.right <= tabRect.right + 0.5 &&
                labelRect.top >= tabRect.top - 0.5 &&
                labelRect.bottom <= tabRect.bottom + 0.5,
            isTrue,
            reason: '$label rect $labelRect outside tab $tabRect',
          );
        }
      });
    }
  });

  group('GuidesScreen food entry card', () {
    Future<void> pumpGuides(WidgetTester tester, FoodPack pack) async {
      SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: GuidesScreen(guides: const [], foodPack: pack),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('card shows, pushes the lookup and back returns', (
      tester,
    ) async {
      await pumpGuides(tester, fixturePack);
      expect(find.text('Bầu ăn được không?'), findsOneWidget);
      expect(find.text('Tra cứu nhanh 6 thực phẩm, món ăn'), findsOneWidget);

      await tester.tap(find.text('Bầu ăn được không?'));
      await tester.pumpAndSettle();
      expect(find.byType(FoodLookupScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(FoodLookupScreen), findsNothing);
      expect(find.text('Cẩm nang'), findsOneWidget);
    });

    testWidgets('card hidden with an empty pack', (tester) async {
      await pumpGuides(tester, const FoodPack.empty());
      expect(find.text('Bầu ăn được không?'), findsNothing);
      expect(find.text('Cẩm nang đang được cập nhật'), findsOneWidget);
    });
  });
}
