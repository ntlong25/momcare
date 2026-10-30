// Phase 24: honest fertile window prediction, the Hôm nay card and the
// wording shared with the doctor review packet.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/fertile_guidance.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/services/cycle_prediction.dart';
import 'package:momcare/core/services/health_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/date_formatter.dart';
import 'package:momcare/features/fertility/screens/fertility_planner_screen.dart';
import 'package:momcare/features/fertility/widgets/cycle_marker.dart';
import 'package:momcare/features/home/screens/pre_pregnancy_home_screen.dart';
import 'package:momcare/features/home/widgets/late_period_card.dart';
import 'package:momcare/l10n/app_localizations.dart';

/// Cycles starting on [first] and separated by [gaps] days.
List<MenstrualCycleModel> _cycles(DateTime first, List<int> gaps) {
  final starts = <DateTime>[first];
  for (final gap in gaps) {
    final last = starts.last;
    starts.add(DateTime(last.year, last.month, last.day + gap));
  }
  return [
    for (final start in starts)
      MenstrualCycleModel(
        id: start.toIso8601String(),
        startDate: start,
        createdAt: start,
        updatedAt: start,
      ),
  ];
}

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final guidanceJson = File(
    'assets/content/fertile_guidance.json',
  ).readAsStringSync();

  group('CyclePrediction', () {
    test('no cycles gives no prediction', () {
      expect(CyclePrediction.compute(const [], today: _d(2026, 3, 1)), isNull);
      expect(
        HealthService.predictFertileWindow(const [], today: _d(2026, 3, 1)),
        isNull,
      );
    });

    test('regular identical cycles: 6-day window ending on ovulation', () {
      final p = CyclePrediction.compute(
        _cycles(_d(2026, 1, 1), [28, 28, 28]),
        today: _d(2026, 3, 27),
      )!;
      expect(p.nextPeriod, _d(2026, 4, 23));
      expect(p.earliestPeriod, p.latestPeriod);
      expect(p.ovulation, _d(2026, 4, 9));
      expect(p.fertileStart, _d(2026, 4, 4));
      expect(p.fertileEnd, _d(2026, 4, 9));
      expect(p.fertileDays, hasLength(6));
      expect(p.peakStart, _d(2026, 4, 7));
      expect(p.peakEnd, _d(2026, 4, 9));
      expect(p.confidence, PredictionConfidence.medium);
      expect(p.hasCycleOutsideTypicalRange, isFalse);
    });

    test('levels across a regular cycle, peak needs 3+ regular cycles', () {
      final cycles = _cycles(_d(2026, 1, 1), [28, 28, 28]); // last 26/3
      FertilityLevel? at(DateTime day) =>
          CyclePrediction.compute(cycles, today: day)!.todayLevel;
      expect(at(_d(2026, 4, 3)), FertilityLevel.low);
      expect(at(_d(2026, 4, 4)), FertilityLevel.high);
      expect(at(_d(2026, 4, 6)), FertilityLevel.high);
      expect(at(_d(2026, 4, 7)), FertilityLevel.peak);
      expect(at(_d(2026, 4, 9)), FertilityLevel.peak);
      expect(at(_d(2026, 4, 10)), FertilityLevel.low);
    });

    test('varying lengths give ranges from the last 6 cycles', () {
      // The first gap (50) is older than the last 6 and is ignored for the
      // range; the mid estimate still uses the overall average (32), which widens the range.
      final cycles = _cycles(_d(2025, 1, 1), [50, 28, 30, 27, 29, 31, 30]);
      final last = cycles.last.startDate;
      final p = CyclePrediction.compute(cycles, today: last)!;
      DateTime plus(int days) =>
          DateTime(last.year, last.month, last.day + days);
      expect(p.earliestPeriod, plus(27));
      expect(p.nextPeriod, plus(32));
      expect(p.latestPeriod, plus(32));
      expect(p.earliestOvulation, plus(13));
      expect(p.latestOvulation, plus(18));
      expect(p.fertileStart, plus(8));
      expect(p.fertileEnd, plus(18));
    });

    test('irregular: low confidence and capped at high', () {
      final cycles = _cycles(_d(2026, 1, 1), [24, 38, 24, 38]);
      final last = cycles.last.startDate; // average 31
      final mid = DateTime(last.year, last.month, last.day + 17);
      final p = CyclePrediction.compute(cycles, today: mid)!;
      expect(p.regularity, CycleRegularity.irregular);
      expect(p.confidence, PredictionConfidence.low);
      expect(p.ovulation, mid);
      expect(p.todayLevel, FertilityLevel.high);
      expect(p.hasCycleOutsideTypicalRange, isTrue);
    });

    test('1 cycle: default length, low confidence, never peak', () {
      final cycles = _cycles(_d(2026, 3, 1), const []);
      final p = CyclePrediction.compute(cycles, today: _d(2026, 3, 15))!;
      expect(p.nextPeriod, _d(2026, 3, 29));
      expect(p.ovulation, _d(2026, 3, 15));
      expect(p.todayLevel, FertilityLevel.high);
      expect(p.confidence, PredictionConfidence.low);
      expect(p.regularity, CycleRegularity.insufficientData);
    });

    test('2 cycles stay low confidence and capped', () {
      final cycles = _cycles(_d(2026, 2, 1), [28]);
      final p = CyclePrediction.compute(cycles, today: _d(2026, 3, 15))!;
      expect(p.ovulation, _d(2026, 3, 15));
      expect(p.todayLevel, FertilityLevel.high);
      expect(p.confidence, PredictionConfidence.low);
    });

    test('under 21 and over 35 days are flagged', () {
      for (final length in [20, 36]) {
        final cycles = _cycles(_d(2026, 1, 1), [length, length, length]);
        final p = CyclePrediction.compute(
          cycles,
          today: cycles.last.startDate,
        )!;
        expect(p.hasCycleOutsideTypicalRange, isTrue, reason: '$length');
        expect(p.confidence, PredictionConfidence.medium, reason: '$length');
      }
      for (final length in [21, 35]) {
        final cycles = _cycles(_d(2026, 1, 1), [length, length, length]);
        final p = CyclePrediction.compute(
          cycles,
          today: cycles.last.startDate,
        )!;
        expect(p.hasCycleOutsideTypicalRange, isFalse, reason: '$length');
      }
    });

    test('running past the prediction hides the level but rolls forward', () {
      final cycles = _cycles(_d(2026, 1, 1), [28, 28, 28]); // next 23/4
      expect(
        CyclePrediction.compute(cycles, today: _d(2026, 4, 23))!.todayLevel,
        isNotNull,
      );
      final late = CyclePrediction.compute(cycles, today: _d(2026, 4, 24))!;
      expect(late.isLateOrStale, isTrue);
      expect(late.todayLevel, isNull);
      expect(late.nextPeriod, _d(2026, 5, 21));
      expect(
        late.nextPeriod,
        HealthService.predictNextPeriod(cycles, today: _d(2026, 4, 24)),
      );
      expect(late.fertileEnd, _d(2026, 5, 7));
    });

    test('stale data hides the level', () {
      final cycles = _cycles(_d(2026, 1, 1), const []);
      final p = CyclePrediction.compute(cycles, today: _d(2026, 3, 1))!;
      expect(
        HealthService.isCycleDataStale(cycles, today: _d(2026, 3, 1)),
        true,
      );
      expect(p.todayLevel, isNull);
    });

    test('month and year boundaries', () {
      final p = CyclePrediction.compute(
        _cycles(_d(2026, 10, 10), [28, 28]),
        today: _d(2026, 12, 5),
      )!;
      expect(p.nextPeriod, _d(2027, 1, 2));
      expect(p.ovulation, _d(2026, 12, 19));
      expect(p.fertileDays.first, _d(2026, 12, 14));

      final q = CyclePrediction.compute(
        _cycles(_d(2026, 12, 10), [28]),
        today: _d(2027, 1, 7),
      )!;
      expect(q.nextPeriod, _d(2027, 2, 4));
      expect(q.ovulation, _d(2027, 1, 21));
      expect(q.fertileStart, _d(2027, 1, 16));
    });

    test('statusOf matches the late card on every boundary day', () {
      final cycles = _cycles(_d(2026, 1, 1), [28, 28, 28]); // next 23/4
      CycleStatus at(DateTime day) =>
          CyclePrediction.statusOf(cycles, today: day);
      expect(at(_d(2026, 4, 23)), CycleStatus.onTrack);
      expect(at(_d(2026, 4, 24)), CycleStatus.late);
      expect(at(_d(2026, 5, 21)), CycleStatus.late); // 56 days
      expect(at(_d(2026, 5, 22)), CycleStatus.stale); // 57 days
      expect(
        CyclePrediction.statusOf(const [], today: _d(2026, 4, 24)),
        CycleStatus.onTrack,
      );
      for (var i = 0; i < 70; i++) {
        final day = _d(2026, 4, i + 1);
        expect(
          LatePeriodCard.isVisible(cycles, day),
          CyclePrediction.compute(cycles, today: day)!.isLateOrStale,
          reason: '$day',
        );
      }
    });

    group('RangeCountdown', () {
      final start = _d(2026, 10, 26);
      final end = _d(2026, 11, 4);
      String at(DateTime day) =>
          RangeCountdown.of(start, end, day).label('Trong khoảng dự đoán');

      test('before, every day inside, after', () {
        expect(at(_d(2026, 10, 24)), '2 ngày nữa');
        expect(at(_d(2026, 10, 25)), '1 ngày nữa');
        for (var i = 0; i < 10; i++) {
          final day = _d(2026, 10, 26 + i);
          expect(at(day), 'Trong khoảng dự đoán', reason: '$day');
        }
        expect(at(_d(2026, 11, 5)), 'Đã qua 1 ngày');
        expect(at(_d(2026, 11, 8)), 'Đã qua 4 ngày');
      });

      test('a single date says Hôm nay, not a range', () {
        final day = _d(2026, 10, 26);
        expect(RangeCountdown.of(day, day, day).label('Khoảng'), 'Hôm nay');
        expect(
          RangeCountdown.of(day, day, _d(2026, 10, 27)).label('Khoảng'),
          'Đã qua 1 ngày',
        );
      });

      test('crosses a year', () {
        expect(
          RangeCountdown.of(
            _d(2027, 1, 2),
            _d(2027, 1, 4),
            _d(2026, 12, 31),
          ).label(''),
          '2 ngày nữa',
        );
      });
    });

    test('the logic file stays pure', () {
      final imports = File(
        'lib/core/services/cycle_prediction.dart',
      ).readAsLinesSync().where((l) => l.startsWith('import'));
      expect(imports.where((l) => l.contains('flutter')), isEmpty);
      expect(imports.where((l) => l.contains('health_service')), isEmpty);
    });
  });

  group('FertileGuidance pack', () {
    test('asset is complete, draft and honest', () {
      final pack = FertileGuidance.parse(guidanceJson);
      expect(pack.isEmpty, isFalse);
      expect(pack.isDraft, isTrue);
      expect(
        pack.text('not_contraception'),
        contains('không dùng để tránh thai'),
      );
      expect(pack.text('frequency'), contains('1-2 ngày'));
      expect(pack.text('frequency'), contains('không cần kiêng'));
      expect(pack.text('confidence_label'), 'Độ tin cậy');

      final lower = guidanceJson.toLowerCase();
      for (final banned in [
        'giới tính',
        'bé trai',
        'bé gái',
        'thất bại',
        'phải cố',
      ]) {
        expect(lower.contains(banned), isFalse, reason: banned);
      }
      for (final id in FertileGuidance.requiredIds) {
        expect(pack.text(id).contains('%'), isFalse, reason: id);
      }
    });

    test('invalid or incomplete packs are empty', () {
      expect(FertileGuidance.parse('nope').isEmpty, isTrue);
      expect(FertileGuidance.parse('{"items":[]}').isEmpty, isTrue);
      expect(
        FertileGuidance.parse('{"items":[{"id":"title","text":"x"}]}').isEmpty,
        isTrue,
      );
    });

    test('review packet has every string and nothing is approved', () {
      final csv = File(
        'content_source/review/6_canh_ngay.csv',
      ).readAsStringSync();
      final pack = FertileGuidance.parse(guidanceJson);
      for (final id in FertileGuidance.requiredIds) {
        expect(csv, contains(pack.text(id)), reason: id);
      }
      expect(guidanceJson, contains('draft_requires_medical_review'));
      expect(guidanceJson, isNot(contains('"approved"')));
    });
  });

  group('Hôm nay card', () {
    final guidance = FertileGuidance.parse(guidanceJson);
    const cardKey = ValueKey('pre-fertile-today-card');

    setUpAll(() async {
      final loader = FontLoader(AppTheme.fontFamily);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File(
          'assets/fonts/BeVietnamPro-$weight.ttf',
        ).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'prePregnancy',
      });
      ContentPackService.debugGuides = const [];
      ContentPackService.debugFertileGuidance = guidance;
    });

    tearDown(() {
      ContentPackService.debugFertileGuidance = const FertileGuidance.empty();
    });

    Future<void> pumpHome(
      WidgetTester tester,
      List<MenstrualCycleModel> cycles,
      DateTime today, {
      bool dark = false,
      double scale = 1,
      Size size = const Size(360, 3000),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            locale: const Locale('vi'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi')],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: PrePregnancyHomeScreen(
              debugCycles: cycles,
              debugToday: today,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    final regular = _cycles(_d(2026, 1, 1), [28, 28, 28]);

    for (final (day, label) in [
      (_d(2026, 3, 27), 'Thấp (ước tính)'),
      (_d(2026, 4, 5), 'Cao (ước tính)'),
      (_d(2026, 4, 8), 'Đỉnh (ước tính)'),
    ]) {
      testWidgets('shows $label', (tester) async {
        await pumpHome(tester, regular, day);
        expect(tester.takeException(), isNull);
        expect(find.byKey(cardKey), findsOneWidget);
        final card = find.byKey(cardKey);
        Finder inCard(String text) =>
            find.descendant(of: card, matching: find.text(text));
        expect(inCard('Khả năng thụ thai hôm nay'), findsOneWidget);
        expect(inCard(label), findsOneWidget);
        expect(inCard('Độ tin cậy: Trung bình'), findsOneWidget);
        expect(inCard(guidance.text('frequency')), findsOneWidget);
        expect(inCard(guidance.text('not_contraception')), findsOneWidget);
        expect(inCard('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);
      });
    }

    testWidgets('Đỉnh keeps the legend meaning: fertile, not ovulation', (
      tester,
    ) async {
      await pumpHome(tester, regular, _d(2026, 4, 8));
      final marker = tester.widget<CycleMarker>(
        find.descendant(
          of: find.byKey(cardKey),
          matching: find.byType(CycleMarker),
        ),
      );
      expect(marker.kind, CycleMarkerKind.fertile);
    });

    testWidgets('Hôm nay and Chu kỳ word an open ovulation range alike', (
      tester,
    ) async {
      // Lengths 24, 33, 28: ovulation range is day 10-19 of this cycle.
      final now = _d(2026, 10, 30);
      final cycles = _cycles(_d(2026, 7, 23), [24, 33, 28]);
      expect(cycles.last.startDate, _d(2026, 10, 16));
      await pumpHome(tester, cycles, now);
      expect(find.text('Trong khoảng dự đoán'), findsOneWidget);
      expect(find.textContaining('Đã qua'), findsNothing);
    });

    testWidgets('fewer than 3 cycles caps at Cao with low confidence', (
      tester,
    ) async {
      await pumpHome(
        tester,
        _cycles(_d(2026, 3, 1), const []),
        _d(2026, 3, 15),
      );
      expect(find.text('Cao (ước tính)'), findsOneWidget);
      expect(find.text('Độ tin cậy: Thấp'), findsOneWidget);
      expect(find.text('Đỉnh (ước tính)'), findsNothing);
    });

    testWidgets('hidden without cycles', (tester) async {
      await pumpHome(tester, const [], _d(2026, 3, 15));
      expect(find.byKey(cardKey), findsNothing);
    });

    testWidgets('hidden while late, the late-period card takes over', (
      tester,
    ) async {
      await pumpHome(tester, regular, _d(2026, 4, 24));
      expect(find.byKey(cardKey), findsNothing);
      expect(find.byKey(const ValueKey('late-period-card')), findsOneWidget);
    });

    testWidgets('hidden on stale data', (tester) async {
      await pumpHome(tester, regular, _d(2026, 7, 1));
      expect(find.byKey(cardKey), findsNothing);
      expect(find.byKey(const ValueKey('late-period-card')), findsOneWidget);
    });

    testWidgets('hidden when the wording pack is missing', (tester) async {
      ContentPackService.debugFertileGuidance = const FertileGuidance.empty();
      await pumpHome(tester, regular, _d(2026, 4, 5));
      expect(find.byKey(cardKey), findsNothing);
    });

    testWidgets('comes after the greeting, before the prediction cards', (
      tester,
    ) async {
      await pumpHome(tester, regular, _d(2026, 4, 5));
      double top(String key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy;
      expect(top('pre-home-greeting'), lessThan(top(cardKey.value)));
      expect(top(cardKey.value), lessThan(top('pre-fertile-window-card')));
      expect(
        top('pre-fertile-window-card'),
        lessThan(top('pre-ovulation-card')),
      );
    });

    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      for (final (day, cycles) in [
        (_d(2026, 4, 8), regular),
        (_d(2026, 4, 24), _cycles(_d(2026, 1, 1), [20, 38, 24, 38])),
      ]) {
        testWidgets('$mode: 360 dp at 1.5x with Be Vietnam Pro, $day', (
          tester,
        ) async {
          await pumpHome(tester, cycles, day, dark: dark, scale: 1.5);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('$mode: card text meets 4.5:1', (tester) async {
        await pumpHome(tester, regular, _d(2026, 4, 8), dark: dark);
        final context = tester.element(find.byKey(cardKey));
        final scheme = Theme.of(context).colorScheme;
        final background = scheme.surfaceContainerLow;
        for (final text in tester.widgetList<Text>(
          find.descendant(of: find.byKey(cardKey), matching: find.byType(Text)),
        )) {
          final color = text.style?.color ?? scheme.onSurface;
          if (text.data == 'Nội dung đang chờ bác sĩ duyệt') continue;
          expect(
            _contrast(color, background),
            greaterThanOrEqualTo(4.5),
            reason: text.data,
          );
        }
      });
    }
  });

  group('Chu kỳ predictions', () {
    late Directory hiveDir;
    late List<MenstrualCycleModel> cycles;

    setUpAll(() async {
      hiveDir = await Directory.systemTemp.createTemp('momcare_fertile');
      Hive.init(hiveDir.path);
      if (!Hive.isAdapterRegistered(MenstrualCycleModelAdapter().typeId)) {
        Hive.registerAdapter(MenstrualCycleModelAdapter());
      }
      await Hive.openBox<MenstrualCycleModel>(AppConstants.menstrualCycleBox);
      ContentPackService.debugFertileGuidance = FertileGuidance.parse(
        guidanceJson,
      );
    });

    tearDownAll(() async {
      ContentPackService.debugFertileGuidance = const FertileGuidance.empty();
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    /// Replaces the stored cycles; gaps end [daysAgo] days before today.
    Future<void> seed(List<int> gaps, int daysAgo) async {
      final box = Hive.box<MenstrualCycleModel>(AppConstants.menstrualCycleBox);
      await box.clear();
      final now = DateTime.now();
      final total = gaps.fold<int>(0, (sum, gap) => sum + gap);
      cycles = _cycles(
        DateTime(now.year, now.month, now.day - daysAgo - total),
        gaps,
      );
      for (final cycle in cycles) {
        await box.put(cycle.id, cycle);
      }
    }

    Future<void> pumpPlanner(
      WidgetTester tester, {
      double width = 412,
      double scale = 1,
    }) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('vi'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi')],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const FertilityPlannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    void expectNoCurrentPrediction() {
      expect(find.text('Dự đoán'), findsNothing);
      expect(find.text('Cửa sổ thụ thai'), findsNothing);
      expect(find.text('Ngày rụng trứng dự kiến'), findsNothing);
      expect(find.byKey(const ValueKey('cycle-confidence')), findsNothing);
      for (final kind in const [
        CycleMarkerKind.ovulation,
        CycleMarkerKind.fertile,
        CycleMarkerKind.predictedPeriod,
      ]) {
        expect(
          find.byKey(ValueKey('cycle-marker-${kind.name}')),
          findsNothing,
          reason: kind.name,
        );
      }
      expect(find.text('Kỳ kinh đã ghi'), findsOneWidget);
    }

    group('late', () {
      setUp(() => seed([28, 28], 30));

      testWidgets('shows the late message instead of rolled-forward dates', (
        tester,
      ) async {
        await pumpPlanner(tester);
        expectNoCurrentPrediction();
        expect(find.text('Trễ kinh 2 ngày → có thể thử thai'), findsOneWidget);
      });

      testWidgets('fits 360 dp at 1.5x', (tester) async {
        await pumpPlanner(tester, width: 360, scale: 1.5);
        expect(tester.takeException(), isNull);
      });
    });

    group('stale', () {
      setUp(() => seed([28, 28], 70));

      testWidgets('asks to update the data instead of predicting', (
        tester,
      ) async {
        await pumpPlanner(tester);
        expectNoCurrentPrediction();
        expect(find.text('Đã lâu bạn chưa ghi kỳ kinh mới'), findsOneWidget);
      });
    });

    group('inside the ovulation range', () {
      setUp(() => seed([24, 33, 28], 14));

      testWidgets('says so instead of Đã qua', (tester) async {
        await pumpPlanner(tester);
        expect(find.text('Trong khoảng dự đoán'), findsOneWidget);
        expect(find.textContaining('Đã qua'), findsNothing);
        expect(find.text('10 ngày nữa'), findsOneWidget);
      });

      testWidgets('fits 360 dp at 1.5x', (tester) async {
        await pumpPlanner(tester, width: 360, scale: 1.5);
        expect(tester.takeException(), isNull);
      });
    });

    group('date format', () {
      setUp(() => seed([26, 30], 2));

      testWidgets('rows show ranges and the confidence is stated', (
        tester,
      ) async {
        await pumpPlanner(tester);

        final last = cycles.last.startDate;
        expect(
          find.text('Bắt đầu ${DateFormatter.formatDate(last)}'),
          findsOneWidget,
          reason: 'history uses the same format as Dự đoán',
        );

        final p = CyclePrediction.compute(cycles, today: DateTime.now())!;
        expect(p.earliestPeriod, isNot(p.latestPeriod));
        for (final (start, end) in [
          (p.earliestPeriod, p.latestPeriod),
          (p.earliestOvulation, p.latestOvulation),
          (p.fertileStart, p.fertileEnd),
        ]) {
          expect(
            find.text(DateFormatter.formatDateRange(start, end)),
            findsOneWidget,
          );
        }
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('cycle-confidence')))
              .data,
          'Độ tin cậy: Trung bình',
        );
        expect(find.textContaining('không dùng để tránh thai'), findsOneWidget);
        expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);
      });
    });
  });
}
