// Phase 22.5: Hôm nay order, AppBar emergency shortcut and no overflow at
// 360 dp x1.5 (pregnancy and pre-pregnancy).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/data/daily_content_parser.dart';
import 'package:momcare/core/models/appointment_model.dart';
import 'package:momcare/core/models/daily_item_model.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/providers/app_mode_provider.dart';
import 'package:momcare/core/services/guide_progress_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/features/emergency/screens/emergency_warning_screen.dart';
import 'package:momcare/features/emergency/widgets/emergency_app_bar_button.dart';
import 'package:momcare/features/home/screens/home_screen.dart';
import 'package:momcare/features/home/screens/pre_pregnancy_home_screen.dart';
import 'package:momcare/features/home/widgets/quick_actions_grid.dart';
import 'package:momcare/l10n/app_localizations.dart';

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

/// Loads the bundled Be Vietnam Pro so text has real metrics (the default
/// test font is much wider than the app font).
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

void _setView(WidgetTester tester, {double width = 360, double height = 800}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _app(Widget home, {double textScale = 1.0, ProviderContainer? c}) {
  final app = MaterialApp(
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
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
  return c == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: c, child: app);
}

/// Asserts the widgets with [keys] are laid out top to bottom in order.
void _expectOrder(WidgetTester tester, List<String> keys) {
  double? previous;
  String? previousKey;
  for (final key in keys) {
    final finder = find.byKey(ValueKey(key));
    expect(finder, findsOneWidget, reason: key);
    final top = tester.getTopLeft(finder).dy;
    if (previous != null) {
      expect(top, greaterThan(previous), reason: '$key after $previousKey');
    }
    previous = top;
    previousKey = key;
  }
}

/// Scrolls the first scrollable to the end in steps, collecting layout
/// errors on the way.
Future<List<FlutterErrorDetails>> _scrollThrough(
  WidgetTester tester,
  Future<void> Function() pump,
) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await pump();
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pump();
    }
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

MenstrualCycleModel _cycle(DateTime start) {
  final stamp = DateTime(2026, 1, 1);
  return MenstrualCycleModel(
    id: 'c_${start.toIso8601String()}',
    startDate: start,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

void main() {
  late List<dynamic> guides;

  setUpAll(() async {
    await _loadAppFont();
    final bundle = _DirectoryAssetBundle('assets/content');
    guides = await ContentPackService.loadGuides(bundle);
    ContentPackService.debugThaiGiaoPack =
        await DailyContentParser.loadThaiGiao(bundle);
    ContentPackService.debugDailyTipsPack =
        await DailyContentParser.loadDailyTips(bundle);
    ContentPackService.debugWeekDetails =
        await ContentPackService.loadWeekDetails(bundle);
  });

  tearDownAll(() {
    ContentPackService.debugGuides = const [];
    ContentPackService.debugThaiGiaoPack = const DailyPack.empty(
      DailyPack.thaiGiaoType,
    );
    ContentPackService.debugDailyTipsPack = const DailyPack.empty(
      DailyPack.dailyTipType,
    );
    ContentPackService.debugWeekDetails = const {};
  });

  group('pregnancy Hôm nay', () {
    late Directory hiveDir;

    setUpAll(() async {
      hiveDir = await Directory.systemTemp.createTemp('momcare_home_layout');
      Hive.init(hiveDir.path);
      if (!Hive.isAdapterRegistered(PregnancyModelAdapter().typeId)) {
        Hive.registerAdapter(PregnancyModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AppointmentModelAdapter().typeId)) {
        Hive.registerAdapter(AppointmentModelAdapter());
      }
      final box = await Hive.openBox<PregnancyModel>(AppConstants.pregnancyBox);
      await Hive.openBox<AppointmentModel>(AppConstants.appointmentBox);
      final now = DateTime.now();
      // Day 122 = week 17 (next checkup milestone is shown).
      final start = DateTime(now.year, now.month, now.day - 121);
      final pregnancy = PregnancyModel(
        id: 'p',
        motherName: 'An',
        dueDate: PregnancyModel.dueDateFromLastPeriod(start),
        createdAt: now,
        updatedAt: now,
      );
      await box.put(pregnancy.id, pregnancy);
    });

    tearDownAll(() async {
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    Future<void> pumpHome(
      WidgetTester tester, {
      double textScale = 1.0,
      double height = 800,
    }) async {
      SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
      ContentPackService.debugGuides = guides.cast();
      _setView(tester, height: height);
      await tester.pumpWidget(_app(const HomeScreen(), textScale: textScale));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('cards follow the Phase 22.5 order', (tester) async {
      await pumpHome(tester);
      expect(tester.takeException(), isNull);
      _expectOrder(tester, const [
        'home-greeting',
        'home-day-card',
        'next-milestone-card',
        'home-appointments',
        'home-thai-giao',
        'home-tip',
        'home-week-todo',
        'home-habits',
        'home-quick-actions',
        'home-emergency-card',
        'home-clinic',
        'home-progress',
      ]);
      // Compact greeting with the name; time left moved into the day card.
      final greeting = tester.widget<Text>(
        find.byKey(const ValueKey('home-greeting')),
      );
      expect(greeting.data, endsWith(', An'));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-day-card')),
          matching: find.byKey(const ValueKey('pregnancy-day-remaining')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AppBar emergency button stays visible and opens the '
        'warning screen', (tester) async {
      await pumpHome(tester);
      final button = find.byKey(const ValueKey('home-emergency-button'));
      expect(
        find.descendant(of: find.byType(AppBar), matching: button),
        findsOneWidget,
      );
      expect(
        tester.widget<IconButton>(button).tooltip,
        EmergencyAppBarButton.tooltip,
      );

      // Still on screen after scrolling to the bottom.
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(button);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyWarningScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('emergency-call-115')), findsOneWidget);
    });

    testWidgets('no overflow at 360 dp with text scale 1.5', (tester) async {
      final errors = await _scrollThrough(
        tester,
        () => pumpHome(tester, textScale: 1.5),
      );
      expect(errors.map((e) => e.toString()).toList(), isEmpty);
    });
    // P22-R1-03: the empty upcoming-appointments state fills the card and
    // is centred in it, like the other AppEmptyState usages.
    testWidgets('empty upcoming appointments state is centred in its card', (
      tester,
    ) async {
      await pumpHome(tester);
      final empty = find.byKey(const ValueKey('home-upcoming-empty'));
      await tester.scrollUntilVisible(
        empty,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final card = tester.getRect(
        find.ancestor(of: empty, matching: find.byType(Card)).first,
      );
      final centerX = card.center.dx;
      for (final part in [
        find.descendant(
          of: empty,
          matching: find.byIcon(Icons.event_available),
        ),
        find.descendant(of: empty, matching: find.text('Chưa có lịch hẹn nào')),
        find.descendant(
          of: empty,
          matching: find.byWidgetPredicate((w) => w is TextButton),
        ),
      ]) {
        expect(part, findsOneWidget);
        expect(tester.getCenter(part).dx, closeTo(centerX, 1));
      }
      expect(tester.getSize(empty).width, greaterThan(card.width * 0.8));
    });
  });

  group('pre-pregnancy Hôm nay', () {
    const prefs = <String, Object>{AppConstants.appModeKey: 'prePregnancy'};

    Future<void> pumpPre(
      WidgetTester tester,
      List<MenstrualCycleModel> cycles,
      DateTime today, {
      double textScale = 1.0,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      ContentPackService.debugGuides = guides.cast();
      _setView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appModeProvider);
      container.read(guideChecklistProvider);
      await tester.pumpWidget(
        _app(
          PrePregnancyHomeScreen(debugCycles: cycles, debugToday: today),
          textScale: textScale,
          c: container,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    DateTime today() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }

    testWidgets('cards follow the Phase 22.5 order', (tester) async {
      await pumpPre(tester, [_cycle(today())], today());
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('pre-home-late-period')), findsNothing);
      _expectOrder(tester, const [
        'pre-home-greeting',
        'pre-fertile-window-card',
        'pre-ovulation-card',
        'pre-home-readiness',
        'pre-home-early-signs',
        'pre-home-tips',
        'pre-home-quick-actions',
        'pre-home-emergency',
        'pre-home-clinic',
        'pre-home-switch',
      ]);
    });

    testWidgets('late period card comes right after the greeting', (
      tester,
    ) async {
      final t = today();
      await pumpPre(tester, [_cycle(t.subtract(const Duration(days: 30)))], t);
      expect(tester.takeException(), isNull);
      _expectOrder(tester, const [
        'pre-home-greeting',
        'pre-home-late-period',
        'pre-home-readiness',
        'pre-home-early-signs',
        'pre-home-tips',
        'pre-home-quick-actions',
        'pre-home-emergency',
        'pre-home-clinic',
        'pre-home-switch',
      ]);
    });

    testWidgets('AppBar emergency button opens the warning screen', (
      tester,
    ) async {
      await pumpPre(tester, const [], today());
      final button = find.byKey(const ValueKey('home-emergency-button'));
      expect(
        find.descendant(of: find.byType(AppBar), matching: button),
        findsOneWidget,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyWarningScreen), findsOneWidget);
    });

    // P22-R1-05: pre-pregnancy quick actions reuse the pregnancy tile:
    // same label style, no forced line breaks, one line at 360 dp.
    testWidgets('quick actions use the shared tile with one-line labels', (
      tester,
    ) async {
      await pumpPre(tester, const [], today());
      final section = find.byKey(const ValueKey('pre-home-quick-actions'));
      await tester.scrollUntilVisible(
        section,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final tiles = find.descendant(
        of: section,
        matching: find.byType(QuickActionTile),
      );
      expect(tiles, findsNWidgets(2));
      final titleSmall = Theme.of(
        tester.element(section),
      ).textTheme.titleSmall!;
      for (final label in ['Theo dõi chu kỳ', 'Dinh dưỡng']) {
        final text = find.descendant(of: section, matching: find.text(label));
        expect(text, findsOneWidget, reason: label);
        expect(tester.widget<Text>(text).style, titleSmall);
        // One line: the label is no taller than a single line of its style.
        final lineHeight = (TextPainter(
          text: TextSpan(text: 'Ag', style: titleSmall),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(tester.element(text)),
        )..layout()).height;
        expect(tester.getSize(text).height, lessThan(lineHeight * 1.5));
      }
    });

    for (final withCycle in [true, false]) {
      testWidgets('no overflow at 360 dp with text scale 1.5 '
          '(cycles: $withCycle)', (tester) async {
        final t = today();
        final errors = await _scrollThrough(
          tester,
          () => pumpPre(
            tester,
            withCycle ? [_cycle(t)] : const [],
            t,
            textScale: 1.5,
          ),
        );
        expect(errors.map((e) => e.toString()).toList(), isEmpty);
      });
    }
  });
}
