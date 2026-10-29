// P22-R1-04: on screens with an extended FAB, the last content can scroll
// fully clear of the FAB (bottom padding AppSpacing.fabClearance).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/models/appointment_model.dart';
import 'package:momcare/core/models/health_log_model.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/features/appointments/screens/appointments_screen.dart';
import 'package:momcare/features/appointments/widgets/appointment_card.dart';
import 'package:momcare/features/fertility/screens/fertility_planner_screen.dart';
import 'package:momcare/features/fertility/widgets/cycle_marker.dart';
import 'package:momcare/features/health_diary/screens/health_diary_screen.dart';
import 'package:momcare/features/health_diary/widgets/health_log_list.dart';
import 'package:momcare/l10n/app_localizations.dart';

Widget _app(Widget home, {bool dark = false}) => ProviderScope(
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
    home: home,
  ),
);

void _setView(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(360 * 3, 640 * 3);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

/// Scrolls [scrollable] to its end and checks [last] ends above the FAB.
Future<void> _expectClearOfFab(
  WidgetTester tester,
  Finder scrollable,
  Finder last,
) async {
  // Jump straight to the maximum scroll (a drag could land on the calendar,
  // which handles vertical swipes itself).
  final position = tester
      .state<ScrollableState>(
        find
            .descendant(of: scrollable, matching: find.byType(Scrollable))
            .first,
      )
      .position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  final fab = tester.getRect(find.byType(FloatingActionButton));
  final item = tester.getRect(last);
  expect(
    item.bottom,
    lessThanOrEqualTo(fab.top),
    reason: 'last item ${item.bottom} should end above the FAB ${fab.top}',
  );
}

/// Loads the bundled Be Vietnam Pro so text has real metrics.
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

void main() {
  late Directory hiveDir;
  final now = DateTime.now();

  setUpAll(() async {
    await _loadAppFont();
    hiveDir = await Directory.systemTemp.createTemp('momcare_fab');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(HealthLogModelAdapter().typeId)) {
      Hive.registerAdapter(HealthLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AppointmentModelAdapter().typeId)) {
      Hive.registerAdapter(AppointmentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(MenstrualCycleModelAdapter().typeId)) {
      Hive.registerAdapter(MenstrualCycleModelAdapter());
    }
    final logs = await Hive.openBox<HealthLogModel>(AppConstants.healthLogBox);
    for (var i = 0; i < 3; i++) {
      final log = HealthLogModel(
        id: 'log$i',
        date: now.subtract(Duration(days: i)),
        weight: 55.0 + i,
        mood: 'calm',
        notes: 'Ghi chú $i',
        createdAt: now,
        updatedAt: now,
      );
      await logs.put(log.id, log);
    }
    final appointments = await Hive.openBox<AppointmentModel>(
      AppConstants.appointmentBox,
    );
    for (var i = 0; i < 4; i++) {
      final apt = AppointmentModel(
        id: 'a$i',
        title: 'Khám thai $i',
        // Two today (calendar tab), two in the coming days.
        dateTime: DateTime(
          now.year,
          now.month,
          now.day,
          23,
          50 - i,
        ).add(Duration(days: i < 2 ? 0 : i)),
        location: 'Bệnh viện',
        reminderEnabled: false,
        createdAt: now,
        updatedAt: now,
      );
      await appointments.put(apt.id, apt);
    }
    final cycles = await Hive.openBox<MenstrualCycleModel>(
      AppConstants.menstrualCycleBox,
    );
    final cycle = MenstrualCycleModel(
      id: 'c1',
      startDate: now.subtract(const Duration(days: 10)),
      createdAt: now,
      updatedAt: now,
    );
    await cycles.put(cycle.id, cycle);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('FAB clearance = FAB height + both FAB margins', () {
    expect(AppSpacing.fabClearance, 56 + 2 * kFloatingActionButtonMargin);
    expect(AppSpacing.fabPagePadding.bottom, AppSpacing.fabClearance);
  });

  for (final dark in [false, true]) {
    testWidgets('Chu kỳ: last card clears the FAB (dark: $dark)', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(_app(const FertilityPlannerScreen(), dark: dark));
      await tester.pumpAndSettle();
      final legendCard = find.ancestor(
        of: find.byType(CycleMarkerLegend),
        matching: find.byType(Card),
      );
      await _expectClearOfFab(
        tester,
        find.byKey(const ValueKey('cycle-planner-scroll')),
        legendCard.first,
      );
    });
  }

  testWidgets('Nhật ký sức khỏe: last entry clears the FAB', (tester) async {
    _setView(tester);
    await tester.pumpWidget(_app(const HealthDiaryScreen()));
    await tester.pumpAndSettle();
    await _expectClearOfFab(
      tester,
      find.byKey(const ValueKey('health-diary-logs-scroll')),
      find.byType(HealthLogList),
    );
  });

  testWidgets('Lịch hẹn: calendar and list tabs clear the FAB', (tester) async {
    _setView(tester);
    await tester.pumpWidget(_app(const AppointmentsScreen()));
    await tester.pumpAndSettle();
    // Calendar tab: the selected-day card (today, two appointments).
    final dayCard = find.ancestor(
      of: find.textContaining('Lịch hẹn ngày'),
      matching: find.byType(Card),
    );
    await _expectClearOfFab(
      tester,
      find.byType(SingleChildScrollView).first,
      dayCard.first,
    );

    await tester.tap(find.text('Danh sách'));
    await tester.pumpAndSettle();
    final scroll = find.descendant(
      of: find.byType(RefreshIndicator),
      matching: find.byType(SingleChildScrollView),
    );
    await _expectClearOfFab(
      tester,
      scroll,
      find.descendant(of: scroll, matching: find.byType(AppointmentCard)).last,
    );
  });
}
