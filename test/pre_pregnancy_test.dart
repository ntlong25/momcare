import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/models/pre_readiness.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/providers/app_mode_provider.dart';
import 'package:momcare/core/services/guide_progress_service.dart';
import 'package:momcare/core/services/health_service.dart';
import 'package:momcare/features/guides/screens/guide_detail_screen.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:momcare/features/home/screens/pre_pregnancy_home_screen.dart';
import 'package:momcare/features/home/widgets/late_period_card.dart';
import 'package:momcare/features/home/widgets/pre_readiness_card.dart';
import 'package:momcare/features/home/widgets/pregnant_switch_card.dart';
import 'package:momcare/features/onboarding/screens/pregnancy_setup_screen.dart';

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

GuideArticle _guide(
  String id, {
  GuideStage stage = GuideStage.pre,
  GuideCategory category = GuideCategory.health,
  int order = 0,
  int items = 0,
  ReviewStatus review = ReviewStatus.draftRequiresMedicalReview,
}) => GuideArticle(
  id: id,
  stage: stage,
  category: category,
  title: 'Guide $id',
  summary: 'Tóm tắt $id',
  order: order,
  checklist: [
    for (var i = 0; i < items; i++)
      GuideChecklistItem(id: '${id}_c$i', text: 'Việc $i của $id'),
  ],
  reviewStatus: review,
);

/// 3 + 2 pre items, a pregnant guide and a pre warning guide (not tracked).
List<GuideArticle> _fixtures() => [
  _guide('pre_b', order: 20, items: 2),
  _guide('pre_a', order: 10, items: 3),
  _guide('preg', stage: GuideStage.pregnant, items: 4),
  _guide('pre_warn', category: GuideCategory.warning, order: 5, items: 2),
];

MenstrualCycleModel _cycle(DateTime start) {
  final stamp = DateTime(2026, 1, 1);
  return MenstrualCycleModel(
    id: 'c_${start.toIso8601String()}',
    startDate: start,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

/// Persists the mode only after a frame, like the platform-channel write on a
/// device, so widgets rebuilt by the new state are disposed before
/// [setMode] completes.
class _SlowPersistAppModeNotifier extends AppModeNotifier {
  @override
  Future<void> setMode(AppMode mode) async {
    state = mode;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await super.setMode(mode);
  }
}

void _setView(WidgetTester tester, {double width = 360, double height = 800}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  group('PreReadiness.compute', () {
    test('counts pre checklists only, in guide order', () {
      final guides = _fixtures();
      final empty = PreReadiness.compute(guides, const {});
      expect(empty.done, 0);
      expect(empty.total, 5);
      expect(empty.percent, 0);
      expect(empty.isEmpty, isFalse);
      expect(empty.isDraft, isTrue);
      expect(empty.entries.map((e) => e.guide.id), ['pre_a', 'pre_b']);
      expect(empty.nextUp.map((e) => e.guide.id), ['pre_a', 'pre_b']);

      final one = PreReadiness.compute(guides, {'pre_a_c0'});
      expect(one.done, 1);
      expect(one.total, 5);
      expect(one.percent, 20);
    });

    test('ticks outside pre checklists are ignored', () {
      final r = PreReadiness.compute(_fixtures(), {
        'preg_c0',
        'pre_warn_c0',
        'unknown',
      });
      expect(r.done, 0);
      expect(r.percent, 0);
    });

    test('all ticked gives 100% and an empty nextUp', () {
      final r = PreReadiness.compute(_fixtures(), {
        for (var i = 0; i < 3; i++) 'pre_a_c$i',
        for (var i = 0; i < 2; i++) 'pre_b_c$i',
      });
      expect(r.percent, 100);
      expect(r.isComplete, isTrue);
      expect(r.nextUp, isEmpty);
    });

    test('nextUp skips complete guides and is capped at 3', () {
      final guides = [
        for (var i = 0; i < 5; i++) _guide('g$i', order: i, items: 1),
      ];
      final r = PreReadiness.compute(guides, {'g0_c0'});
      expect(r.nextUp.map((e) => e.guide.id), ['g1', 'g2', 'g3']);
    });

    test('no pre guides gives isEmpty and 0%', () {
      final r = PreReadiness.compute(
        [_guide('preg', stage: GuideStage.pregnant, items: 3)],
        {'preg_c0'},
      );
      expect(r.isEmpty, isTrue);
      expect(r.total, 0);
      expect(r.percent, 0);
      expect(r.ratio, 0);
      expect(r.nextUp, isEmpty);
      expect(PreReadiness.compute(const [], const {}).isEmpty, isTrue);
    });

    test('approved-only pre guides are not draft', () {
      final r = PreReadiness.compute([
        _guide('a', items: 1, review: ReviewStatus.approved),
      ], const {});
      expect(r.isDraft, isFalse);
    });

    test('bundled content: 8 pre guides, 43 items, unique ids', () async {
      final guides = await ContentPackService.loadGuides(
        _DirectoryAssetBundle('assets/content'),
      );
      final r = PreReadiness.compute(guides, const {});
      expect(r.entries, hasLength(8));
      expect(r.total, 43);
      expect(r.entries.map((e) => e.guide.id), contains(earlySignsGuideId));
      final ids = [
        for (final e in r.entries) ...e.guide.checklist.map((c) => c.id),
      ];
      expect(ids.toSet().length, ids.length);
    });
  });

  group('HealthService late period', () {
    final start = DateTime(2026, 10, 1);

    test('expected date is last start + 28 by default', () {
      expect(
        HealthService.expectedPeriodDate([_cycle(start)]),
        DateTime(2026, 10, 29),
      );
      expect(HealthService.expectedPeriodDate(const []), isNull);
    });

    test('daysLate counts days past the expected date', () {
      final cycles = [_cycle(start)];
      int late(DateTime today) => HealthService.daysLate(cycles, today: today);
      expect(late(DateTime(2026, 10, 20)), 0);
      expect(late(DateTime(2026, 10, 29)), 0);
      expect(late(DateTime(2026, 10, 30)), 1);
      expect(late(DateTime(2026, 11, 3)), 5);
      expect(late(DateTime(2026, 11, 3, 23, 30)), 5);
      expect(HealthService.daysLate(const [], today: start), 0);
    });

    test('a future start gives 0', () {
      expect(
        HealthService.daysLate([
          _cycle(DateTime(2026, 12, 1)),
        ], today: DateTime(2026, 11, 3)),
        0,
      );
    });

    test('unsorted input gives the same result', () {
      final sorted = [
        _cycle(DateTime(2026, 8, 6)),
        _cycle(DateTime(2026, 9, 3)),
        _cycle(start),
      ];
      final unsorted = [sorted[1], sorted[2], sorted[0]];
      final today = DateTime(2026, 11, 3);
      expect(
        HealthService.expectedPeriodDate(unsorted),
        DateTime(2026, 10, 29),
      );
      expect(
        HealthService.daysLate(unsorted, today: today),
        HealthService.daysLate(sorted, today: today),
      );
      expect(HealthService.daysLate(unsorted, today: today), 5);
    });

    test('uses the average cycle length when known', () {
      final cycles = [_cycle(DateTime(2026, 8, 31)), _cycle(start)];
      // 31-day gap -> expected 1/11.
      expect(HealthService.expectedPeriodDate(cycles), DateTime(2026, 11, 1));
      expect(HealthService.daysLate(cycles, today: DateTime(2026, 11, 3)), 2);
    });

    test('stale boundary on 28 days: 56 still estimates, 57 is stale', () {
      final cycles = [_cycle(start)];
      bool stale(int days) => HealthService.isCycleDataStale(
        cycles,
        today: DateTime(start.year, start.month, start.day + days),
      );
      expect(stale(30), isFalse);
      expect(stale(56), isFalse);
      expect(stale(57), isTrue);
      expect(stale(70), isTrue);
      expect(HealthService.isCycleDataStale(const []), isFalse);
    });

    test('predictNextPeriod still rolls forward', () {
      expect(
        HealthService.predictNextPeriod([
          _cycle(start),
        ], today: DateTime(2026, 11, 3)),
        DateTime(2026, 11, 26),
      );
    });
  });

  group('Hôm nay pre-pregnancy widgets', () {
    late List<GuideArticle> guides;

    setUp(() {
      guides = [
        ..._fixtures(),
        _guide(earlySignsGuideId, category: GuideCategory.signs, order: 80),
      ];
      ContentPackService.debugGuides = guides;
    });

    tearDown(() {
      ContentPackService.debugGuides = const [];
    });

    Future<ProviderContainer> pump(
      WidgetTester tester,
      Widget child, {
      Map<String, Object> prefs = const {},
      bool scroll = true,
      double width = 360,
      List<Override> overrides = const [],
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      _setView(tester, width: width);
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      // Create the notifiers now so they load the mocked prefs while pumping.
      container.read(appModeProvider);
      container.read(guideChecklistProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: scroll
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    )
                  : child,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      return container;
    }

    testWidgets('readiness card shows progress and reacts to ticks', (
      tester,
    ) async {
      final container = await pump(
        tester,
        PreReadinessCard(guides: _fixtures()),
      );
      expect(find.text('Sẵn sàng mang thai'), findsOneWidget);
      expect(find.text('0/5 việc · 0%'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pre-readiness-row-pre_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pre-readiness-row-pre_b')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pre-readiness-row-preg')),
        findsNothing,
      );
      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await container
          .read(guideChecklistProvider.notifier)
          .toggle('pre_a_c0', true);
      await tester.pump();
      expect(find.text('1/5 việc · 20%'), findsOneWidget);

      for (final id in ['pre_a_c1', 'pre_a_c2', 'pre_b_c0', 'pre_b_c1']) {
        await container.read(guideChecklistProvider.notifier).toggle(id, true);
      }
      await tester.pump();
      expect(find.text('5/5 việc · 100%'), findsOneWidget);
      expect(find.textContaining('Bạn đã hoàn thành'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pre-readiness-row-pre_a')),
        findsNothing,
      );
    });

    testWidgets('readiness row opens the guide, "Xem tất cả" sets tab 2', (
      tester,
    ) async {
      final container = await pump(
        tester,
        PreReadinessCard(guides: _fixtures()),
      );
      await tester.tap(find.byKey(const ValueKey('pre-readiness-see-all')));
      await tester.pump();
      expect(container.read(navigationIndexProvider), 2);

      await tester.tap(find.byKey(const ValueKey('pre-readiness-row-pre_b')));
      await tester.pumpAndSettle();
      final detail = tester.widget<GuideDetailScreen>(
        find.byType(GuideDetailScreen),
      );
      expect(detail.guide.id, 'pre_b');
    });

    testWidgets('readiness card is hidden without pre guides', (tester) async {
      await pump(
        tester,
        PreReadinessCard(
          guides: [_guide('preg', stage: GuideStage.pregnant, items: 2)],
        ),
      );
      expect(find.text('Sẵn sàng mang thai'), findsNothing);
      expect(find.byKey(const ValueKey('pre-readiness-card')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    final today = DateTime(2026, 10, 31);
    DateTime daysAgo(int days) =>
        DateTime(today.year, today.month, today.day - days);

    testWidgets('late period card: 30 days on 28 days -> 2 days late', (
      tester,
    ) async {
      await pump(
        tester,
        LatePeriodCard(cycles: [_cycle(daysAgo(30))], today: today),
      );
      expect(find.text('Trễ kinh 2 ngày → có thể thử thai'), findsOneWidget);
      expect(
        find.text(
          'Kỳ kinh dự kiến: 29/10/2026 (theo chu kỳ trung bình 28 ngày)',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('chỉ là ước tính'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('late-period-regularity-note')),
        findsOneWidget,
      );
      expect(find.textContaining('Chưa đủ dữ liệu chu kỳ'), findsOneWidget);
      expect(find.text('Tôi đã có thai'), findsOneWidget);
      expect(find.text('Ghi kỳ kinh mới'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('late-period-guide')));
      await tester.pumpAndSettle();
      final detail = tester.widget<GuideDetailScreen>(
        find.byType(GuideDetailScreen),
      );
      expect(detail.guide.id, earlySignsGuideId);
    });

    testWidgets('late period card: regular cycles have no extra note', (
      tester,
    ) async {
      await pump(
        tester,
        LatePeriodCard(
          cycles: [
            _cycle(daysAgo(86)),
            _cycle(daysAgo(58)),
            _cycle(daysAgo(30)),
          ],
          today: today,
        ),
      );
      expect(find.text('Trễ kinh 2 ngày → có thể thử thai'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('late-period-regularity-note')),
        findsNothing,
      );
    });

    testWidgets('late period card hidden when not late or no cycles', (
      tester,
    ) async {
      await pump(
        tester,
        Column(
          children: [
            LatePeriodCard(cycles: [_cycle(daysAgo(28))], today: today),
            LatePeriodCard(cycles: [_cycle(daysAgo(3))], today: today),
            LatePeriodCard(cycles: const [], today: today),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('late-period-card')), findsNothing);
      expect(find.textContaining('Trễ kinh'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stale data asks to update the cycle', (tester) async {
      await pump(
        tester,
        LatePeriodCard(cycles: [_cycle(daysAgo(70))], today: today),
      );
      expect(find.text('Đã lâu bạn chưa ghi kỳ kinh mới'), findsOneWidget);
      expect(find.textContaining('Trễ kinh'), findsNothing);
      expect(find.text('Ghi kỳ kinh mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing early-signs guide hides button and entry card', (
      tester,
    ) async {
      ContentPackService.debugGuides = _fixtures();
      await pump(
        tester,
        Column(
          children: [
            LatePeriodCard(cycles: [_cycle(daysAgo(30))], today: today),
            const EarlySignsEntryCard(),
          ],
        ),
      );
      expect(find.text('Trễ kinh 2 ngày → có thể thử thai'), findsOneWidget);
      expect(find.text('Xem dấu hiệu & cách thử thai'), findsNothing);
      expect(find.text('Dấu hiệu mang thai sớm'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('early-signs entry card opens the guide', (tester) async {
      await pump(tester, const EarlySignsEntryCard());
      expect(find.text('Dấu hiệu mang thai sớm'), findsOneWidget);
      await tester.tap(find.text('Dấu hiệu mang thai sớm'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<GuideDetailScreen>(find.byType(GuideDetailScreen))
            .guide
            .id,
        earlySignsGuideId,
      );
    });

    const prePrefs = <String, Object>{AppConstants.appModeKey: 'prePregnancy'};

    testWidgets('"Hủy" keeps pre-pregnancy mode and pushes nothing', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const PregnantSwitchCard(),
        prefs: prePrefs,
      );
      expect(container.read(appModeProvider), AppMode.prePregnancy);
      await tester.tap(find.byKey(const ValueKey('pregnant-switch-button')));
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(container.read(appModeProvider), AppMode.prePregnancy);
      expect(find.byType(PregnancySetupScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('"Tiếp tục" without a pregnancy opens setup; skip pops', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const PregnantSwitchCard(),
        prefs: prePrefs,
      );
      await tester.tap(find.byKey(const ValueKey('pregnant-switch-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      final setup = tester.widget<PregnancySetupScreen>(
        find.byType(PregnancySetupScreen),
      );
      expect(setup.fromModeSwitch, isTrue);
      expect(container.read(appModeProvider), AppMode.prePregnancy);

      final skip = find.text('Bỏ qua lúc này');
      await tester.ensureVisible(skip);
      await tester.pumpAndSettle();
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(find.byType(PregnancySetupScreen), findsNothing);
      expect(find.byType(PregnantSwitchCard), findsOneWidget);
      expect(find.byType(MainNavigation), findsNothing);
      expect(container.read(appModeProvider), AppMode.prePregnancy);
    });

    testWidgets('setup back without data pops and keeps the mode', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const PregnantSwitchCard(),
        prefs: prePrefs,
      );
      await tester.tap(find.byKey(const ValueKey('pregnant-switch-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(PregnancySetupScreen), findsNothing);
      expect(container.read(appModeProvider), AppMode.prePregnancy);
    });

    testWidgets('"Tiếp tục" with a pregnancy switches even though the card '
        'is disposed by the mode change', (tester) async {
      final pregnancy = PregnancyModel(
        id: 'p1',
        dueDate: DateTime(2027, 5, 1),
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      // Like MainNavigation: the card only exists in pre-pregnancy mode.
      final container = await pump(
        tester,
        Consumer(
          builder: (context, ref, _) =>
              ref.watch(appModeProvider) == AppMode.prePregnancy
              ? PregnantSwitchCard(debugActivePregnancy: () => pregnancy)
              : const Text('pregnancy-home'),
        ),
        prefs: prePrefs,
        overrides: [
          appModeProvider.overrideWith((ref) => _SlowPersistAppModeNotifier()),
        ],
      );
      container.read(navigationIndexProvider.notifier).state = 3;
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('pregnant-switch-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      // The card is gone before setMode completes, as on a device.
      expect(find.byType(PregnantSwitchCard), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PregnantSwitchCard), findsNothing);
      expect(find.text('pregnancy-home'), findsOneWidget);
      expect(container.read(appModeProvider), AppMode.pregnancy);
      expect(container.read(navigationIndexProvider), 0);
      expect(find.text('Đã chuyển sang chế độ Đang mang thai'), findsOneWidget);
      expect(find.byType(PregnancySetupScreen), findsNothing);
    });

    testWidgets('late period hides the fertile-window and ovulation cards', (
      tester,
    ) async {
      await pump(
        tester,
        PrePregnancyHomeScreen(
          debugCycles: [_cycle(daysAgo(30))],
          debugToday: today,
        ),
        prefs: prePrefs,
        scroll: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('late-period-card')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pre-fertile-window-card')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('pre-ovulation-card')), findsNothing);
      expect(find.text('Cửa sổ thụ thai'), findsNothing);
      expect(find.text('Ngày rụng trứng dự kiến'), findsNothing);
    });

    testWidgets('a period started today shows both prediction cards', (
      tester,
    ) async {
      final now = DateTime.now();
      final realToday = DateTime(now.year, now.month, now.day);
      await pump(
        tester,
        PrePregnancyHomeScreen(
          debugCycles: [_cycle(realToday)],
          debugToday: realToday,
        ),
        prefs: prePrefs,
        scroll: false,
        // The pre-existing prediction rows overflow the wide test font at
        // 360 dp; their layout is out of scope here.
        width: 480,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('late-period-card')), findsNothing);
      final scrollable = find.byType(Scrollable).first;
      for (final key in ['pre-fertile-window-card', 'pre-ovulation-card']) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey(key)),
          200,
          scrollable: scrollable,
        );
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(find.text('Cửa sổ thụ thai'), findsOneWidget);
      expect(find.text('Ngày rụng trứng dự kiến'), findsOneWidget);
    });

    testWidgets('PrePregnancyHomeScreen builds at 360 dp without cycles', (
      tester,
    ) async {
      final container = await pump(
        tester,
        const PrePregnancyHomeScreen(),
        prefs: prePrefs,
        scroll: false,
      );
      expect(tester.takeException(), isNull);
      expect(container.read(appModeProvider), AppMode.prePregnancy);
      expect(find.byKey(const ValueKey('late-period-card')), findsNothing);
      expect(find.text('null', findRichText: true), findsNothing);

      final scrollable = find.byType(Scrollable).first;
      for (final text in [
        'Sẵn sàng mang thai',
        'Dấu hiệu mang thai sớm',
        'Tôi đã có thai',
      ]) {
        await tester.scrollUntilVisible(
          find.text(text),
          200,
          scrollable: scrollable,
        );
        expect(find.text(text), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
