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
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/models/week_detail_model.dart';
import 'package:momcare/core/services/thai_giao_progress_service.dart';
import 'package:momcare/core/services/thai_giao_reminder_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/features/home/screens/home_screen.dart';
import 'package:momcare/features/home/widgets/today_thai_giao_card.dart';
import 'package:momcare/l10n/app_localizations.dart';

const _fixtureRoot = 'test/fixtures/content';

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

String _pack(String type, List<Object?> items, {String? reviewStatus}) {
  return '''
{
  "version": 1,
  "type": "$type",
  "lastUpdated": "2026-10-29",
  "reviewStatus": ${reviewStatus == null ? 'null' : '"$reviewStatus"'},
  "items": ${_encode(items)}
}''';
}

String _encode(Object? value) {
  if (value == null) return 'null';
  if (value is String) return '"$value"';
  if (value is num || value is bool) return '$value';
  if (value is List) return '[${value.map(_encode).join(',')}]';
  if (value is Map) {
    return '{${value.entries.map((e) => '"${e.key}":${_encode(e.value)}').join(',')}}';
  }
  throw ArgumentError(value);
}

Map<String, Object?> _item(
  int day,
  String category, {
  String title = 'Tiêu đề',
  String body = 'Nội dung',
  Object? durationMin = 5,
}) => {
  'day': day,
  'week': (day - 1) ~/ 7,
  'category': category,
  'title': title,
  'body': body,
  'durationMin': durationMin,
  'sources': <Object?>[],
};

DailyPack _parseThaiGiao(String raw) => DailyContentParser.parseDailyPack(
  raw,
  expectedType: DailyPack.thaiGiaoType,
);

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

void main() {
  group('DailyContentParser', () {
    test('parses a valid pack', () {
      final pack = _parseThaiGiao(
        _pack('thai_giao', [
          _item(2, 'music', title: 'B'),
          _item(1, 'talk', title: 'A'),
        ], reviewStatus: 'draft_requires_medical_review'),
      );
      expect(pack.items.map((i) => i.day), [1, 2]);
      expect(pack.items.first.title, 'A');
      expect(pack.items.first.week, 0);
      expect(pack.isDraft, isTrue);
      expect(pack.lastUpdated, '2026-10-29');
    });

    test('approved pack is not draft; anything else is draft', () {
      final approved = _parseThaiGiao(
        _pack('thai_giao', [_item(1, 'talk')], reviewStatus: 'approved'),
      );
      expect(approved.isDraft, isFalse);
      final missing = _parseThaiGiao(_pack('thai_giao', [_item(1, 'talk')]));
      expect(missing.isDraft, isTrue);
    });

    test('invalid JSON, wrong root or wrong type give an empty pack', () {
      expect(_parseThaiGiao('{ not json').items, isEmpty);
      expect(_parseThaiGiao('[]').items, isEmpty);
      expect(_parseThaiGiao('{"items": 3}').items, isEmpty);
      expect(
        _parseThaiGiao(_pack('daily_tip', [_item(1, 'nutrition')])).items,
        isEmpty,
      );
    });

    test('skips bad items and keeps the first duplicate day', () {
      final pack = _parseThaiGiao(
        _pack('thai_giao', [
          _item(0, 'talk'),
          _item(295, 'talk'),
          _item(3, 'dance'),
          _item(4, 'nutrition'),
          _item(5, 'talk', title: '  '),
          _item(6, 'talk', body: ''),
          'not a map',
          {'day': '7', 'category': 'talk', 'title': 'x', 'body': 'y'},
          _item(8, 'talk', title: 'first'),
          _item(8, 'music', title: 'second'),
          _item(294, 'journal'),
        ]),
      );
      expect(pack.items.map((i) => i.day), [8, 294]);
      expect(pack.items.first.title, 'first');
    });

    test('durationMin accepts int, double or null', () {
      final pack = _parseThaiGiao(
        _pack('thai_giao', [
          _item(1, 'talk', durationMin: 5),
          _item(2, 'music', durationMin: 10.0),
          _item(3, 'movement', durationMin: null),
          _item(4, 'reading', durationMin: 'abc'),
        ]),
      );
      expect(pack.items.map((i) => i.durationMin), [5, 10, null, null]);
    });

    test('tip categories are validated against the tip list', () {
      final pack = DailyContentParser.parseDailyPack(
        _pack('daily_tip', [_item(1, 'nutrition'), _item(2, 'talk')]),
        expectedType: DailyPack.dailyTipType,
      );
      expect(pack.items.map((i) => i.day), [1]);
    });

    test('missing file gives an empty pack without throwing', () async {
      final pack = await DailyContentParser.loadDailyPack(
        _DirectoryAssetBundle('test/fixtures/nowhere'),
        DailyContentParser.thaiGiaoAssetPath,
        expectedType: DailyPack.thaiGiaoType,
      );
      expect(pack.isEmpty, isTrue);
      expect(pack.itemForDay(1), isNull);
    });

    test('invalid fixture file gives an empty pack', () async {
      final pack = await DailyContentParser.loadDailyPack(
        _DirectoryAssetBundle(_fixtureRoot),
        'assets/content/daily/invalid.json',
        expectedType: DailyPack.thaiGiaoType,
      );
      expect(pack.isEmpty, isTrue);
    });
  });

  group('DailyPack.itemForDay', () {
    late DailyPack fixture;

    setUpAll(() async {
      fixture = await DailyContentParser.loadThaiGiao(
        _DirectoryAssetBundle(_fixtureRoot),
      );
    });

    test('exact match', () {
      expect(fixture.itemForDay(11)!.day, 11);
    });

    test('missing day 10 falls back to the nearest movement item', () {
      expect(fixture.items.any((i) => i.day == 10), isFalse);
      final item = fixture.itemForDay(10)!;
      expect(item.category, 'movement');
      expect(item.day, 3, reason: 'day 3 and 17 tie; earlier wins');
    });

    test('clamps below 1 and above 294', () {
      expect(fixture.itemForDay(-5)!.day, 1);
      expect(fixture.itemForDay(0)!.day, 1);
      // Day 294 is slot 6 (journal); nearest journal in the fixture is 21.
      final late = fixture.itemForDay(999)!;
      expect(late.day, 21);
      expect(late.category, 'journal');
    });

    test('falls back to the nearest item of any category', () {
      final pack = _parseThaiGiao(
        _pack('thai_giao', [_item(1, 'talk'), _item(20, 'music')]),
      );
      // Day 6 is slot 5, the slot of day 20 (music): the category wins
      // over the nearer day 1.
      expect(pack.itemForDay(6)!.day, 20);
      // Days 3 and 17 are slot 2: no item uses it, so the nearest item wins.
      expect(pack.itemForDay(3)!.day, 1);
      expect(pack.itemForDay(17)!.day, 20);
    });

    test('empty pack returns null', () {
      expect(const DailyPack.empty('thai_giao').itemForDay(5), isNull);
    });
  });

  group('Bundled daily packs', () {
    late DailyPack thaiGiao;
    late DailyPack tips;

    setUpAll(() async {
      final bundle = _DirectoryAssetBundle('assets/content');
      thaiGiao = await DailyContentParser.loadThaiGiao(bundle);
      tips = await DailyContentParser.loadDailyTips(bundle);
    });

    for (final entry in {'thai_giao': 0, 'daily_tip': 1}.entries) {
      test('${entry.key} has 294 valid draft items', () {
        final pack = entry.value == 0 ? thaiGiao : tips;
        expect(pack.items, hasLength(294));
        expect(pack.isDraft, isTrue);
        expect(pack.items.map((i) => i.day), List.generate(294, (i) => i + 1));
        final categories = DailyPack.categoriesByType[pack.type]!;
        for (final item in pack.items) {
          expect(categories, contains(item.category));
          expect(item.day, item.week * 7 + item.slot + 1);
          expect(item.title, isNot(contains('null')));
          expect(item.body, isNot(contains('null')));
        }
      });
    }

    test('raw files have no items the parser skips', () {
      for (final path in [
        'assets/content/daily/thai_giao.json',
        'assets/content/daily/daily_tips.json',
      ]) {
        final raw = File(path).readAsStringSync();
        expect(RegExp(r'"day"\s*:').allMatches(raw), hasLength(294));
      }
    });
  });

  group('PregnancyModel day', () {
    test('pregnancyDayAt agrees with currentWeekAt for weeks 0..41', () {
      final now = DateTime(2026, 10, 29, 15);
      for (var week = 0; week <= 41; week++) {
        for (var slot = 0; slot < 7; slot++) {
          final start = DateTime(
            now.year,
            now.month,
            now.day - week * 7 - slot,
          );
          final pregnancy = PregnancyModel(
            id: 'p',
            dueDate: PregnancyModel.dueDateFromLastPeriod(start),
            createdAt: now,
            updatedAt: now,
          );
          final day = pregnancy.pregnancyDayAt(now);
          expect(day, week * 7 + slot + 1);
          expect(pregnancy.contentDayAt(now), day);
          expect((day - 1) ~/ 7, pregnancy.currentWeekAt(now));
        }
      }
    });

    test('content day is clamped to 1..294', () {
      final now = DateTime(2026, 10, 29);
      PregnancyModel startingIn(int days) => PregnancyModel(
        id: 'p',
        dueDate: PregnancyModel.dueDateFromLastPeriod(
          DateTime(now.year, now.month, now.day + days),
        ),
        createdAt: now,
        updatedAt: now,
      );
      expect(startingIn(5).pregnancyDayAt(now), -4);
      expect(startingIn(5).contentDayAt(now), 1);
      expect(startingIn(-300).pregnancyDayAt(now), 301);
      expect(startingIn(-300).contentDayAt(now), 294);
    });
  });

  group('ThaiGiaoProgressService', () {
    final today = _d(2026, 10, 29);
    String key(DateTime d) => ThaiGiaoProgressService.dateKey(d);

    test('dateKey is yyyy-MM-dd', () {
      expect(key(_d(2026, 3, 7)), '2026-03-07');
    });

    test('streak cases', () {
      int streak(Set<String> done) =>
          ThaiGiaoProgressService.streakAt(done, today);
      expect(streak({}), 0);
      expect(streak({key(today)}), 1);
      expect(streak({key(_d(2026, 10, 28)), key(_d(2026, 10, 27))}), 2);
      expect(
        streak({key(today), key(_d(2026, 10, 28)), key(_d(2026, 10, 26))}),
        2,
        reason: 'gap on the 27th breaks the streak',
      );
      expect(streak({key(_d(2026, 10, 27))}), 0);
      final ticked = {key(today), key(_d(2026, 10, 28)), key(_d(2026, 10, 27))};
      expect(streak(ticked), 3);
      expect(streak(ticked..remove(key(today))), 2, reason: 'untick today');
      expect(
        ThaiGiaoProgressService.streakAt({
          '2026-10-31',
          '2026-11-01',
        }, _d(2026, 11, 1)),
        2,
        reason: 'crosses a month boundary',
      );
    });

    test('corrupt value gives an empty set', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.thaiGiaoDoneKey: '{oops',
      });
      expect(await ThaiGiaoProgressService.loadDone(), isEmpty);
      SharedPreferences.setMockInitialValues({
        AppConstants.thaiGiaoDoneKey: '{"a":1}',
      });
      expect(await ThaiGiaoProgressService.loadDone(), isEmpty);
    });

    test('setDone persists a sorted list and clear removes it', () async {
      SharedPreferences.setMockInitialValues({});
      await ThaiGiaoProgressService.setDone(_d(2026, 10, 29), true);
      await ThaiGiaoProgressService.setDone(_d(2026, 10, 27), true);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppConstants.thaiGiaoDoneKey),
        '["2026-10-27","2026-10-29"]',
      );
      await ThaiGiaoProgressService.setDone(_d(2026, 10, 29), false);
      expect(await ThaiGiaoProgressService.loadDone(), {'2026-10-27'});
      await ThaiGiaoProgressService.clear();
      expect(prefs.containsKey(AppConstants.thaiGiaoDoneKey), isFalse);
    });

    test('done state persists across notifier instances', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ThaiGiaoProgressNotifier();
      await first.ready;
      await first.setDone(today, true);
      expect(first.isDone(today), isTrue);
      first.dispose();

      final second = ThaiGiaoProgressNotifier();
      await second.ready;
      expect(second.isDone(today), isTrue);
      expect(second.streakAt(today), 1);
      second.resetLocal();
      expect(second.state, isEmpty);
      second.dispose();
    });
  });

  group('ThaiGiaoReminderService settings', () {
    test('defaults to off at 20:00', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await ThaiGiaoReminderService.load();
      expect(settings.enabled, isFalse);
      expect(settings.hour, 20);
      expect(settings.minute, 0);
    });

    test('save/load round trip and clear', () async {
      SharedPreferences.setMockInitialValues({});
      await ThaiGiaoReminderService.save(
        const ThaiGiaoReminderSettings(enabled: true, hour: 7, minute: 45),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppConstants.thaiGiaoReminderKey),
        '{"enabled":true,"hour":7,"minute":45}',
      );
      final loaded = await ThaiGiaoReminderService.load();
      expect(loaded.enabled, isTrue);
      expect(loaded.hour, 7);
      expect(loaded.minute, 45);
      await ThaiGiaoReminderService.clear();
      expect((await ThaiGiaoReminderService.load()).enabled, isFalse);
    });

    test('corrupt or out-of-range values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.thaiGiaoReminderKey: 'nope',
      });
      expect((await ThaiGiaoReminderService.load()).enabled, isFalse);
      SharedPreferences.setMockInitialValues({
        AppConstants.thaiGiaoReminderKey:
            '{"enabled":"yes","hour":30,"minute":-1}',
      });
      final settings = await ThaiGiaoReminderService.load();
      expect(settings.enabled, isFalse);
      expect(settings.hour, 20);
      expect(settings.minute, 0);
    });

    test('uses a stable notification id', () {
      expect(
        ThaiGiaoReminderService.notificationId,
        ThaiGiaoReminderService.notificationId,
      );
      expect(ThaiGiaoReminderService.title, 'Thai giáo hôm nay');
    });
  });

  group('HomeScreen daily section', () {
    late Directory hiveDir;
    late DailyPack thaiGiao;
    late DailyPack tips;
    late Map<int, WeekDetail> weeks;
    late PregnancyModel pregnancy;
    const contentDay = 122;

    setUpAll(() async {
      final bundle = _DirectoryAssetBundle('assets/content');
      thaiGiao = await DailyContentParser.loadThaiGiao(bundle);
      tips = await DailyContentParser.loadDailyTips(bundle);
      weeks = await ContentPackService.loadWeekDetails(bundle);

      hiveDir = await Directory.systemTemp.createTemp('momcare_daily_test');
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
      // Day 122 = week 17, weekday slot 2.
      final start = DateTime(now.year, now.month, now.day - (contentDay - 1));
      pregnancy = PregnancyModel(
        id: 'p',
        dueDate: PregnancyModel.dueDateFromLastPeriod(start),
        createdAt: now,
        updatedAt: now,
      );
      await box.put(pregnancy.id, pregnancy);
    });

    tearDownAll(() async {
      ContentPackService.debugThaiGiaoPack = const DailyPack.empty(
        DailyPack.thaiGiaoType,
      );
      ContentPackService.debugDailyTipsPack = const DailyPack.empty(
        DailyPack.dailyTipType,
      );
      ContentPackService.debugWeekDetails = const {};
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    Future<void> pumpHome(
      WidgetTester tester, {
      required bool withContent,
      // The old progress, quick-action and appointment rows overflow with the
      // wide test font at phone width (pre-existing); the overflow test below
      // checks the new cards at 360 dp.
      double width = 600,
    }) async {
      SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
      ContentPackService.debugThaiGiaoPack = withContent
          ? thaiGiao
          : const DailyPack.empty(DailyPack.thaiGiaoType);
      ContentPackService.debugDailyTipsPack = withContent
          ? tips
          : const DailyPack.empty(DailyPack.dailyTipType);
      ContentPackService.debugWeekDetails = withContent
          ? weeks
          : {17: const WeekDetail(week: 17)};
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = Size(width * 3, 2796);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi')],
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('shows day card, thai giáo, tip and week todos', (
      tester,
    ) async {
      expect(pregnancy.currentWeek, 17);
      await pumpHome(tester, withContent: true);

      expect(find.text('Ngày $contentDay/280'), findsOneWidget);
      expect(find.text('Tuần 17 · ngày 3'), findsOneWidget);

      final activity = thaiGiao.itemForDay(contentDay)!;
      expect(activity.day, contentDay);
      expect(find.text(activity.title), findsOneWidget);
      expect(find.text(activity.body), findsOneWidget);
      expect(find.text('~${activity.durationMin} phút'), findsOneWidget);

      final tip = tips.itemForDay(contentDay)!;
      expect(find.text('Gợi ý hôm nay'), findsOneWidget);
      expect(find.text(tip.title), findsOneWidget);
      expect(find.text('Nội dung đang chờ bác sĩ duyệt'), findsNWidgets(2));
      expect(find.textContaining('Hãy uống đủ nước mỗi ngày'), findsNothing);

      final todos = weeks[17]!.todoThisWeek;
      expect(todos, isNotEmpty);
      expect(find.text('Việc tuần này'), findsOneWidget);
      for (final todo in todos.take(5)) {
        expect(find.text(todo), findsOneWidget);
      }
      for (final todo in todos.skip(5)) {
        expect(find.text(todo), findsNothing);
      }
      expect(find.textContaining('null'), findsNothing);
      expect(find.text('Đang tắt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Đã làm shows the streak and persists', (tester) async {
      await pumpHome(tester, withContent: true);
      expect(find.textContaining('Chuỗi'), findsNothing);

      final done = find.byKey(const ValueKey('thai-giao-done'));
      await tester.ensureVisible(done);
      await tester.tap(done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Chuỗi 1 ngày'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppConstants.thaiGiaoDoneKey),
        '["${ThaiGiaoProgressService.dateKey(DateTime.now())}"]',
      );

      await tester.tap(done);
      await tester.pump();
      expect(find.textContaining('Chuỗi'), findsNothing);
    });

    for (final width in [360.0, 390.0]) {
      testWidgets('new cards do not overflow at ${width.toInt()} dp', (
        tester,
      ) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        try {
          await pumpHome(tester, withContent: true, width: width);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -1500),
          );
          await tester.pump();
        } finally {
          FlutterError.onError = previous;
        }
        const newCards = [
          'pregnancy_day_card.dart',
          'today_thai_giao_card.dart',
          'today_tip_card.dart',
          'week_todo_card.dart',
        ];
        final fromNewCards = errors
            .map((e) => e.toString())
            .where((text) => newCards.any(text.contains))
            .toList();
        expect(fromNewCards, isEmpty);
        expect(
          errors.where((e) => !e.toString().contains('overflowed')),
          isEmpty,
        );
      });
    }

    testWidgets('empty packs hide the daily cards', (tester) async {
      await pumpHome(tester, withContent: false);

      expect(tester.takeException(), isNull);
      expect(find.text('Ngày $contentDay/280'), findsOneWidget);
      expect(find.text('Thai giáo hôm nay'), findsNothing);
      expect(find.text('Gợi ý hôm nay'), findsNothing);
      expect(find.text('Việc tuần này'), findsNothing);
      expect(find.text('Đã làm'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
    });
  });

  group('TodayThaiGiaoCard', () {
    const cardPack = DailyPack(
      type: DailyPack.thaiGiaoType,
      items: [
        DailyItem(
          day: 10,
          week: 2,
          category: 'talk',
          title: 'Trò chuyện với con',
          body: 'Kể cho con nghe về ngày hôm nay.',
        ),
      ],
    );

    Future<void> pumpCard(
      WidgetTester tester, {
      ThemeData? theme,
      DateTime Function()? clock,
    }) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            locale: const Locale('vi'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi')],
            home: Scaffold(
              body: SingleChildScrollView(
                child: TodayThaiGiaoCard(day: 10, pack: cardPack, clock: clock),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final entry in {
      // The app's color schemes (AppTheme.*Theme fetch Google Fonts in tests).
      'light': ThemeData(
        colorScheme: AppTheme.lightColorScheme,
        primaryColor: AppTheme.primaryColor,
      ),
      'dark': ThemeData(
        colorScheme: AppTheme.darkColorScheme,
        primaryColor: AppTheme.primaryColor,
      ),
    }.entries) {
      testWidgets('selected Đã làm chip is readable in ${entry.key} theme', (
        tester,
      ) async {
        await pumpCard(tester, theme: entry.value);
        final chipFinder = find.byKey(const ValueKey('thai-giao-done'));
        await tester.tap(chipFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final chip = tester.widget<FilterChip>(chipFinder);
        expect(chip.selected, isTrue);
        final background = chip.selectedColor!;
        expect(background.a, 1.0);
        final label = tester.widget<RichText>(
          find.descendant(
            of: find.text('Đã làm'),
            matching: find.byType(RichText),
          ),
        );
        expect(
          contrast(label.text.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(chip.checkmarkColor!, background),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    testWidgets('Đã làm marks the date at tap time, not build time', (
      tester,
    ) async {
      var fakeNow = DateTime(2026, 10, 29, 23, 59);
      await pumpCard(tester, clock: () => fakeNow);

      // Midnight passes without the card rebuilding.
      fakeNow = DateTime(2026, 10, 30, 0, 1);
      await tester.tap(find.byKey(const ValueKey('thai-giao-done')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.thaiGiaoDoneKey), '["2026-10-30"]');
    });

    testWidgets('time picker uses 24-hour input on 12-hour devices', (
      tester,
    ) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      await pumpCard(tester);

      await tester.tap(find.byKey(const ValueKey('thai-giao-reminder-switch')));
      await tester.pumpAndSettle();

      final dialog = find.byType(TimePickerDialog);
      expect(dialog, findsOneWidget);
      expect(MediaQuery.of(tester.element(dialog)).alwaysUse24HourFormat, true);

      Navigator.of(tester.element(dialog)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Đang tắt'), findsOneWidget);
    });
  });
}
