// Phase 23 tester round 1: calendars and stats at font scale 1.5 on a 360 dp
// phone (R1-01, R1-02), the dark mode switch (R1-03), delete-all resetting
// in-memory state (R1-05, R1-06), skipped pregnancy setup (R1-07) and past
// predictions (R1-08). R1-04 is covered in legal_screens_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/models/appointment_model.dart';
import 'package:momcare/core/models/health_log_model.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/models/nutrition_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/models/recipe_model.dart';
import 'package:momcare/core/providers/app_mode_provider.dart';
import 'package:momcare/core/providers/disclaimer_consent_provider.dart';
import 'package:momcare/core/providers/theme_provider.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/date_formatter.dart';
import 'package:momcare/features/appointments/screens/appointments_screen.dart';
import 'package:momcare/features/fertility/screens/fertility_planner_screen.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:momcare/features/legal/screens/disclaimer_consent_screen.dart';
import 'package:momcare/features/onboarding/screens/onboarding_screen.dart';
import 'package:momcare/features/onboarding/screens/pregnancy_setup_screen.dart';
import 'package:momcare/features/settings/screens/settings_screen.dart';
import 'package:momcare/l10n/app_localizations.dart';

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

void _setPhone(
  WidgetTester tester, {
  double width = 360,
  double textScale = 1.5,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, 800 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _app(Widget home, {ProviderContainer? container}) {
  final app = Consumer(
    builder: (context, ref, _) => MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeProvider),
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi')],
      home: home,
    ),
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

/// Height the text needs, even when its parent clips it to less.
double _neededHeight(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  return paragraph.getMinIntrinsicHeight(paragraph.size.width);
}

/// One-line height of [text] at its current style and scale.
double _oneLineHeight(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  return paragraph.getMinIntrinsicHeight(double.infinity);
}

void _expectCalendarFits(WidgetTester tester) {
  final calendar = tester.widget<TableCalendar<dynamic>>(
    find.byWidgetPredicate((w) => w is TableCalendar),
  );
  for (final label in ['T2', 'T7', 'CN']) {
    final text = find.text(label).first;
    expect(
      _neededHeight(tester, text),
      lessThanOrEqualTo(calendar.daysOfWeekHeight),
      reason: '$label must not be clipped',
    );
    expect(
      _neededHeight(tester, text),
      _oneLineHeight(tester, text),
      reason: '$label stays on one line',
    );
  }
  expect(calendar.rowHeight, greaterThan(52));

  final title = find.textContaining(RegExp(r'^Tháng \d+, \d{4}$'));
  expect(title, findsOneWidget);
  expect(
    _neededHeight(tester, title),
    _oneLineHeight(tester, title),
    reason: 'header title stays on one line',
  );
  expect(tester.takeException(), isNull);
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    await _loadAppFont();
    await initializeDateFormatting('vi');
    // In-memory boxes (bytes:): real file IO never finishes in fake async,
    // which the delete-all flow runs in.
    hiveDir = await Directory.systemTemp.createTemp('momcare_p23_r1');
    Hive.init(hiveDir.path);
    Hive.registerAdapter(PregnancyModelAdapter());
    Hive.registerAdapter(HealthLogModelAdapter());
    Hive.registerAdapter(AppointmentModelAdapter());
    Hive.registerAdapter(MenstrualCycleModelAdapter());
    Hive.registerAdapter(NutritionModelAdapter());
    Hive.registerAdapter(RecipeModelAdapter());
    final empty = Uint8List(0);
    await Hive.openBox<PregnancyModel>(AppConstants.pregnancyBox, bytes: empty);
    await Hive.openBox<HealthLogModel>(AppConstants.healthLogBox, bytes: empty);
    await Hive.openBox<AppointmentModel>(
      AppConstants.appointmentBox,
      bytes: empty,
    );
    await Hive.openBox<MenstrualCycleModel>(
      AppConstants.menstrualCycleBox,
      bytes: empty,
    );
    await Hive.openBox<NutritionModel>(AppConstants.nutritionBox, bytes: empty);
    await Hive.openBox<RecipeModel>(AppConstants.recipeBox, bytes: empty);
    await Hive.openBox(AppConstants.settingsBox, bytes: empty);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.box<MenstrualCycleModel>(AppConstants.menstrualCycleBox).clear();
  });

  group('R1-01 calendars at font scale 1.5', () {
    for (final width in [360.0, 412.0]) {
      testWidgets('Chu kỳ at $width dp', (tester) async {
        _setPhone(tester, width: width);
        await tester.pumpWidget(_app(const FertilityPlannerScreen()));
        await tester.pumpAndSettle();
        _expectCalendarFits(tester);
      });

      testWidgets('Lịch hẹn at $width dp, every format', (tester) async {
        _setPhone(tester, width: width);
        await tester.pumpWidget(_app(const AppointmentsScreen()));
        await tester.pumpAndSettle();
        _expectCalendarFits(tester);

        for (final next in ['2 tuần', 'Tuần']) {
          await tester.tap(
            find
                .descendant(
                  of: find.byWidgetPredicate((w) => w is TableCalendar),
                  matching: find.byType(InkWell),
                )
                .at(1),
          );
          await tester.pumpAndSettle();
          expect(find.text(next), findsOneWidget);
          _expectCalendarFits(tester);
        }
      });
    }

    testWidgets('font scale 1.0 keeps the package row height', (tester) async {
      _setPhone(tester, textScale: 1);
      await tester.pumpWidget(_app(const FertilityPlannerScreen()));
      await tester.pumpAndSettle();
      final calendar = tester.widget<TableCalendar<dynamic>>(
        find.byWidgetPredicate((w) => w is TableCalendar),
      );
      expect(calendar.rowHeight, 52);
      expect(
        _neededHeight(tester, find.text('T2').first),
        lessThanOrEqualTo(calendar.daysOfWeekHeight),
      );
    });
  });

  group('R1-02 Thống kê chu kỳ at font scale 1.5', () {
    testWidgets('fits 360 dp with the values kept apart', (tester) async {
      _setPhone(tester);
      await tester.pumpWidget(_app(const FertilityPlannerScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final values = [
        find.text('28 ngày'),
        find.text('Chưa đủ dữ liệu'),
        find.text('0 kỳ kinh'),
      ];
      await tester.ensureVisible(values.first);
      await tester.pumpAndSettle();

      final rects = [for (final value in values) tester.getRect(value)];
      expect(rects[0].right, lessThan(rects[1].left));
      expect(rects[1].right, lessThan(rects[2].left));
      expect(rects[2].right, lessThanOrEqualTo(360));
      for (final value in values) {
        expect(
          tester.renderObject<RenderParagraph>(value).didExceedMaxLines,
          isFalse,
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('R1-03 dark mode switch', () {
    Future<void> pumpSettings(
      WidgetTester tester, {
      required Brightness device,
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      tester.platformDispatcher.platformBrightnessTestValue = device;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(_app(const SettingsScreen()));
      await tester.pumpAndSettle();
    }

    bool switchValue(WidgetTester tester) =>
        tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value;

    Brightness shown(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

    Future<void> tapSwitch(WidgetTester tester) async {
      await tester.tap(find.text('Chế độ tối'));
      await tester.pumpAndSettle();
    }

    testWidgets('light device, fresh install: first tap goes dark', (
      tester,
    ) async {
      await pumpSettings(tester, device: Brightness.light);
      expect(switchValue(tester), isFalse);

      await tapSwitch(tester);

      expect(shown(tester), Brightness.dark);
      expect(switchValue(tester), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppConstants.themeKey), ThemeMode.dark.index);
    });

    testWidgets('dark device, fresh install: switch is on, first tap goes '
        'light', (tester) async {
      await pumpSettings(tester, device: Brightness.dark);
      expect(shown(tester), Brightness.dark);
      expect(switchValue(tester), isTrue);

      await tapSwitch(tester);

      expect(shown(tester), Brightness.light);
      expect(switchValue(tester), isFalse);
    });

    testWidgets('a saved choice wins over the device brightness', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        device: Brightness.light,
        prefs: {AppConstants.themeKey: ThemeMode.dark.index},
      );
      expect(switchValue(tester), isTrue);

      await tapSwitch(tester);

      expect(shown(tester), Brightness.light);
      expect(switchValue(tester), isFalse);
    });
  });

  group('R1-05, R1-06 Xóa toàn bộ dữ liệu', () {
    const notifications = MethodChannel(
      'dexterous.com/flutter/local_notifications',
    );

    /// Lets the photo and temp-folder cleanup finish: it does real file IO,
    /// which never completes inside fake async alone.
    Future<void> finishDelete(WidgetTester tester) async {
      final consent = find.byType(DisclaimerConsentScreen);
      for (var i = 0; i < 100 && consent.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('resets theme, tab and mode as well as the stored data', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notifications,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          notifications,
          null,
        ),
      );
      SharedPreferences.setMockInitialValues({
        AppConstants.themeKey: ThemeMode.dark.index,
        AppConstants.appModeKey: 'prePregnancy',
        AppConstants.disclaimerAcceptedVersionKey:
            AppConstants.disclaimerVersion,
        AppConstants.disclaimerAcceptedAtKey: '2026-10-30T00:00:00.000Z',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _app(const SettingsScreen(), container: container),
      );
      await tester.pumpAndSettle();
      container.read(navigationIndexProvider.notifier).state = 4;
      expect(container.read(themeProvider), ThemeMode.dark);
      expect(container.read(appModeProvider), AppMode.prePregnancy);

      await tester.scrollUntilVisible(
        find.text('Xóa toàn bộ dữ liệu'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'XOA');
      await tester.tap(find.text('Xóa dữ liệu'));
      await finishDelete(tester);

      // First run again: the disclaimer comes before onboarding.
      expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(container.read(disclaimerConsentProvider), isFalse);
      await tester.drag(
        find.byKey(const ValueKey('disclaimer-consent-scroll')),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('disclaimer-accept')));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      expect(container.read(navigationIndexProvider), 0);
      expect(container.read(themeProvider), ThemeNotifier.defaultMode);
      expect(container.read(appModeProvider), isNull);
      expect(tester.takeException(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppConstants.themeKey), isNull);
      expect(prefs.getString(AppConstants.appModeKey), isNull);
    });

    testWidgets('clears the stored disclaimer acceptance', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notifications,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          notifications,
          null,
        ),
      );
      SharedPreferences.setMockInitialValues({
        AppConstants.disclaimerAcceptedVersionKey:
            AppConstants.disclaimerVersion,
        AppConstants.disclaimerAcceptedAtKey: '2026-10-30T00:00:00.000Z',
      });
      await tester.pumpWidget(_app(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Xóa toàn bộ dữ liệu'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'XOA');
      await tester.tap(find.text('Xóa dữ liệu'));
      await finishDelete(tester);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppConstants.disclaimerAcceptedVersionKey), isNull);
      expect(prefs.getString(AppConstants.disclaimerAcceptedAtKey), isNull);
      expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
    });
  });

  group('R1-07 skipped pregnancy setup', () {
    testWidgets('Cài đặt offers setup; skipping comes back', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'pregnancy',
      });
      await tester.pumpWidget(_app(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Thông tin thai kỳ'), findsOneWidget);
      final row = find.byKey(const ValueKey('settings-pregnancy-setup'));
      await tester.scrollUntilVisible(
        row,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byType(PregnancySetupScreen), findsOneWidget);
      expect(
        tester
            .widget<PregnancySetupScreen>(find.byType(PregnancySetupScreen))
            .fromModeSwitch,
        isTrue,
      );

      await tester.scrollUntilVisible(
        find.text('Bỏ qua lúc này'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Bỏ qua lúc này'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(MainNavigation), findsNothing);
    });

    testWidgets('pre-pregnancy mode has no such row', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'prePregnancy',
      });
      await tester.pumpWidget(_app(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Thông tin thai kỳ'), findsNothing);
      expect(
        find.byKey(const ValueKey('settings-pregnancy-setup')),
        findsNothing,
      );
    });
  });

  group('R1-08 Dự đoán countdown', () {
    final now = DateTime(2026, 10, 30, 22, 15);

    test('today, including later or earlier the same day', () {
      expect(DateFormatter.formatDayCountdown(now, now: now), 'Hôm nay');
      expect(
        DateFormatter.formatDayCountdown(DateTime(2026, 10, 30), now: now),
        'Hôm nay',
      );
      expect(
        DateFormatter.formatDayCountdown(
          DateTime(2026, 10, 30, 23, 59),
          now: now,
        ),
        'Hôm nay',
      );
    });

    test('future days count calendar days, not 24 h periods', () {
      expect(
        DateFormatter.formatDayCountdown(DateTime(2026, 10, 31), now: now),
        '1 ngày',
      );
      expect(
        DateFormatter.formatDayCountdown(DateTime(2026, 11, 4), now: now),
        '5 ngày',
      );
    });

    test('past days never show a minus sign', () {
      expect(
        DateFormatter.formatDayCountdown(DateTime(2026, 10, 29), now: now),
        'Đã qua 1 ngày',
      );
      expect(
        DateFormatter.formatDayCountdown(DateTime(2026, 10, 26), now: now),
        'Đã qua 4 ngày',
      );
    });

    testWidgets('both rows use it, also at font scale 1.5', (tester) async {
      _setPhone(tester);
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day - 20);
      final cycle = MenstrualCycleModel(
        id: 'c1',
        startDate: start,
        createdAt: start,
        updatedAt: start,
      );
      await Hive.box<MenstrualCycleModel>(
        AppConstants.menstrualCycleBox,
      ).put(cycle.id, cycle);

      await tester.pumpWidget(_app(const FertilityPlannerScreen()));
      await tester.pumpAndSettle();

      // Default 28-day cycle: next period in 8 days, ovulation 14 before it.
      expect(find.text('8 ngày nữa'), findsOneWidget);
      expect(find.text('Đã qua 6 ngày'), findsOneWidget);
      expect(find.text('-6 ngày'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
