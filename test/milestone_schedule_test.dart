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
import 'package:momcare/core/models/appointment_model.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/models/milestone_schedule.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/services/milestone_progress_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/date_formatter.dart';
import 'package:momcare/features/guides/guide_actions.dart';
import 'package:momcare/features/guides/screens/guide_detail_screen.dart';
import 'package:momcare/features/guides/widgets/milestone_status_chip.dart';
import 'package:momcare/features/home/screens/home_screen.dart';
import 'package:momcare/features/home/widgets/next_milestone_card.dart';
import 'package:momcare/l10n/app_localizations.dart';

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

PregnancyModel _pregnancyFromStart(DateTime start) {
  final now = DateTime(2026, 1, 1);
  return PregnancyModel(
    id: 'p',
    dueDate: PregnancyModel.dueDateFromLastPeriod(start),
    createdAt: now,
    updatedAt: now,
  );
}

/// Pregnancy whose current week (today) is [week], day [weekDay] of it.
PregnancyModel _pregnancyAtWeek(int week, {int weekDay = 2}) {
  final now = DateTime.now();
  final daysSinceStart = week * 7 + weekDay;
  final start = DateTime(now.year, now.month, now.day - daysSinceStart);
  return PregnancyModel(
    id: 'p',
    dueDate: PregnancyModel.dueDateFromLastPeriod(start),
    createdAt: now,
    updatedAt: now,
  );
}

GuideArticle _guide({
  GuideCategory category = GuideCategory.checkup,
  required List<GuideTimelineItem> timeline,
}) => GuideArticle(
  id: 'g',
  stage: GuideStage.pregnant,
  category: category,
  title: 'Guide',
  timeline: timeline,
);

GuideTimelineItem _item(
  String id,
  int? from,
  int? to, {
  GuideActionType action = GuideActionType.addAppointment,
}) => GuideTimelineItem(
  id: id,
  title: 'Item $id',
  weekFrom: from,
  weekTo: to,
  actionType: action,
);

DateTime _day(DateTime d, int offset) =>
    DateTime(d.year, d.month, d.day + offset);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lmp = DateTime(2026, 1, 1);
  final pregnancy = _pregnancyFromStart(lmp);

  group('MilestoneSchedule', () {
    final guide = _guide(timeline: [_item('a', 10, 12)]);
    final start = _day(lmp, 70);
    final end = _day(lmp, 13 * 7 - 1);

    MilestoneStatus statusAt(DateTime now, {Map<String, DateTime>? done}) =>
        MilestoneSchedule.build(
          guide: guide,
          pregnancy: pregnancy,
          now: now,
          done: done ?? const {},
        ).items.single.status;

    test('dates use raw week offsets from the pregnancy start', () {
      final m = MilestoneSchedule.build(
        guide: guide,
        pregnancy: pregnancy,
        now: lmp,
      ).items.single;
      expect(m.startDate, start);
      expect(m.endDate, end);
      expect(m.daysUntilStart, 70);
    });

    test('status boundaries', () {
      expect(statusAt(_day(start, -1)), MilestoneStatus.upcoming);
      expect(statusAt(start), MilestoneStatus.dueNow);
      expect(
        statusAt(end.add(const Duration(hours: 23))),
        MilestoneStatus.dueNow,
      );
      expect(statusAt(_day(end, 1)), MilestoneStatus.past);
    });

    test('upcoming counts days until start', () {
      final m = MilestoneSchedule.build(
        guide: guide,
        pregnancy: pregnancy,
        now: _day(start, -1),
      ).items.single;
      expect(m.daysUntilStart, 1);
      expect(MilestoneLabels.status(m), 'Sắp tới · còn 1 ngày');
    });

    test('done overrides every status', () {
      final done = {'a': DateTime(2026, 3, 1)};
      for (final now in [_day(start, -5), start, end, _day(end, 9)]) {
        expect(statusAt(now, done: done), MilestoneStatus.done);
      }
      final m = MilestoneSchedule.build(
        guide: guide,
        pregnancy: pregnancy,
        now: start,
        done: done,
      ).items.single;
      expect(m.doneDate, DateTime(2026, 3, 1));
      expect(m.canAddAppointment, isFalse);
      expect(MilestoneLabels.status(m), 'Đã khám 01/03/2026');
    });

    test('a single-week item spans 7 days', () {
      final m = MilestoneSchedule.build(
        guide: _guide(timeline: [_item('w36', 36, 36)]),
        pregnancy: pregnancy,
        now: lmp,
      ).items.single;
      expect(m.endDate.difference(m.startDate).inDays, 6);
      expect(m.startDate, _day(lmp, 252));
    });

    test('items without a week are skipped; sorted by start then end', () {
      final schedule = MilestoneSchedule.build(
        guide: _guide(
          timeline: [
            _item('late', 20, 22),
            _item('none', null, null),
            _item('wide', 10, 30),
            _item('narrow', 10, 11),
            _item('onlyTo', null, 5),
          ],
        ),
        pregnancy: pregnancy,
        now: lmp,
      );
      expect(schedule.items.map((m) => m.id), [
        'onlyTo',
        'narrow',
        'wide',
        'late',
      ]);
    });

    test('next() prefers dueNow (earliest end) over upcoming', () {
      final g = _guide(
        timeline: [
          _item('past', 1, 2),
          _item('wide', 10, 30),
          _item('narrow', 11, 12),
          _item('later', 14, 15),
        ],
      );
      final now = _day(lmp, 11 * 7);
      final schedule = MilestoneSchedule.build(
        guide: g,
        pregnancy: pregnancy,
        now: now,
      );
      expect(schedule.next()!.id, 'narrow');

      final doneNarrow = MilestoneSchedule.build(
        guide: g,
        pregnancy: pregnancy,
        now: now,
        done: {'narrow': now},
      );
      expect(doneNarrow.next()!.id, 'wide');

      final doneDue = MilestoneSchedule.build(
        guide: g,
        pregnancy: pregnancy,
        now: now,
        done: {'narrow': now, 'wide': now},
      );
      expect(doneDue.next()!.id, 'later');
    });

    test('next() is null when everything is past or done', () {
      final g = _guide(timeline: [_item('a', 1, 2), _item('b', 3, 4)]);
      final now = _day(lmp, 10 * 7);
      expect(
        MilestoneSchedule.build(
          guide: g,
          pregnancy: pregnancy,
          now: now,
        ).next(),
        isNull,
      );
      expect(
        MilestoneSchedule.build(
          guide: g,
          pregnancy: pregnancy,
          now: _day(lmp, 7),
          done: {'a': lmp, 'b': lmp},
        ).next(),
        isNull,
      );
    });

    test('changing the due date shifts all dates', () {
      final shifted = PregnancyModel(
        id: 'p2',
        dueDate: _day(pregnancy.dueDate, 10),
        createdAt: lmp,
        updatedAt: lmp,
      );
      final g = _guide(timeline: [_item('a', 10, 12), _item('b', 30, 32)]);
      final before = MilestoneSchedule.build(
        guide: g,
        pregnancy: pregnancy,
        now: lmp,
      );
      final after = MilestoneSchedule.build(
        guide: g,
        pregnancy: shifted,
        now: lmp,
      );
      for (var i = 0; i < 2; i++) {
        expect(after.items[i].startDate, _day(before.items[i].startDate, 10));
        expect(after.items[i].endDate, _day(before.items[i].endDate, 10));
      }
    });

    test('canAddAppointment only for open addAppointment items', () {
      final g = _guide(
        timeline: [
          _item('past', 1, 2),
          _item('due', 10, 12),
          _item('up', 20, 22),
          _item('none', 20, 22, action: GuideActionType.none),
        ],
      );
      final schedule = MilestoneSchedule.build(
        guide: g,
        pregnancy: pregnancy,
        now: _day(lmp, 75),
      );
      expect(schedule.byId('past')!.canAddAppointment, isFalse);
      expect(schedule.byId('due')!.canAddAppointment, isTrue);
      expect(schedule.byId('up')!.canAddAppointment, isTrue);
      expect(schedule.byId('none')!.canAddAppointment, isFalse);
    });
  });

  group('MilestoneProgressService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('mark / unmark round-trip', () async {
      await MilestoneProgressService.setDone('a', DateTime(2026, 5, 6, 13));
      expect(await MilestoneProgressService.loadDone(), {
        'a': DateTime(2026, 5, 6),
      });
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppConstants.milestoneDoneKey),
        '{"a":"2026-05-06"}',
      );
      await MilestoneProgressService.clearDone('a');
      expect(await MilestoneProgressService.loadDone(), isEmpty);
    });

    test('state persists across a new notifier instance', () async {
      final first = MilestoneProgressNotifier();
      await first.ready;
      await first.markDone('tl_chk_triple', DateTime(2026, 4, 1));
      await first.markDone('tl_vax_flu', DateTime(2026, 4, 2));
      await first.unmark('tl_vax_flu');
      first.dispose();

      final second = MilestoneProgressNotifier();
      await second.ready;
      expect(second.state, {'tl_chk_triple': DateTime(2026, 4, 1)});
      second.resetLocal();
      expect(second.state, isEmpty);
      second.dispose();
    });

    test('corrupt JSON and invalid dates are ignored', () async {
      for (final raw in ['{not json', '[1,2]', '"x"', 'null']) {
        SharedPreferences.setMockInitialValues({
          AppConstants.milestoneDoneKey: raw,
        });
        expect(await MilestoneProgressService.loadDone(), isEmpty);
      }
      SharedPreferences.setMockInitialValues({
        AppConstants.milestoneDoneKey:
            '{"ok":"2026-02-28","bad":"2026-02-31","word":"hôm qua",'
            '"num":5,"iso":"2026-02-01T10:00:00"}',
      });
      expect(await MilestoneProgressService.loadDone(), {
        'ok': DateTime(2026, 2, 28),
      });
      final notifier = MilestoneProgressNotifier();
      await notifier.ready;
      expect(notifier.state.keys, ['ok']);
      notifier.dispose();
    });

    test('clear() and the delete-all flow remove the key', () async {
      await MilestoneProgressService.setDone('a', DateTime(2026, 5, 6));
      await MilestoneProgressService.clear();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AppConstants.milestoneDoneKey), isFalse);

      // SettingsScreen._deleteAllDataAndRestart removes this key.
      final settings = File(
        'lib/features/settings/screens/settings_screen.dart',
      ).readAsStringSync();
      expect(settings, contains('prefs.remove(AppConstants.milestoneDoneKey)'));
      expect(
        settings,
        contains('milestoneProgressProvider.notifier).resetLocal()'),
      );
    });
  });

  group('bundled guides', () {
    late List<GuideArticle> guides;

    setUpAll(() async {
      guides = await ContentPackService.loadGuides(
        _DirectoryAssetBundle('assets/content'),
      );
    });

    GuideArticle byId(String id) => guides.firstWhere((g) => g.id == id);

    test('checkups -> 13 milestones, vaccination -> 4', () {
      final now = DateTime.now();
      final checkups = MilestoneSchedule.build(
        guide: byId('pregnant_checkups'),
        pregnancy: _pregnancyAtWeek(17),
        now: now,
      );
      final vaccination = MilestoneSchedule.build(
        guide: byId('pregnant_vaccination'),
        pregnancy: _pregnancyAtWeek(17),
        now: now,
      );
      expect(checkups.items, hasLength(13));
      expect(checkups.items.every((m) => !m.isVaccination), isTrue);
      expect(vaccination.items, hasLength(4));
      expect(vaccination.items.every((m) => m.isVaccination), isTrue);
      expect(byId('pregnant_vaccination').checklist, hasLength(2));
      expect(
        vaccination.byId('tl_vax_rsv')!.item.actionType,
        GuideActionType.none,
      );

      final allIds = [
        for (final g in guides) ...g.timeline.map((t) => t.id),
        for (final g in guides) ...g.checklist.map((c) => c.id),
      ];
      expect(allIds.toSet().length, allIds.length);
    });

    test('prefill date is never before today for items that are not past', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final week in [0, 6, 17, 27, 33, 40]) {
        final p = _pregnancyAtWeek(week);
        for (final id in ['pregnant_checkups', 'pregnant_vaccination']) {
          final schedule = MilestoneSchedule.build(
            guide: byId(id),
            pregnancy: p,
            now: now,
          );
          for (final m in schedule.items) {
            if (m.status == MilestoneStatus.past) continue;
            final prefill = GuideActions.estimatedDateForWeek(
              p,
              m.item.weekFrom,
              now: now,
            )!;
            expect(prefill.isBefore(today), isFalse, reason: m.id);
            if (m.status == MilestoneStatus.upcoming) {
              expect(prefill, m.startDate, reason: m.id);
            }
          }
        }
      }
    });
  });

  group('timeline and Hôm nay card UI', () {
    late Directory hiveDir;
    late Box<PregnancyModel> box;
    late List<GuideArticle> guides;

    setUpAll(() async {
      guides = await ContentPackService.loadGuides(
        _DirectoryAssetBundle('assets/content'),
      );
      hiveDir = await Directory.systemTemp.createTemp('momcare_milestone');
      Hive.init(hiveDir.path);
      if (!Hive.isAdapterRegistered(PregnancyModelAdapter().typeId)) {
        Hive.registerAdapter(PregnancyModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AppointmentModelAdapter().typeId)) {
        Hive.registerAdapter(AppointmentModelAdapter());
      }
      box = await Hive.openBox<PregnancyModel>(AppConstants.pregnancyBox);
      await Hive.openBox<AppointmentModel>(AppConstants.appointmentBox);
    });

    tearDownAll(() async {
      ContentPackService.debugGuides = const [];
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    GuideArticle byId(String id) => guides.firstWhere((g) => g.id == id);

    Future<PregnancyModel?> setPregnancy(int? week) async {
      await box.clear();
      if (week == null) return null;
      final p = _pregnancyAtWeek(week);
      await box.put(p.id, p);
      return p;
    }

    void setView(WidgetTester tester, double width) {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = Size(width * 3, 2796);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
    }

    Future<void> pumpDetail(
      WidgetTester tester,
      GuideArticle guide, {
      ThemeData? theme,
    }) async {
      setView(tester, 430);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: GuideDetailScreen(guide: guide, sources: const {}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Finder tile(String id) => find.byKey(ValueKey('milestone-$id'));

    Finder inTile(String id, Finder finder) =>
        find.descendant(of: tile(id), matching: finder);

    Future<void> scrollTo(
      WidgetTester tester,
      String id, {
      bool up = false,
    }) async {
      if (tile(id).evaluate().isNotEmpty) {
        await tester.ensureVisible(tile(id));
      } else {
        await tester.scrollUntilVisible(
          tile(id),
          up ? -200 : 200,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.pump();
    }

    testWidgets('week 17 checkups: statuses, buttons and done flow', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => setPregnancy(17));
      await pumpDetail(tester, byId('pregnant_checkups'));

      await scrollTo(tester, 'tl_chk_first_visit');
      expect(inTile('tl_chk_first_visit', find.text('Đã qua')), findsOneWidget);
      expect(
        inTile('tl_chk_first_visit', find.text('Thêm vào lịch hẹn')),
        findsNothing,
      );

      await scrollTo(tester, 'tl_chk_triple');
      expect(inTile('tl_chk_triple', find.text('Đến lúc rồi')), findsOneWidget);
      expect(
        inTile('tl_chk_triple', find.text('Thêm vào lịch hẹn')),
        findsOneWidget,
      );

      await scrollTo(tester, 'tl_chk_anomaly');
      expect(
        inTile('tl_chk_anomaly', find.textContaining('Sắp tới · còn')),
        findsOneWidget,
      );
      expect(
        inTile('tl_chk_anomaly', find.text('Thêm vào lịch hẹn')),
        findsOneWidget,
      );

      // Mark 6-8 done with today's date.
      await scrollTo(tester, 'tl_chk_first_visit', up: true);
      await tester.tap(
        find.byKey(const ValueKey('milestone-done-tl_chk_first_visit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final todayLabel = DateFormatter.formatDate(DateTime.now());
      expect(
        inTile('tl_chk_first_visit', find.text('Đã khám $todayLabel')),
        findsOneWidget,
      );
      expect(
        inTile('tl_chk_first_visit', find.text('Bỏ đánh dấu')),
        findsOneWidget,
      );

      // Survives a rebuild (new provider scope reloads from prefs).
      await tester.pumpWidget(const SizedBox());
      await pumpDetail(tester, byId('pregnant_checkups'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      await scrollTo(tester, 'tl_chk_first_visit');
      expect(
        inTile('tl_chk_first_visit', find.text('Đã khám $todayLabel')),
        findsOneWidget,
      );

      await tester.tap(find.text('Bỏ đánh dấu'));
      await tester.pump();
      expect(inTile('tl_chk_first_visit', find.text('Đã qua')), findsOneWidget);
    });

    testWidgets('vaccination items show doctor label; RSV has no add', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => setPregnancy(17));
      await pumpDetail(tester, byId('pregnant_vaccination'));

      const expectedStatus = {
        'tl_vax_flu': 'Đến lúc rồi',
        'tl_vax_tetanus': 'Đến lúc rồi',
        'tl_vax_tdap': 'Sắp tới',
      };
      for (final id in expectedStatus.keys) {
        await scrollTo(tester, id);
        expect(
          inTile(id, find.textContaining(expectedStatus[id]!)),
          findsOneWidget,
          reason: id,
        );
        expect(
          inTile(id, find.text('Theo chỉ định của bác sĩ')),
          findsOneWidget,
          reason: id,
        );
        expect(inTile(id, find.text('Thêm vào lịch hẹn')), findsOneWidget);
      }
      await scrollTo(tester, 'tl_vax_rsv');
      expect(
        inTile('tl_vax_rsv', find.text('Theo chỉ định của bác sĩ')),
        findsOneWidget,
      );
      expect(
        inTile('tl_vax_rsv', find.text('Thêm vào lịch hẹn')),
        findsNothing,
      );
      expect(
        inTile('tl_vax_rsv', find.text('Đánh dấu đã tiêm')),
        findsOneWidget,
      );
    });

    testWidgets('without a pregnancy the timeline renders as before', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => setPregnancy(null));
      await pumpDetail(tester, byId('pregnant_checkups'));
      await tester.scrollUntilVisible(
        find.text('Siêu âm hình thái học'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(MilestoneStatusChip), findsNothing);
      expect(find.textContaining('Đánh dấu'), findsNothing);
      expect(find.text('Thêm vào lịch hẹn'), findsWidgets);
    });

    testWidgets('pre-pregnancy guide has no status controls', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => setPregnancy(17));
      final pre = guides.firstWhere(
        (g) => g.stage == GuideStage.pre && g.timeline.isNotEmpty,
        orElse: () => byId('pre_vaccination'),
      );
      await pumpDetail(tester, pre);
      expect(find.byType(MilestoneStatusChip), findsNothing);
      expect(find.textContaining('Đánh dấu'), findsNothing);
    });

    for (final entry in {
      'light': ThemeData(
        colorScheme: AppTheme.lightColorScheme,
        primaryColor: AppTheme.primaryColor,
      ),
      'dark': ThemeData(
        colorScheme: AppTheme.darkColorScheme,
        primaryColor: AppTheme.primaryColor,
      ),
    }.entries) {
      test('status chips are readable in ${entry.key} theme', () {
        final scheme = entry.value.colorScheme;
        for (final status in MilestoneStatus.values) {
          final bg = MilestoneStatusChip.background(scheme, status);
          final fg = scheme.onSurface;
          final l1 = fg.computeLuminance();
          final l2 = bg.computeLuminance();
          final ratio =
              ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: status.name);
        }
      });
    }

    Future<void> pumpCard(
      WidgetTester tester,
      PregnancyModel pregnancy, {
      double width = 390,
    }) async {
      setView(tester, width);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: NextMilestoneCard(
                  pregnancy: pregnancy,
                  now: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('card at week 17, after done, and vaccine count', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      ContentPackService.debugGuides = guides;
      final p = _pregnancyAtWeek(17);
      await pumpCard(tester, p);

      final card = find.byKey(const ValueKey('next-milestone-card'));
      expect(card, findsOneWidget);
      expect(find.text('Mốc khám tiếp theo'), findsOneWidget);
      final triple = byId(
        'pregnant_checkups',
      ).timeline.firstWhere((t) => t.id == 'tl_chk_triple');
      expect(find.text(triple.title), findsOneWidget);
      expect(find.text('Tuần 16-18'), findsOneWidget);
      expect(find.text('Đến lúc rồi'), findsOneWidget);
      expect(find.text('Thêm vào lịch hẹn'), findsOneWidget);
      expect(find.text('Xem lịch khám'), findsOneWidget);
      expect(
        find.text('Tiêm phòng: 2 mũi nên hỏi bác sĩ lúc này'),
        findsOneWidget,
      );
      expect(find.textContaining('null'), findsNothing);

      final container = ProviderScope.containerOf(tester.element(card));
      await tester.runAsync(
        () => container
            .read(milestoneProgressProvider.notifier)
            .markDone('tl_chk_triple', DateTime.now()),
      );
      await tester.pump();
      final anomaly = byId(
        'pregnant_checkups',
      ).timeline.firstWhere((t) => t.id == 'tl_chk_anomaly');
      expect(find.text(anomaly.title), findsOneWidget);
      expect(find.text('Sắp tới · còn 19 ngày'), findsOneWidget);

      await tester.runAsync(
        () => container
            .read(milestoneProgressProvider.notifier)
            .markDone('tl_vax_flu', DateTime.now()),
      );
      await tester.pump();
      expect(
        find.text('Tiêm phòng: 1 mũi nên hỏi bác sĩ lúc này'),
        findsOneWidget,
      );
    });

    testWidgets('card is hidden at week 43 and without guides', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ContentPackService.debugGuides = guides;
      await pumpCard(tester, _pregnancyAtWeek(43));
      expect(find.byKey(const ValueKey('next-milestone-card')), findsNothing);

      ContentPackService.debugGuides = const [];
      await pumpCard(tester, _pregnancyAtWeek(17));
      expect(find.byKey(const ValueKey('next-milestone-card')), findsNothing);
    });

    for (final width in [360.0, 390.0]) {
      testWidgets('card does not overflow at ${width.toInt()} dp', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        ContentPackService.debugGuides = guides;
        for (final week in [17, 30, 38]) {
          await pumpCard(tester, _pregnancyAtWeek(week), width: width);
          expect(tester.takeException(), isNull, reason: 'week $week');
        }
      });
    }

    for (final withGuides in [true, false]) {
      testWidgets('HomeScreen builds (guides: $withGuides)', (tester) async {
        SharedPreferences.setMockInitialValues({'app_mode': 'pregnancy'});
        ContentPackService.debugGuides = withGuides ? guides : const [];
        await tester.runAsync(() => setPregnancy(17));
        setView(tester, 600);
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
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('next-milestone-card')),
          withGuides ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}
