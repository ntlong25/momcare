import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/data/pregnancy_weeks_data.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/health_log_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/models/week_detail_model.dart';
import 'package:momcare/features/guides/screens/guide_detail_screen.dart';
import 'package:momcare/features/guides/screens/guides_screen.dart';
import 'package:momcare/features/tracking/screens/tracking_screen.dart';
import 'package:momcare/features/tracking/screens/week_detail_screen.dart';
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

const _weeksFixtures = 'test/fixtures/content/weeks_v2';

String _fixture(String name) =>
    File('$_weeksFixtures/$name').readAsStringSync();

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  group('weeks_v2 parser', () {
    test('parses valid entries, skips bad weeks and duplicates', () {
      final weeks = ContentPackService.parseWeekDetails(_fixture('valid.json'));

      expect(weeks.keys.toList()..sort(), [0, 20, 21]);
      final w20 = weeks[20]!;
      expect(w20.sizeCompare, 'quả chuối');
      expect(w20.lengthCm, 25.6);
      expect(w20.weightG, 300.0);
      expect(w20.lengthText, '25.6 cm');
      expect(w20.weightText, '300 g');
      // Empty and non-string list entries are dropped.
      expect(w20.commonSymptoms, ['Đau lưng', 'Táo bón']);
      expect(w20.examsThisWeek, ['Siêu âm hình thái học (tuần 20–22)']);
      expect(w20.sources, ['WHO-ANC', 'UNKNOWN-SRC']);
      expect(w20.lastUpdated, '2026-10-29');
      expect(w20.isDraft, isTrue);
    });

    test('null size/length/weight and int/double numbers', () {
      final weeks = ContentPackService.parseWeekDetails(_fixture('valid.json'));

      final w0 = weeks[0]!;
      expect(w0.sizeCompare, isNull);
      expect(w0.lengthCm, isNull);
      expect(w0.weightG, isNull);
      expect(w0.lengthText, isNull);
      expect(w0.weightText, isNull);
      expect(w0.examsThisWeek, isEmpty);

      final w21 = weeks[21]!;
      expect(w21.lengthCm, 27.0);
      expect(w21.lengthText, '27 cm');
      expect(w21.weightG, 360.5);
      expect(w21.weightText, '360.5 g');
      // Missing lists default to empty.
      expect(w21.redFlags, isEmpty);
      expect(w21.babyDevelopment, isEmpty);
      expect(w21.image, isNull);
    });

    test('approved pack is not a draft', () {
      final weeks = ContentPackService.parseWeekDetails(
        _fixture('approved.json'),
      );
      expect(weeks[5]!.isDraft, isFalse);
      expect(weeks[5]!.lastUpdated, '2026-11-01');
    });

    test('invalid JSON, wrong shape and missing file yield empty', () async {
      expect(
        ContentPackService.parseWeekDetails(_fixture('invalid_json.json')),
        isEmpty,
      );
      expect(
        ContentPackService.parseWeekDetails(_fixture('wrong_shape.json')),
        isEmpty,
      );
      expect(ContentPackService.parseWeekDetails('[]'), isEmpty);
      expect(
        await ContentPackService.loadWeekDetails(
          _DirectoryAssetBundle('test/fixtures/does_not_exist'),
        ),
        isEmpty,
      );
    });

    test('resolver clamps and falls back to pregnancy_weeks data', () {
      final weeks = ContentPackService.parseWeekDetails(_fixture('valid.json'));

      expect(
        ContentPackService.resolveWeekDetail(20, weeks).sizeCompare,
        'quả chuối',
      );

      final fallback = ContentPackService.resolveWeekDetail(17, weeks);
      final legacy = PregnancyWeeksDatabase.getWeekData(17);
      expect(fallback.week, 17);
      expect(fallback.babyDevelopment, legacy.development);
      expect(fallback.redFlags, legacy.redFlags);

      expect(ContentPackService.resolveWeekDetail(-5, const {}).week, 0);
      expect(ContentPackService.resolveWeekDetail(99, const {}).week, 42);
      expect(
        ContentPackService.resolveWeekDetail(30, const {}).babyDevelopment,
        PregnancyWeeksDatabase.getWeekData(30).development,
      );
    });

    test('bundled weeks_v2.json has weeks 0..42 with known sources', () async {
      final bundle = _DirectoryAssetBundle('assets/content');
      final weeks = await ContentPackService.loadWeekDetails(bundle);
      final sources = await ContentPackService.loadSources(bundle);

      expect(weeks.keys.toList()..sort(), List.generate(43, (i) => i));
      for (final week in [0, 1, 2, 3]) {
        expect(weeks[week]!.lengthCm, isNull);
        expect(weeks[week]!.weightG, isNull);
      }
      expect(weeks[20]!.sizeCompare, 'quả chuối');
      expect(weeks[20]!.lengthCm, 25.6);
      expect(weeks[20]!.weightG, 300);

      final ids = weeks.values.expand((w) => w.sources).toSet();
      expect(ids.where((id) => !sources.containsKey(id)), isEmpty);
    });
  });

  group('WeekDetailScreen', () {
    late Map<int, WeekDetail> weeks;
    late Map<String, ContentSource> sources;

    setUpAll(() async {
      final bundle = _DirectoryAssetBundle('assets/content');
      weeks = await ContentPackService.loadWeekDetails(bundle);
      sources = await ContentPackService.loadSources(bundle);
    });

    Future<void> pumpWeek(WidgetTester tester, int week, {int? current}) async {
      await _setPhoneViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: WeekDetailScreen(
            initialWeek: week,
            currentWeek: current,
            weeks: weeks,
            sources: sources,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('week 20 shows content, placeholder, sources and draft note', (
      tester,
    ) async {
      await pumpWeek(tester, 20);

      expect(find.text('Tuần 20'), findsWidgets);
      expect(find.text('Tuần hiện tại'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('week-image-placeholder')),
        findsOneWidget,
      );
      expect(find.text('quả chuối'), findsOneWidget);
      expect(find.text('25.6 cm'), findsOneWidget);
      expect(find.text('300 g'), findsOneWidget);
      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);

      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Siêu âm hình thái học (tuần 20–22)'),
        300,
        scrollable: list,
      );
      await tester.scrollUntilVisible(
        find.text('Dấu hiệu cần đi khám ngay'),
        300,
        scrollable: list,
      );
      expect(find.text('Xem hướng dẫn cấp cứu'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Nguồn:'),
        300,
        scrollable: list,
      );
      expect(find.textContaining('null'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swipe and arrows change the week', (tester) async {
      await pumpWeek(tester, 20);

      await tester.fling(find.byType(PageView), const Offset(-250, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Tuần 21'), findsWidgets);
      expect(find.textContaining('Về tuần hiện tại (20)'), findsOneWidget);

      await tester.tap(find.byTooltip('Tuần trước'));
      await tester.pumpAndSettle();
      expect(find.text('Tuần 20'), findsWidgets);
      expect(find.text('Tuần hiện tại'), findsOneWidget);
    });

    testWidgets('week 0 has no length/weight/null and prev disabled', (
      tester,
    ) async {
      await pumpWeek(tester, 0, current: 17);

      expect(find.text('Tuần 0'), findsWidgets);
      expect(find.text('Chiều dài'), findsNothing);
      expect(find.text('Cân nặng'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(find.text('Đang chuẩn bị'), findsOneWidget);
      final prev = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      expect(prev.onPressed, isNull);

      await tester.tap(find.textContaining('Về tuần hiện tại (17)'));
      await tester.pumpAndSettle();
      expect(find.text('Tuần 17'), findsWidgets);
    });

    testWidgets('all 43 pages build without exceptions', (tester) async {
      await pumpWeek(tester, 42);
      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(next.onPressed, isNull);

      for (var week = 0; week <= 42; week++) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(week),
            home: WeekDetailScreen(
              initialWeek: week,
              weeks: weeks,
              sources: sources,
            ),
          ),
        );
        await tester.pump();
        final list = find.byType(Scrollable).last;
        await tester.drag(list, const Offset(0, -5000));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'week $week');
        expect(find.textContaining('null'), findsNothing, reason: 'week $week');
      }
    });
  });

  group('Tuần thai entry point', () {
    late Directory hiveDir;

    setUpAll(() async {
      hiveDir = await Directory.systemTemp.createTemp('momcare_week_test');
      Hive.init(hiveDir.path);
      if (!Hive.isAdapterRegistered(HealthLogModelAdapter().typeId)) {
        Hive.registerAdapter(HealthLogModelAdapter());
      }
      await Hive.openBox<HealthLogModel>(AppConstants.healthLogBox);
    });

    tearDownAll(() async {
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    testWidgets('one tap opens the detail screen on the current week', (
      tester,
    ) async {
      // The legacy header and chart rows overflow with the wide test font at
      // phone width (pre-existing, unrelated to this entry point).
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(1800, 2796);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final now = DateTime.now();
      // Start 17 weeks + 3 days ago -> current week 17.
      final start = DateTime(now.year, now.month, now.day - 17 * 7 - 3);
      final pregnancy = PregnancyModel(
        id: 'p',
        dueDate: PregnancyModel.dueDateFromLastPeriod(start),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(pregnancy.currentWeek, 17);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: TrackingScreen(showAppBar: false, pregnancy: pregnancy),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('bản cập nhật sau'), findsNothing);
      await tester.tap(find.text('Xem chi tiết tuần 17'));
      await tester.pumpAndSettle();

      expect(find.byType(WeekDetailScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Tuần 17'),
        ),
        findsOneWidget,
      );
      expect(find.text('Tuần hiện tại'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WeekDetailScreen), findsNothing);
      expect(find.text('Xem chi tiết tuần 17'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tracking-week-header')));
      await tester.pumpAndSettle();
      expect(find.byType(WeekDetailScreen), findsOneWidget);
    });
  });

  group('warning guides', () {
    const warning = GuideArticle(
      id: 'pregnant_warning_signs',
      stage: GuideStage.pregnant,
      category: GuideCategory.warning,
      title: 'Dấu hiệu nguy hiểm cần đi khám ngay',
      checklist: [
        GuideChecklistItem(id: 'w_bleed', text: 'Ra máu âm đạo'),
        GuideChecklistItem(
          id: 'w_call',
          text: 'Gọi cấp cứu khi cần',
          actionType: GuideActionType.call,
          actionLabel: 'Gọi 115',
          actionValue: '115',
        ),
      ],
    );
    const normal = GuideArticle(
      id: 'pregnant_checkups',
      stage: GuideStage.pregnant,
      category: GuideCategory.checkup,
      title: 'Lịch khám thai định kỳ',
      checklist: [GuideChecklistItem(id: 'chk_n1', text: 'Đặt lịch khám')],
    );

    test('warning guides do not track progress', () {
      expect(warning.tracksProgress, isFalse);
      expect(warning.progress({'w_bleed'}), isNull);
      expect(normal.tracksProgress, isTrue);
      expect(normal.progress(const {}), 0);
    });

    testWidgets('Cẩm nang card has no progress bar for warning guide', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
      await _setPhoneViewport(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GuidesScreen(guides: [warning, normal])),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Dấu hiệu nguy hiểm cần đi khám ngay'), findsOneWidget);
      expect(find.text('Lịch khám thai định kỳ'), findsOneWidget);
      // Only the normal guide shows a progress bar.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('warning detail renders bullets, normal detail checkboxes', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setPhoneViewport(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GuideDetailScreen(guide: warning, sources: {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Ra máu âm đạo'), findsOneWidget);
      expect(find.text('Gọi 115'), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GuideDetailScreen(guide: normal, sources: {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });
}
