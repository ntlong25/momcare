// Phase 30: design critique fixes and motion.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/daily_item_model.dart';
import 'package:momcare/core/models/food_model.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/week_detail_model.dart';
import 'package:momcare/core/theme/app_motion.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/core/widgets/app_card.dart';
import 'package:momcare/core/widgets/app_progress_bar.dart';
import 'package:momcare/core/widgets/section_header.dart';
import 'package:momcare/features/guides/screens/guides_screen.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:momcare/features/home/widgets/today_thai_giao_card.dart';
import 'package:momcare/features/nutrition/screens/nutrition_screen.dart';
import 'package:momcare/features/tracking/screens/week_detail_screen.dart';

Future<void> _loadAppFont() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      File(
        'assets/fonts/BeVietnamPro-$weight.ttf',
      ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
  await loader.load();
}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance() + 0.05;
  final y = b.computeLuminance() + 0.05;
  return x > y ? x / y : y / x;
}

void _setView(WidgetTester tester, {double width = 360, double height = 800}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  addTearDown(tester.view.reset);
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Widget _app(Widget home, {ThemeData? theme, double textScale = 1}) =>
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    );

const _themes = {'light': _Theme.light, 'dark': _Theme.dark};

enum _Theme {
  light,
  dark;

  ThemeData get data => this == light ? AppTheme.light() : AppTheme.dark();
}

void main() {
  setUpAll(_loadAppFont);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('30.1 thai giáo', () {
    const pack = DailyPack(
      type: DailyPack.thaiGiaoType,
      items: [
        DailyItem(
          day: 1,
          week: 1,
          category: 'movement',
          title: 'Đứng lên ngồi xuống với ghế',
          body: 'Đứng trước ghế chắc chắn, từ từ ngồi xuống rồi đứng lên.',
          durationMin: 5,
        ),
      ],
    );
    final done = find.byKey(const ValueKey('thai-giao-done'));

    Future<void> pumpCard(
      WidgetTester tester, {
      ThemeData? theme,
      double textScale = 1,
    }) async {
      _setView(tester);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: SingleChildScrollView(
              child: TodayThaiGiaoCard(day: 1, pack: pack),
            ),
          ),
          theme: theme,
          textScale: textScale,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    List<String> recordHaptics(WidgetTester tester) {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return haptics;
    }

    for (final MapEntry(key: name, value: theme) in _themes.entries) {
      testWidgets('Đã làm is a filled button, the category plain text '
          '($name)', (tester) async {
        await pumpCard(tester, theme: theme.data);
        expect(tester.widget(done), isA<FilledButton>());
        expect(find.byType(Chip), findsNothing);
        expect(find.byType(FilterChip), findsNothing);
        expect(find.text('Vận động nhẹ'), findsOneWidget);
        expect(tester.getSize(done).height, greaterThanOrEqualTo(48));

        final scheme = theme.data.colorScheme;
        final peach = theme.data.extension<AppSemanticColors>()!.peachContainer;
        expect(_contrast(scheme.primary, peach), greaterThanOrEqualTo(3));
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('no overflow at 360 dp x1.5, done and streak ($name)', (
        tester,
      ) async {
        await pumpCard(tester, theme: theme.data, textScale: 1.5);
        await tester.tap(done);
        await tester.pumpAndSettle();
        expect(find.text('Chuỗi 1 ngày'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('light haptic when marking done only', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpCard(tester);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(haptics, hasLength(1));
    });

    testWidgets('the state change takes 250 ms without moving the button', (
      tester,
    ) async {
      await pumpCard(tester);
      final before = tester.getRect(done);
      Color fill() => tester
          .widget<Material>(
            find.descendant(of: done, matching: find.byType(Material)).first,
          )
          .color!;
      final primary = AppTheme.light().colorScheme.primary;
      final success = AppTheme.light().extension<AppSemanticColors>()!.success;
      expect(fill(), primary);

      await tester.tap(done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(fill(), isNot(primary));
      expect(fill(), isNot(success));
      expect(tester.getRect(done).size, before.size);
      await tester.pump(AppMotion.action);
      await tester.pump(const Duration(milliseconds: 50));
      expect(fill(), success);
      expect(tester.getRect(done).size, before.size);
    });

    testWidgets('reduced motion: instant and no haptic', (tester) async {
      _reduceMotion(tester);
      final haptics = recordHaptics(tester);
      await pumpCard(tester);
      await tester.tap(done);
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(tester.takeException(), isNull);
      expect(haptics, isEmpty);
    });
  });

  group('30.2 Công cụ', () {
    Finder tab(String id) => find.byKey(ValueKey('tab-$id'));

    Future<void> pumpTools(
      WidgetTester tester, {
      double width = 411,
      double height = 914,
      double textScale = 1,
      ThemeData? theme,
      bool prePregnancy = false,
    }) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: prePregnancy ? 'prePregnancy' : 'pregnancy',
      });
      ContentPackService.debugFoodPack = const FoodPack.empty();
      addTearDown(
        () => ContentPackService.debugFoodPack = const FoodPack.empty(),
      );
      _setView(tester, width: width, height: height);
      tester.view.padding = const FakeViewPadding(top: 52 * 3);
      await tester.pumpWidget(
        _app(const ToolsTabScreen(), theme: theme, textScale: textScale),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    test('every former sub-screen is a tab, Cần khám among the first four', () {
      expect(
        [for (final p in toolsPages(isPrePregnancy: false)) p.label],
        [
          'Dinh dưỡng',
          'Lịch hẹn',
          'Bộ đếm',
          'Cần khám',
          'Công thức',
          'Ăn được không?',
        ],
      );
      expect(
        [for (final p in toolsPages(isPrePregnancy: true)) p.label],
        ['Dinh dưỡng', 'Lịch hẹn', 'Cần khám', 'Công thức', 'Ăn được không?'],
      );
    });

    testWidgets('one tab bar; content starts in the top third at 411 dp', (
      tester,
    ) async {
      await pumpTools(tester);
      expect(find.byType(TabBar), findsOneWidget);
      final list = tester.getTopLeft(find.byType(RefreshIndicator)).dy;
      expect(list + AppSpacing.lg, lessThan(914 / 3));
      // Cần khám is visible without scrolling the tabs.
      expect(tester.getRect(tab('emergency')).right, lessThanOrEqualTo(411));
    });

    testWidgets('the hospital action has a visible label and a 48 dp target', (
      tester,
    ) async {
      await pumpTools(tester);
      final action = find.byKey(const ValueKey('tools-find-hospital'));
      expect(
        find.descendant(of: action, matching: find.text('Tìm bệnh viện')),
        findsOneWidget,
      );
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    });

    testWidgets('recipes and lookup are reachable and keep their own scroll', (
      tester,
    ) async {
      await pumpTools(tester);
      await tester.dragUntilVisible(
        tab('food-lookup'),
        find.byType(TabBar),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(tab('recipes'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có công thức món ăn'), findsOneWidget);
      await tester.tap(tab('food-lookup'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    for (final MapEntry(key: name, value: theme) in _themes.entries) {
      for (final pre in [false, true]) {
        testWidgets('no overflow at 360 dp x1.5 ($name, pre: $pre)', (
          tester,
        ) async {
          await pumpTools(
            tester,
            width: 360,
            height: 800,
            textScale: 1.5,
            theme: theme.data,
            prePregnancy: pre,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('quick actions still open the full nutrition screen', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_app(const NutritionScreen(focusWeek: 12)));
      await tester.pump();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Hướng dẫn'), findsOneWidget);
    });
  });

  group('30.3 Cẩm nang', () {
    const warning = GuideArticle(
      id: 'warn',
      stage: GuideStage.pregnant,
      category: GuideCategory.warning,
      title: 'Dấu hiệu nguy hiểm',
      summary: 'Gọi 115 hoặc đến cơ sở y tế gần nhất.',
      checklist: [GuideChecklistItem(id: 'w', text: 'Ra máu')],
    );
    const normal = GuideArticle(
      id: 'normal',
      stage: GuideStage.pregnant,
      category: GuideCategory.checkup,
      title: 'Lịch khám thai',
      summary: 'Các mốc khám.',
      checklist: [
        GuideChecklistItem(id: 'a', text: 'Việc một'),
        GuideChecklistItem(id: 'b', text: 'Việc hai'),
      ],
    );

    Future<void> pumpGuides(
      WidgetTester tester, {
      ThemeData? theme,
      double textScale = 1,
      String? ticked,
    }) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'pregnancy',
        AppConstants.guideChecklistKey: ?ticked,
      });
      _setView(tester);
      await tester.pumpWidget(
        _app(
          const GuidesScreen(
            guides: [warning, normal],
            foodPack: FoodPack.empty(),
          ),
          theme: theme,
          textScale: textScale,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Card cardOf(WidgetTester tester, String title) => tester.widget<Card>(
      find.ancestor(of: find.text(title), matching: find.byType(Card)).first,
    );

    for (final MapEntry(key: name, value: theme) in _themes.entries) {
      testWidgets('warning guide uses the alert card ($name)', (tester) async {
        await pumpGuides(tester, theme: theme.data, textScale: 1.5);
        expect(tester.takeException(), isNull);
        final scheme = theme.data.colorScheme;
        final color = cardOf(tester, warning.title).color!;
        expect(color, scheme.errorContainer);
        expect(color, isNot(cardOf(tester, normal.title).color));
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        final summary = tester.widget<Text>(find.text(warning.summary));
        expect(summary.style?.color, scheme.onErrorContainer);
        expect(
          _contrast(scheme.onErrorContainer, scheme.errorContainer),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    testWidgets('P30-R1-04: warning summary is never cut at 360 dp x1.5', (
      tester,
    ) async {
      const long =
          'Nếu có bất kỳ dấu hiệu nào dưới đây, đừng chờ đến lịch hẹn. '
          'Gọi 115 hoặc đến cơ sở y tế gần nhất.';
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'pregnancy',
      });
      _setView(tester);
      await tester.pumpWidget(
        _app(
          const GuidesScreen(
            guides: [
              GuideArticle(
                id: 'warn',
                stage: GuideStage.pregnant,
                category: GuideCategory.warning,
                title: 'Dấu hiệu nguy hiểm',
                summary: long,
              ),
              GuideArticle(
                id: 'normal',
                stage: GuideStage.pregnant,
                category: GuideCategory.checkup,
                title: 'Lịch khám thai',
                summary: long,
              ),
            ],
            foodPack: FoodPack.empty(),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pump();
      final texts = find.text(long);
      expect(texts, findsNWidgets(2));
      Finder inCard(String title) => find.descendant(
        of: find
            .ancestor(of: find.text(title), matching: find.byType(Card))
            .first,
        matching: texts,
      );
      final warningText = tester.renderObject<RenderParagraph>(
        inCard('Dấu hiệu nguy hiểm'),
      );
      expect(warningText.didExceedMaxLines, isFalse);
      // Other guides keep their two-line preview.
      expect(tester.widget<Text>(inCard('Lịch khám thai')).maxLines, 2);
    });

    testWidgets('progress bar shows only after the guide is started', (
      tester,
    ) async {
      await pumpGuides(tester);
      expect(find.byType(AppProgressBar), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await pumpGuides(tester, ticked: '["a"]');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(AppProgressBar), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('section headings rank above card titles', (tester) async {
      await pumpGuides(tester);
      expect(find.byType(SectionHeader), findsNWidgets(2));
      final heading = tester.widget<Text>(
        find.descendant(
          of: find.byType(SectionHeader).first,
          matching: find.byType(Text),
        ),
      );
      final card = tester.widget<Text>(find.text(normal.title));
      expect(heading.style!.fontSize, greaterThan(card.style!.fontSize!));
    });
  });

  group('30.4 title style', () {
    testWidgets('AppCard titles use the one style in every variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Column(
              children: [
                AppCard(title: 'Một'),
                AppCard(title: 'Hai', variant: AppCardVariant.mint),
              ],
            ),
          ),
        ),
      );
      final context = tester.element(find.text('Một'));
      final expected = AppCard.titleTextStyle(context)!;
      for (final title in ['Một', 'Hai']) {
        final style = tester.widget<Text>(find.text(title)).style!;
        expect(style.fontSize, expected.fontSize);
        expect(style.fontWeight, FontWeight.bold);
      }
    });
  });

  group('30.6 motion', () {
    test('tokens match the plan', () {
      expect(AppMotion.progress.inMilliseconds, 600);
      expect(AppMotion.action.inMilliseconds, 250);
      expect(AppMotion.photo.inMilliseconds, 300);
      expect(AppMotion.detail.inMilliseconds, 300);
      expect(AppMotion.week.inMilliseconds, 250);
    });

    double shown(WidgetTester tester) => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    Widget bar(double value, {bool animateIn = false}) => MaterialApp(
      home: Scaffold(
        body: AppProgressBar(value: value, animateIn: animateIn),
      ),
    );

    testWidgets('progress bar takes 600 ms to a new value', (tester) async {
      await tester.pumpWidget(bar(0.2));
      expect(shown(tester), 0.2);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(bar(0.8));
      await tester.pump(const Duration(milliseconds: 300));
      expect(shown(tester), inExclusiveRange(0.2, 0.8));
      await tester.pump(const Duration(milliseconds: 301));
      expect(shown(tester), 0.8);
    });

    testWidgets('animateIn fills from zero and paints on the first frame', (
      tester,
    ) async {
      await tester.pumpWidget(bar(0.5, animateIn: true));
      expect(shown(tester), 0);
      await tester.pumpAndSettle();
      expect(shown(tester), 0.5);
    });

    testWidgets('reduced motion: the bar is at its value at once', (
      tester,
    ) async {
      _reduceMotion(tester);
      await tester.pumpWidget(bar(0.5, animateIn: true));
      await tester.pump();
      expect(shown(tester), 0.5);
      await tester.pumpWidget(bar(0.8));
      await tester.pump();
      await tester.pump();
      expect(shown(tester), 0.8);
    });

    Future<Duration> pushedDuration(WidgetTester tester) async {
      late Route<void> route;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                route = AppMotion.detailRoute<void>(
                  context,
                  (_) => const SizedBox(),
                );
                Navigator.of(context).push(route);
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      return (route as TransitionRoute<void>).transitionDuration;
    }

    testWidgets('card to detail takes 300 ms', (tester) async {
      expect(await pushedDuration(tester), AppMotion.detail);
    });

    testWidgets('reduced motion: card to detail is instant', (tester) async {
      _reduceMotion(tester);
      expect(await pushedDuration(tester), Duration.zero);
    });

    double page(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page!;

    Future<void> pumpWeeks(WidgetTester tester) async {
      _setView(tester);
      await tester.pumpWidget(
        _app(
          const WeekDetailScreen(
            initialWeek: 12,
            weeks: {
              12: WeekDetail(week: 12, sizeCompare: 'quả chanh'),
              13: WeekDetail(week: 13, sizeCompare: 'quả đào'),
            },
            sources: {},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the next week slides in over 250 ms', (tester) async {
      await pumpWeeks(tester);
      await tester.tap(find.byTooltip('Tuần sau'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(page(tester), inExclusiveRange(12, 13));
      await tester.pumpAndSettle();
      expect(find.text('Tuần 13'), findsWidgets);
    });

    testWidgets('reduced motion: the next week is shown at once', (
      tester,
    ) async {
      _reduceMotion(tester);
      await pumpWeeks(tester);
      await tester.tap(find.byTooltip('Tuần sau'));
      await tester.pump();
      expect(page(tester), 13);
      await tester.pump();
      expect(find.text('quả đào'), findsWidgets);
    });
  });
}
