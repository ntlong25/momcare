// Phase 25: manual fertility signals, the LH update of the current cycle,
// discreet reminders and the "Nên đi khám khi nào" wording.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/models/fertile_guidance.dart';
import 'package:momcare/core/models/fertility_log_model.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/models/pregnancy_model.dart';
import 'package:momcare/core/providers/app_mode_provider.dart';
import 'package:momcare/core/services/cycle_prediction.dart';
import 'package:momcare/core/services/database_service.dart';
import 'package:momcare/core/services/encryption_service.dart';
import 'package:momcare/core/services/fertility_log_service.dart';
import 'package:momcare/core/services/fertility_reminder_service.dart';
import 'package:momcare/core/services/notification_service.dart';
import 'package:momcare/core/services/thai_giao_reminder_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/date_formatter.dart';
import 'package:momcare/features/bump_journal/quick_camera.dart';
import 'package:momcare/features/fertility/screens/fertility_planner_screen.dart';
import 'package:momcare/features/fertility/widgets/cycle_marker.dart';
import 'package:momcare/features/fertility/widgets/fertility_log_sheet.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:momcare/features/home/screens/pre_pregnancy_home_screen.dart';
import 'package:momcare/l10n/app_localizations.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

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

FertilityLogModel _log(
  DateTime day, {
  LhResult? lh,
  CervicalMucus? mucus,
  double? temperatureC,
  bool intimacy = false,
}) => FertilityLogModel(
  date: day,
  lh: lh,
  mucus: mucus,
  temperatureC: temperatureC,
  intimacy: intimacy,
  updatedAt: day,
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

class _FakeBackend implements ReminderBackend {
  bool allowed = true;
  int permissionRequests = 0;
  final Map<int, DateTime> scheduled = {};
  final List<ReminderNotification> sent = [];
  Set<(String, String)> get texts => {for (final n in sent) (n.title, n.body)};
  final List<int> cancelled = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<void> schedule(ReminderNotification notification) async {
    scheduled[notification.id] = notification.when;
    sent.add(notification);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }
}

/// In-memory boxes: writes finish inside the fake clock of widget tests.
Future<void> _openMemoryBoxes() async {
  if (!Hive.isAdapterRegistered(MenstrualCycleModelAdapter().typeId)) {
    Hive.registerAdapter(MenstrualCycleModelAdapter());
  }
  if (!Hive.isAdapterRegistered(FertilityLogModelAdapter().typeId)) {
    Hive.registerAdapter(FertilityLogModelAdapter());
  }
  await Hive.openBox<MenstrualCycleModel>(
    AppConstants.menstrualCycleBox,
    bytes: Uint8List(0),
  );
  await Hive.openBox<FertilityLogModel>(
    AppConstants.fertilityLogBox,
    bytes: Uint8List(0),
  );
  await Hive.openBox<dynamic>(
    AppConstants.fertilityPrefsBox,
    bytes: Uint8List(0),
  );
}

Future<void> _clearMemoryBoxes() async {
  await DatabaseService.menstrualCycleBox.clear();
  await DatabaseService.fertilityLogBox.clear();
  await DatabaseService.fertilityPrefsBox.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final guidanceJson = File(
    'assets/content/fertile_guidance.json',
  ).readAsStringSync();
  final guidance = FertileGuidance.parse(guidanceJson);

  group('FertilityLogModel', () {
    test('type id does not collide with the existing adapters', () {
      expect(FertilityLogModelAdapter().typeId, 6);
      for (final adapter in <TypeAdapter<dynamic>>[
        PregnancyModelAdapter(),
        MenstrualCycleModelAdapter(),
      ]) {
        expect(adapter.typeId, isNot(6));
      }
    });

    test('a date is a local calendar day, time dropped', () {
      final log = _log(DateTime(2026, 3, 4, 22, 15));
      expect(log.date, _d(2026, 3, 4));
      expect(FertilityLogModel.dayKey(log.date), '2026-03-04');
      expect(FertilityLogModel.dayKey(DateTime.utc(2026, 3, 4)), '2026-03-04');
    });

    test('corrupt fields read as empty, a missing date as invalid', () {
      final junk = FertilityLogModel.fromFields({
        0: _d(2026, 3, 4),
        1: 'unknown',
        2: 7,
        3: 'hot',
        4: 'yes',
        5: 'later',
      });
      expect(junk.isValid, isTrue);
      expect(junk.isEmpty, isTrue);

      for (final fields in <Map<int, dynamic>>[
        const {},
        {0: 'not a date', 1: 'positive'},
      ]) {
        expect(FertilityLogModel.fromFields(fields).isValid, isFalse);
      }
      final impossible = FertilityLogModel.fromFields({
        0: _d(2026, 3, 4),
        3: 90.0,
      });
      expect(impossible.temperatureC, isNull);
      expect(
        FertilityLogModel.fromFields({
          0: _d(2026, 3, 4),
          3: double.nan,
        }).temperatureC,
        isNull,
      );
    });

    test('temperature accepts both decimal marks and refuses the rest', () {
      expect(FertilityLogModel.parseTemperature('36,5'), 36.5);
      expect(FertilityLogModel.parseTemperature(' 36.55 '), 36.55);
      for (final bad in ['', 'abc', '3', '34.9', '39.1', 'NaN', 'Infinity']) {
        expect(FertilityLogModel.parseTemperature(bad), isNull, reason: bad);
      }
      expect(FertilityLogModel.formatTemperature(36.5), '36,5');
      expect(FertilityLogModel.formatTemperature(36.55), '36,55');
      expect(FertilityLogModel.formatTemperature(37), '37');
    });

    test('a hidden intimacy mark alone is not visible', () {
      final log = _log(_d(2026, 3, 4), intimacy: true);
      expect(log.isEmpty, isFalse);
      expect(log.isVisible(showIntimacy: false), isFalse);
      expect(log.isVisible(showIntimacy: true), isTrue);
      expect(
        guidance.logSummary(
          _log(_d(2026, 3, 4), lh: LhResult.peak, intimacy: true),
          showIntimacy: false,
        ),
        'Que thử LH: Đỉnh',
      );
    });
  });

  group('storage', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('momcare_signals');
      PathProviderMock.install(dir.path);
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await Hive.close();
      PathProviderMock.remove();
      await dir.delete(recursive: true);
    });

    /// A pre-Phase 25 install: encrypted boxes and no fertility boxes.
    Future<void> seedOldInstall() async {
      final cipher = await EncryptionService.getEncryptionCipher();
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(MenstrualCycleModelAdapter().typeId)) {
        Hive.registerAdapter(MenstrualCycleModelAdapter());
      }
      final box = await Hive.openBox<MenstrualCycleModel>(
        AppConstants.menstrualCycleBox,
        encryptionCipher: cipher,
      );
      final cycle = _cycles(_d(2026, 3, 1), const []).single;
      await box.put(cycle.id, cycle);
      await Hive.close();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hive_boxes_encrypted', true);
    }

    test('upgrade: old data stays, new boxes open empty and persist', () async {
      await seedOldInstall();
      expect(File('${dir.path}/fertility_log_box.hive').existsSync(), isFalse);

      await DatabaseService.init();
      expect(DatabaseService.getAllMenstrualCycles(), hasLength(1));
      expect(FertilityLogService.all(), isEmpty);
      expect(FertilityLogService.showIntimacy, isFalse);
      expect(FertilityReminderService.load().anyEnabled, isFalse);

      await FertilityLogService.save(
        _log(
          _d(2026, 3, 10),
          lh: LhResult.positive,
          mucus: CervicalMucus.eggWhite,
          temperatureC: 36.55,
          intimacy: true,
        ),
        today: _d(2026, 3, 12),
      );
      await Hive.close();

      await DatabaseService.init();
      expect(DatabaseService.getAllMenstrualCycles(), hasLength(1));
      final stored = FertilityLogService.forDay(_d(2026, 3, 10))!;
      expect(stored.lh, LhResult.positive);
      expect(stored.mucus, CervicalMucus.eggWhite);
      expect(stored.temperatureC, 36.55);
      expect(stored.intimacy, isTrue);
    });

    test('the log and its preferences are encrypted at rest', () async {
      await seedOldInstall();
      await DatabaseService.init();
      await FertilityLogService.save(
        _log(_d(2026, 3, 10), mucus: CervicalMucus.eggWhite),
        today: _d(2026, 3, 12),
      );
      FertilityReminderService.backend = _FakeBackend();
      await FertilityReminderService.update(
        const FertilityReminderSettings(windowEnabled: true),
      );
      await Hive.close();

      // Hive stores keys as they are; values must not be readable.
      for (final (file, value) in [
        ('fertility_log_box.hive', 'eggWhite'),
        ('fertility_prefs_box.hive', 'window'),
      ]) {
        final bytes = File('${dir.path}/$file').readAsBytesSync();
        expect(bytes, isNotEmpty);
        expect(
          String.fromCharCodes(bytes).contains(value),
          isFalse,
          reason: file,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'hive_boxes_encrypted'});
    });

    test('one record per day, the last save wins, empty removes it', () async {
      await seedOldInstall();
      await DatabaseService.init();
      final day = _d(2026, 3, 10);
      final today = _d(2026, 3, 12);
      await FertilityLogService.save(
        _log(DateTime(2026, 3, 10, 7), lh: LhResult.negative),
        today: today,
      );
      await FertilityLogService.save(
        _log(DateTime(2026, 3, 10, 21), lh: LhResult.peak),
        today: today,
      );
      expect(FertilityLogService.all(), hasLength(1));
      expect(FertilityLogService.forDay(day)!.lh, LhResult.peak);

      await FertilityLogService.save(_log(day), today: today);
      expect(FertilityLogService.all(), isEmpty);
    });

    test('future days and invalid records are refused', () async {
      await seedOldInstall();
      await DatabaseService.init();
      expect(
        await FertilityLogService.save(
          _log(_d(2026, 3, 13), lh: LhResult.positive),
          today: _d(2026, 3, 12),
        ),
        isFalse,
      );
      expect(
        await FertilityLogService.save(
          FertilityLogModel.fromFields(const {}),
          today: _d(2026, 3, 12),
        ),
        isFalse,
      );
      expect(FertilityLogService.all(), isEmpty);
    });

    test(
      'delete-all clears logs and settings; day delete clears one',
      () async {
        await seedOldInstall();
        await DatabaseService.init();
        final backend = _FakeBackend();
        FertilityReminderService.backend = backend;
        await FertilityLogService.save(
          _log(_d(2026, 3, 10), lh: LhResult.peak),
          today: _d(2026, 3, 12),
        );
        await FertilityLogService.save(
          _log(_d(2026, 3, 11), lh: LhResult.peak),
          today: _d(2026, 3, 12),
        );
        await FertilityLogService.deleteDay(_d(2026, 3, 10));
        expect(FertilityLogService.all(), hasLength(1));
        await FertilityLogService.setShowIntimacy(true);
        await FertilityReminderService.update(
          const FertilityReminderSettings(windowEnabled: true),
        );

        await DatabaseService.clearAllData();

        expect(FertilityLogService.all(), isEmpty);
        expect(FertilityLogService.showIntimacy, isFalse);
        expect(FertilityReminderService.load().anyEnabled, isFalse);
        await FertilityReminderService.reschedule();
        expect(backend.scheduled, isEmpty);
      },
    );

    test('a damaged stored record is skipped, not fatal', () async {
      await seedOldInstall();
      await DatabaseService.init();
      await DatabaseService.fertilityLogBox.put(
        'bad',
        FertilityLogModel.fromFields(const {}),
      );
      await Hive.close();
      await DatabaseService.init();
      expect(FertilityLogService.all(), isEmpty);
    });
  });

  group('positive LH test', () {
    // Next period 23/4, calendar window 4/4 to 9/4, last start 26/3.
    final regular = _cycles(_d(2026, 1, 1), [28, 28, 28]);

    CyclePrediction at(DateTime today, List<DateTime> positives) =>
        CyclePrediction.compute(
          regular,
          today: today,
          positiveLhDays: positives,
        )!;

    void expectLhDates(CyclePrediction p, DateTime positive) {
      final latest = CycleStats.addDays(positive, 2);
      expect(p.ovulationSource, OvulationSource.lhTest);
      expect(p.lhPositiveDate, positive);
      expect(p.earliestOvulation, positive);
      expect(p.latestOvulation, latest);
      expect(p.fertileEnd, latest);
      expect(p.fertileStart, CycleStats.addDays(positive, -5));
      // Only this cycle moves.
      expect(p.nextPeriod, _d(2026, 4, 23));
      expect(p.earliestPeriod, _d(2026, 4, 23));
      expect(p.latestPeriod, _d(2026, 4, 23));
    }

    test('before the predicted window', () {
      final positive = _d(2026, 4, 1);
      final p = at(positive, [positive]);
      expectLhDates(p, positive);
      expect(p.todayLevel, FertilityLevel.peak);
    });

    test('inside the predicted window', () {
      final positive = _d(2026, 4, 6);
      expectLhDates(at(positive, [positive]), positive);
      expect(at(_d(2026, 4, 8), [positive]).todayLevel, FertilityLevel.peak);
    });

    test('after the predicted window', () {
      final positive = _d(2026, 4, 12);
      final p = at(_d(2026, 4, 13), [positive]);
      expectLhDates(p, positive);
      expect(p.todayLevel, FertilityLevel.peak);
    });

    test('today level ends two days after, even inside the old range', () {
      final positive = _d(2026, 4, 1);
      expect(at(_d(2026, 4, 3), [positive]).todayLevel, FertilityLevel.peak);
      expect(at(_d(2026, 4, 4), [positive]).todayLevel, FertilityLevel.low);
      expect(at(_d(2026, 4, 8), [positive]).todayLevel, FertilityLevel.low);
    });

    test('several positives: the first of this cycle counts, any order', () {
      final first = _d(2026, 4, 5);
      final p = at(_d(2026, 4, 9), [_d(2026, 4, 7), first, _d(2026, 4, 6)]);
      expectLhDates(p, first);
      expect(p.todayLevel, FertilityLevel.low);
    });

    test('a positive of an earlier cycle or the future does nothing', () {
      for (final positive in [_d(2026, 3, 25), _d(2026, 4, 2)]) {
        final p = at(_d(2026, 4, 1), [positive]);
        expect(p.ovulationSource, OvulationSource.calendar);
        expect(p.lhPositiveDate, isNull);
        expect(p.fertileStart, _d(2026, 4, 4));
      }
    });

    test('a positive on the first day of the cycle counts', () {
      final p = at(_d(2026, 3, 26), [_d(2026, 3, 26)]);
      expect(p.lhPositiveDate, _d(2026, 3, 26));
    });

    test('no effect on the next cycle', () {
      final next = [...regular, _cycles(_d(2026, 4, 23), const []).single];
      final p = CyclePrediction.compute(
        next,
        today: _d(2026, 4, 25),
        positiveLhDays: [_d(2026, 4, 6)],
      )!;
      final calendar = CyclePrediction.compute(next, today: _d(2026, 4, 25))!;
      expect(p.ovulationSource, OvulationSource.calendar);
      expect(p.fertileStart, calendar.fertileStart);
      expect(p.ovulation, calendar.ovulation);
      expect(p.nextPeriod, calendar.nextPeriod);
    });

    test('late and stale still win', () {
      final positives = [_d(2026, 4, 6)];
      final late = at(_d(2026, 4, 24), positives);
      expect(late.status, CycleStatus.late);
      expect(late.todayLevel, isNull);
      expect(late.ovulationSource, OvulationSource.calendar);
      final stale = at(_d(2026, 7, 1), positives);
      expect(stale.status, CycleStatus.stale);
      expect(stale.todayLevel, isNull);
      expect(stale.ovulationSource, OvulationSource.calendar);
    });

    test('irregular cycles reach Đỉnh only through a test', () {
      final cycles = _cycles(_d(2026, 1, 1), [24, 38, 24, 38]);
      final last = cycles.last.startDate;
      final day = DateTime(last.year, last.month, last.day + 12);
      final p = CyclePrediction.compute(
        cycles,
        today: day,
        positiveLhDays: [day],
      )!;
      expect(p.todayLevel, FertilityLevel.peak);
      expect(p.confidence, PredictionConfidence.low);
    });

    test('peak days and the mid estimate sit in the expected range', () {
      final positive = _d(2026, 4, 6);
      final p = at(positive, [positive]);
      expect(p.ovulation, _d(2026, 4, 7));
      expect(p.peakStart, positive);
      expect(p.peakEnd, _d(2026, 4, 8));
      expect(p.fertileDays, hasLength(8));
    });

    test('without tests nothing changes', () {
      final p = at(_d(2026, 4, 7), const []);
      expect(p.ovulationSource, OvulationSource.calendar);
      expect(p.isFromLhTest, isFalse);
      expect(p.peakEnd, p.ovulation);
    });

    test('temperature and mucus never reach the prediction', () {
      final logs = [
        _log(
          _d(2026, 4, 6),
          lh: LhResult.negative,
          mucus: CervicalMucus.eggWhite,
          temperatureC: 37.5,
        ),
      ];
      expect(FertilityLogModel.positiveLhDays(logs), isEmpty);
      expect(
        FertilityLogModel.positiveLhDays([
          _log(_d(2026, 4, 6), lh: LhResult.positive),
          _log(_d(2026, 4, 5), lh: LhResult.peak),
        ]),
        [_d(2026, 4, 5), _d(2026, 4, 6)],
      );
      expect(
        File(
          'lib/core/services/cycle_prediction.dart',
        ).readAsStringSync().contains('temperature'),
        isFalse,
      );
    });
  });

  group('reminders', () {
    // Window opens 4/4 at 09:00; ovulation 9/4.
    final regular = _cycles(_d(2026, 1, 1), [28, 28, 28]);
    late _FakeBackend backend;

    setUpAll(() async {
      Hive.init(Directory.systemTemp.path);
      await _openMemoryBoxes();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    setUp(() async {
      await _clearMemoryBoxes();
      backend = _FakeBackend();
      FertilityReminderService.backend = backend;
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'prePregnancy',
      });
    });

    Future<void> seedCycles() async {
      for (final cycle in regular) {
        await DatabaseService.menstrualCycleBox.put(cycle.id, cycle);
      }
    }

    const both = FertilityReminderSettings(
      windowEnabled: true,
      lhEnabled: true,
      chosenStyle: FertilityNotificationStyle.discreet,
    );

    test('off by default and corrupt settings stay off', () {
      expect(const FertilityReminderSettings().anyEnabled, isFalse);
      expect(FertilityReminderService.load().anyEnabled, isFalse);
      for (final bad in [null, 'x', 3, <String, Object>{}]) {
        final s = FertilityReminderSettings.fromJson(bad);
        expect(s.anyEnabled, isFalse);
        expect(s.hour, FertilityReminderSettings.defaultHour);
      }
      final odd = FertilityReminderSettings.fromJson({
        'window': 'yes',
        'hour': 99,
        'minute': -1,
      });
      expect(odd.windowEnabled, isFalse);
      expect(odd.hour, FertilityReminderSettings.defaultHour);
      expect(odd.minute, FertilityReminderSettings.defaultMinute);
    });

    CyclePrediction current(
      List<MenstrualCycleModel> cycles,
      DateTime day, [
      List<DateTime> positives = const [],
    ]) =>
        CyclePrediction.compute(cycles, today: day, positiveLhDays: positives)!;

    List<PlannedReminder> planOn(
      DateTime now, {
      List<MenstrualCycleModel>? cycles,
      List<DateTime> positives = const [],
      FertilityReminderSettings settings = const FertilityReminderSettings(
        windowEnabled: true,
      ),
      DateTime? staleNudgeAt,
    }) => FertilityReminderService.plan(
      current(cycles ?? regular, now, positives),
      current(cycles ?? regular, now),
      settings,
      now,
      staleNudgeAt: staleNudgeAt,
    );

    List<DateTime> daysOf(Iterable<PlannedReminder> plan, ReminderKind kind) =>
        [
          for (final r in plan)
            if (r.kind == kind) CycleStats.dateOnly(r.when),
        ];

    test('ids stay apart from other reminders, within the iOS limit', () {
      final ids = FertilityReminderService.allIds;
      expect(ids, isNot(contains(ThaiGiaoReminderService.notificationId)));
      for (final key in ['habit:1', 'appointment:1', 'thai_giao:daily']) {
        expect(ids, isNot(contains(NotificationService.stableId(key))));
      }
      // iOS keeps 64 pending notifications for the whole app.
      expect(ids.length, lessThanOrEqualTo(20));
    });

    test('ids are fixed, distinct and free of the date', () {
      expect(
        FertilityReminderService.allIds.toSet(),
        hasLength(FertilityReminderService.allIds.length),
      );
      expect(
        FertilityReminderService.lhId(0),
        FertilityReminderService.lhId(0),
      );
    });

    test('first day and peak days match the prediction, two cycles', () {
      // Window 4/4 to 9/4, peak 7/4 to 9/4; next cycle 28 days later.
      final plan = planOn(DateTime(2026, 3, 27, 10));
      expect(daysOf(plan, ReminderKind.fertileFirstDay), [
        _d(2026, 4, 4),
        _d(2026, 5, 2),
      ]);
      expect(daysOf(plan, ReminderKind.fertilePeak), [
        _d(2026, 4, 7),
        _d(2026, 4, 8),
        _d(2026, 4, 9),
        _d(2026, 5, 5),
        _d(2026, 5, 6),
        _d(2026, 5, 7),
      ]);
      expect(plan.first.when, DateTime(2026, 4, 4, 9));
      expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
      for (final r in plan) {
        expect(FertilityReminderService.allIds, contains(r.id));
      }
    });

    test('peak is planned exactly when the card would show Đỉnh', () {
      final plan = planOn(DateTime(2026, 3, 27, 10));
      final peaks = daysOf(plan, ReminderKind.fertilePeak).toSet();
      for (var i = 0; i < 28; i++) {
        final day = _d(2026, 3, 27 + i);
        final card = current(regular, day).todayLevel;
        expect(
          peaks.contains(day),
          card == FertilityLevel.peak,
          reason: '$day',
        );
      }
    });

    test('later cycles match what the prediction rolls forward to', () {
      final base = current(regular, _d(2026, 3, 27));
      // A late day rolls the calendar forward by exactly one cycle.
      final rolled = current(regular, _d(2026, 4, 24));
      final later = base.laterCycle(1);
      expect(later.fertileStart, rolled.fertileStart);
      expect(later.fertileEnd, rolled.fertileEnd);
      expect(later.peakStart, rolled.peakStart);
      expect(later.latestPeriod, rolled.latestPeriod);
      expect(later.isFromLhTest, isFalse);
    });

    test('a finished window gives way: always two cycles ahead', () {
      final plan = planOn(DateTime(2026, 4, 10, 10));
      expect(daysOf(plan, ReminderKind.fertileFirstDay), [
        _d(2026, 5, 2),
        _d(2026, 5, 30),
      ]);
    });

    test('irregular cycles get the first day only, never peak', () {
      final cycles = _cycles(_d(2026, 1, 1), [24, 38, 24, 38]);
      final plan = planOn(cycles.last.startDate, cycles: cycles);
      expect(daysOf(plan, ReminderKind.fertilePeak), isEmpty);
      expect(daysOf(plan, ReminderKind.fertileFirstDay), hasLength(2));
    });

    test('positive LH re-plans this cycle, the next stays calendar', () {
      final positive = _d(2026, 3, 30);
      final plan = planOn(DateTime(2026, 3, 30, 8), positives: [positive]);
      expect(daysOf(plan, ReminderKind.fertilePeak), [
        _d(2026, 3, 30),
        _d(2026, 3, 31),
        _d(2026, 4, 1),
        _d(2026, 5, 5),
        _d(2026, 5, 6),
        _d(2026, 5, 7),
      ]);
      expect(daysOf(plan, ReminderKind.fertileFirstDay), [_d(2026, 5, 2)]);
    });

    test('one update nudge after the schedule runs out', () {
      final plan = planOn(DateTime(2026, 3, 27, 10));
      final nudges = plan.where((r) => r.kind == ReminderKind.updateData);
      expect(nudges, hasLength(1));
      expect(nudges.single.id, FertilityReminderService.updateDataId);
      // After the second cycle's expected period, 21/5.
      expect(nudges.single.when, DateTime(2026, 5, 22, 9));
      expect(
        plan.every(
          (r) => r == nudges.single || r.when.isBefore(nudges.single.when),
        ),
        isTrue,
      );
    });

    test('stale: fertile days stop, only the nudge', () {
      final now = DateTime(2026, 7, 1, 10);
      expect(planOn(now), isEmpty);
      final plan = planOn(now, staleNudgeAt: DateTime(2026, 7, 2, 9));
      expect(plan.single.kind, ReminderKind.updateData);
    });

    test('late: nothing at all', () {
      expect(
        planOn(
          DateTime(2026, 4, 24, 8),
          settings: both,
          staleNudgeAt: DateTime(2026, 4, 25, 9),
        ),
        isEmpty,
      );
    });

    test('no cycles: nothing', () {
      expect(
        FertilityReminderService.plan(null, null, both, _d(2026, 4, 1)),
        isEmpty,
      );
    });

    test('LH reminders stay neutral, current cycle, one a day', () {
      final now = DateTime(2026, 4, 5, 10);
      final lh = planOn(
        now,
        settings: const FertilityReminderSettings(lhEnabled: true),
      );
      expect(lh.map((r) => r.when.day), [6, 7, 8, 9]);
      expect(lh.every((r) => r.kind == ReminderKind.lhTest), isTrue);
      final notification = FertilityReminderService.notificationFor(
        lh.first,
        FertilityNotificationStyle.full,
        guidance,
      );
      expect(notification.body, 'Xem lịch hôm nay');

      final mixed = planOn(now, settings: both);
      final days = mixed.map((r) => CycleStats.dateOnly(r.when)).toList();
      expect(days.toSet(), hasLength(days.length));
      expect(daysOf(mixed, ReminderKind.lhTest), [_d(2026, 4, 6)]);
    });

    test('a positive test stops the LH reminders, wide ranges are capped', () {
      expect(
        planOn(
          DateTime(2026, 3, 28, 10),
          positives: [_d(2026, 3, 28)],
          settings: const FertilityReminderSettings(lhEnabled: true),
        ),
        isEmpty,
      );
      final cycles = _cycles(_d(2026, 1, 1), [22, 40, 22, 40]);
      expect(
        planOn(
          cycles.last.startDate,
          cycles: cycles,
          settings: const FertilityReminderSettings(lhEnabled: true),
        ),
        hasLength(FertilityReminderService.maxLhReminders),
      );
    });

    group('content and lock screen', () {
      final when = PlannedReminder(
        1,
        DateTime.utc(2026),
        ReminderKind.fertilePeak,
      );
      final first = PlannedReminder(
        2,
        DateTime.utc(2026),
        ReminderKind.fertileFirstDay,
      );
      final nudge = PlannedReminder(
        3,
        DateTime.utc(2026),
        ReminderKind.updateData,
      );

      test('Đầy đủ says what the day is, as an estimate', () {
        ReminderNotification full(PlannedReminder r) =>
            FertilityReminderService.notificationFor(
              r,
              FertilityNotificationStyle.full,
              guidance,
            );
        expect(full(first).body, 'Hôm nay là ngày dễ thụ thai (ước tính)');
        expect(full(when).body, 'Hôm nay là ngày đỉnh (ước tính)');
        expect(full(nudge).body, guidance.text('notify_update'));
        expect(full(when).title, 'MomCare+');
      });

      test('Kín đáo is the neutral text everywhere', () {
        for (final r in [first, when, nudge]) {
          final n = FertilityReminderService.notificationFor(
            r,
            FertilityNotificationStyle.discreet,
            guidance,
          );
          expect('${n.title}: ${n.body}', 'MomCare+: Xem lịch hôm nay');
        }
      });

      group('default style', () {
        tearDown(() => debugDefaultTargetPlatformOverride = null);

        test('Android defaults to Đầy đủ, iOS to Kín đáo', () {
          for (final (platform, expected) in [
            (TargetPlatform.android, FertilityNotificationStyle.full),
            (TargetPlatform.iOS, FertilityNotificationStyle.discreet),
          ]) {
            debugDefaultTargetPlatformOverride = platform;
            expect(const FertilityReminderSettings().style, expected);
            expect(
              FertilityReminderSettings.fromJson({'style': 'nope'}).style,
              expected,
            );
            expect(
              FertilityReminderSettings.fromJson({'window': true}).style,
              expected,
            );
          }
        });

        test('a stored choice wins on both platforms', () {
          for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
            debugDefaultTargetPlatformOverride = platform;
            for (final style in FertilityNotificationStyle.values) {
              final stored = FertilityReminderSettings.fromJson(
                const FertilityReminderSettings()
                    .copyWith(style: style)
                    .toJson(),
              );
              expect(stored.style, style);
              expect(stored.copyWith(hour: 7).style, style);
            }
          }
        });

        test('no choice is stored until the user makes one', () async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          await FertilityReminderService.update(
            const FertilityReminderSettings(windowEnabled: true),
          );
          expect(FertilityReminderService.load().chosenStyle, isNull);
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          expect(
            FertilityReminderService.load().style,
            FertilityNotificationStyle.discreet,
          );
        });
      });

      test('both styles carry the neutral public version', () {
        for (final style in FertilityNotificationStyle.values) {
          for (final r in [first, when, nudge]) {
            final map = FertilityReminderService.notificationFor(
              r,
              style,
              guidance,
            ).toMap();
            expect(
              '${map['publicTitle']}: ${map['publicBody']}',
              guidance.text('reminder_text'),
            );
          }
        }
      });

      test('a missing wording pack falls back to neutral', () {
        final n = FertilityReminderService.notificationFor(
          when,
          FertilityNotificationStyle.full,
          const FertileGuidance.empty(),
        );
        expect(n.body, 'Xem lịch hôm nay');
      });

      test('Android posts private with the public version', () {
        final source = File(
          'android/app/src/main/kotlin/com/ntlong25/momcare/CalendarReminders.kt',
        ).readAsStringSync();
        expect(
          source,
          contains('.setVisibility(Notification.VISIBILITY_PRIVATE)'),
        );
        expect(source, contains('.setPublicVersion(lockScreen)'));
        expect(source, contains('entry.getString("publicBody")'));
        expect(source.contains('Log.'), isFalse);
        final manifest = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        expect(manifest, contains('android:allowBackup="false"'));
        expect(manifest, contains('.CalendarReminderReceiver'));
        expect(manifest.contains('SCHEDULE_EXACT_ALARM'), isFalse);
      });

      test('a tap reaches Dart, also from a cold start', () {
        final activity = File(
          'android/app/src/main/kotlin/com/ntlong25/momcare/MainActivity.kt',
        ).readAsStringSync();
        expect(activity, contains('invokeMethod("tapped", null)'));
        expect(activity, contains('"takeTap" -> {'));
        expect(
          activity,
          contains('isCalendarTap(intent)) calendarTapped = true'),
        );
        expect(
          File(
            'lib/features/bump_journal/quick_camera.dart',
          ).readAsStringSync(),
          contains('openCycleRequestProvider'),
        );
        expect(
          File('lib/main.dart').readAsStringSync(),
          contains('FertilityReminderService.listenForTaps'),
        );
      });
    });

    group('automatic permission request', () {
      test('asks once; granted turns fertile notifications on', () async {
        await seedCycles();
        await FertilityReminderService.askOnce(now: DateTime(2026, 3, 27, 10));
        expect(backend.permissionRequests, 1);
        final settings = FertilityReminderService.load();
        expect(settings.windowEnabled, isTrue);
        expect(settings.lhEnabled, isFalse);
        expect(settings.chosenStyle, isNull);
        expect(settings.style, FertilityNotificationStyle.full); // Android.
        expect(backend.sent.first.publicBody, 'Xem lịch hôm nay');
        expect(backend.scheduled, isNotEmpty);

        await FertilityReminderService.askOnce();
        expect(backend.permissionRequests, 1);
      });

      test('iOS gets the discreet default', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await seedCycles();
        await FertilityReminderService.askOnce(now: DateTime(2026, 3, 27, 10));
        expect(
          FertilityReminderService.load().style,
          FertilityNotificationStyle.discreet,
        );
        expect(backend.texts, {('MomCare+', 'Xem lịch hôm nay')});
      });

      test('denied stays off and is never asked again', () async {
        backend.allowed = false;
        await FertilityReminderService.askOnce();
        await FertilityReminderService.askOnce();
        expect(backend.permissionRequests, 1);
        expect(FertilityReminderService.permissionAsked, isTrue);
        expect(FertilityReminderService.load().anyEnabled, isFalse);
        expect(backend.scheduled, isEmpty);

        // The Chu kỳ settings still enable them.
        backend.allowed = true;
        expect(
          await FertilityReminderService.update(
            const FertilityReminderSettings(windowEnabled: true),
          ),
          isTrue,
        );
        expect(FertilityReminderService.load().windowEnabled, isTrue);
      });

      test('parallel calls ask once', () async {
        await Future.wait([
          FertilityReminderService.askOnce(),
          FertilityReminderService.askOnce(),
        ]);
        expect(backend.permissionRequests, 1);
      });

      test('never in pregnancy mode', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.appModeKey: 'pregnancy',
        });
        await FertilityReminderService.askOnce();
        expect(backend.permissionRequests, 0);
        expect(FertilityReminderService.permissionAsked, isFalse);
      });

      test('delete-all resets the flag', () async {
        await FertilityReminderService.askOnce();
        expect(FertilityReminderService.permissionAsked, isTrue);
        // clearAllData clears this box (see the storage group); the other
        // boxes are not open in this group.
        await DatabaseService.fertilityPrefsBox.clear();
        expect(FertilityReminderService.permissionAsked, isFalse);
        await FertilityReminderService.askOnce();
        expect(backend.permissionRequests, 2);
      });

      test('already on: remembered, no request', () async {
        await FertilityReminderService.update(
          const FertilityReminderSettings(lhEnabled: true),
        );
        final before = backend.permissionRequests;
        await FertilityReminderService.askOnce();
        expect(backend.permissionRequests, before);
        expect(FertilityReminderService.permissionAsked, isTrue);
      });

      test('the offer card is gone', () {
        expect(
          File(
            'lib/features/fertility/widgets/fertility_offer_card.dart',
          ).existsSync(),
          isFalse,
        );
        expect(guidanceJson.contains('offer_'), isFalse);
      });
    });

    test('every kind opens Chu kỳ: one tap action and one payload', () {
      final kotlin = File(
        'android/app/src/main/kotlin/com/ntlong25/momcare/CalendarReminders.kt',
      ).readAsStringSync();
      expect('setAction('.allMatches(kotlin).length, 2); // fire + open.
      expect(kotlin, contains('.setAction(ACTION_OPEN_CYCLE)'));
      final dart = File(
        'lib/core/services/fertility_reminder_service.dart',
      ).readAsStringSync();
      expect(
        'payload: FertilityReminderService.payload'.allMatches(dart).length,
        1,
      );
      for (final kind in ReminderKind.values) {
        final n = FertilityReminderService.notificationFor(
          PlannedReminder(1, DateTime(2026), kind),
          FertilityNotificationStyle.full,
          guidance,
        );
        expect(n.publicBody, 'Xem lịch hôm nay', reason: kind.name);
      }
    });

    test('stale gives one nudge, opening the app does not repeat it', () async {
      await seedCycles(); // Last start 26/3; stale after 21/5.
      final now = DateTime(2026, 7, 1, 10);
      await FertilityReminderService.update(
        const FertilityReminderSettings(windowEnabled: true),
        now: now,
      );
      expect(backend.scheduled.keys, [FertilityReminderService.updateDataId]);
      expect(backend.scheduled.values.single, DateTime(2026, 7, 2, 9));

      // The time follows 'Giờ nhắc' even when the day is remembered
      // (P25-F-04).
      await FertilityReminderService.update(
        FertilityReminderService.load().copyWith(hour: 18, minute: 51),
        now: now,
      );
      expect(backend.scheduled.values.single, DateTime(2026, 7, 2, 18, 51));
      await FertilityReminderService.reschedule(now: DateTime(2026, 7, 2, 10));
      expect(backend.scheduled.values.single, DateTime(2026, 7, 2, 18, 51));

      // Fired, then the app opens the day after.
      await FertilityReminderService.reschedule(now: DateTime(2026, 7, 3, 10));
      expect(backend.scheduled, isEmpty);
    });

    test('delete-all cancels the scheduled ids', () async {
      await seedCycles();
      await FertilityReminderService.update(
        both,
        now: DateTime(2026, 3, 27, 10),
      );
      await FertilityReminderService.onDataDeleted();
      expect(backend.scheduled, isEmpty);
      expect(
        File(
          'lib/features/settings/screens/settings_screen.dart',
        ).readAsStringSync(),
        contains('FertilityReminderService.onDataDeleted()'),
      );
    });

    test('text and payload stay discreet', () async {
      await seedCycles();
      await FertilityReminderService.update(
        both,
        now: DateTime(2026, 3, 27, 10),
      );
      expect(backend.scheduled, isNotEmpty);
      expect(backend.texts, {('MomCare+', 'Xem lịch hôm nay')});
      expect(backend.sent.first.publicBody, 'Xem lịch hôm nay');
      expect(
        '${FertilityReminderService.title}: ${FertilityReminderService.body}',
        guidance.text('reminder_text'),
      );
      final visible = [
        FertilityReminderService.title,
        FertilityReminderService.body,
        FertilityReminderService.payload,
      ].join(' ').toLowerCase();
      for (final word in [
        'thụ thai',
        'rụng trứng',
        'lh',
        'que',
        'quan hệ',
        'gần gũi',
        'fertil',
        'ovul',
      ]) {
        expect(visible.contains(word), isFalse, reason: word);
      }
    });

    test(
      'the settings go to the encrypted box, not SharedPreferences',
      () async {
        await FertilityReminderService.update(
          const FertilityReminderSettings(windowEnabled: true, hour: 7),
        );
        expect(FertilityReminderService.load().hour, 7);
        expect(FertilityReminderService.load().windowEnabled, isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), {AppConstants.appModeKey});
      },
    );

    test('denied permission leaves everything off', () async {
      await seedCycles();
      backend.allowed = false;
      final ok = await FertilityReminderService.update(
        both,
        now: DateTime(2026, 3, 27, 10),
      );
      expect(ok, isFalse);
      expect(FertilityReminderService.load().anyEnabled, isFalse);
      expect(backend.scheduled, isEmpty);
    });

    test('app start reschedules without asking for permission', () async {
      await seedCycles();
      await FertilityReminderService.update(
        both,
        now: DateTime(2026, 3, 27, 10),
      );
      final before = Map<int, DateTime>.of(backend.scheduled);
      backend.scheduled.clear();
      final requests = backend.permissionRequests;

      await FertilityReminderService.reschedule(now: DateTime(2026, 3, 27, 10));
      expect(backend.scheduled, before);
      expect(backend.permissionRequests, requests);
    });

    test('app start does nothing when off or not in this mode', () async {
      await seedCycles();
      await FertilityReminderService.reschedule(now: DateTime(2026, 3, 27, 10));
      expect(backend.scheduled, isEmpty);

      await FertilityReminderService.update(
        both,
        now: DateTime(2026, 3, 27, 10),
      );
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'pregnancy',
      });
      await FertilityReminderService.reschedule(now: DateTime(2026, 3, 27, 10));
      expect(backend.scheduled, isEmpty);
    });

    test('switching to pregnancy cancels and turns reminders off', () async {
      await seedCycles();
      await FertilityReminderService.update(
        both,
        now: DateTime(2026, 3, 27, 10),
      );
      expect(backend.scheduled, isNotEmpty);

      await AppModeNotifier().setMode(AppMode.pregnancy);

      expect(backend.scheduled, isEmpty);
      expect(backend.cancelled, containsAll(FertilityReminderService.allIds));
      expect(FertilityReminderService.load().anyEnabled, isFalse);

      // Going back never brings them back unasked.
      await AppModeNotifier().setMode(AppMode.prePregnancy);
      await FertilityReminderService.reschedule(now: DateTime(2026, 3, 27, 10));
      expect(backend.scheduled, isEmpty);
    });

    test('a new period rebuilds the dates through the box watcher', () async {
      await seedCycles();
      await FertilityReminderService.update(
        const FertilityReminderSettings(windowEnabled: true),
        now: DateTime(2026, 3, 27, 10),
      );
      expect(backend.scheduled, isNotEmpty);

      FertilityReminderService.startWatching();
      addTearDown(FertilityReminderService.stopWatching);
      // The watcher uses the real date, so the seeded plan becomes empty only
      // because April 2026 is over; the point is that it rebuilt.
      backend.cancelled.clear();
      final next = _cycles(_d(2026, 4, 23), const []).single;
      await DatabaseService.menstrualCycleBox.put(next.id, next);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(backend.cancelled, containsAll(FertilityReminderService.allIds));

      // main.dart calls startWatching on the boot path.
      expect(
        File('lib/main.dart').readAsStringSync(),
        contains('FertilityReminderService.startWatching()'),
      );
    });

    test('settings delete-all wipes through DatabaseService first', () {
      final source = File(
        'lib/features/settings/screens/settings_screen.dart',
      ).readAsStringSync();
      final cancel = source.indexOf('cancelAllNotifications()');
      final clear = source.indexOf('DatabaseService.clearAllData()');
      expect(cancel, greaterThan(0));
      expect(clear, greaterThan(cancel));
    });
  });

  group('privacy guards', () {
    const files = [
      'lib/core/models/fertility_log_model.dart',
      'lib/core/services/fertility_log_service.dart',
      'lib/core/services/fertility_reminder_service.dart',
      'lib/features/fertility/widgets/fertility_log_sheet.dart',
      'lib/features/fertility/widgets/fertility_signals_card.dart',
    ];

    test('nothing is logged, sent or put into SharedPreferences', () {
      for (final path in files) {
        final source = File(path).readAsStringSync();
        for (final banned in [
          'print(',
          '_logger',
          'AppLogger',
          'http',
          'analytics',
          'Health()',
        ]) {
          expect(source.contains(banned), isFalse, reason: '$path: $banned');
        }
      }
      final log = File(files[1]).readAsStringSync();
      expect(log.contains('prefs.set'), isFalse);
      // The reminder service reads the app mode only.
      final reminders = File(files[2]).readAsStringSync();
      expect(RegExp(r'prefs\.set').hasMatch(reminders), isFalse);
    });

    test('no new permissions and no Health sync of the new types', () {
      final health = File(
        'lib/core/services/health_service.dart',
      ).readAsStringSync();
      expect(health.contains('fertility'), isFalse);
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      for (final type in ['OVULATION', 'SEXUAL', 'CERVICAL', 'TEMPERATURE']) {
        expect(manifest.toUpperCase().contains(type), isFalse, reason: type);
      }
    });

    test('local data and privacy text name the new data', () {
      for (final path in [
        'lib/features/settings/screens/settings_screen.dart',
        'lib/features/legal/screens/privacy_policy_screen.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('tín hiệu thụ thai'), reason: path);
        expect(source, contains('que LH'), reason: path);
        expect(source, contains('thông báo ngày dễ thụ thai'), reason: path);
      }
    });
  });

  group('wording', () {
    test('required ids are in the asset and the review packet', () {
      final csv = File(
        'content_source/review/6_canh_ngay.csv',
      ).readAsStringSync();
      expect(guidance.isEmpty, isFalse);
      for (final id in FertileGuidance.requiredIds) {
        expect(guidance.text(id), isNotEmpty, reason: id);
        expect(csv, contains(guidance.text(id)), reason: id);
      }
      expect(guidanceJson, contains('draft_requires_medical_review'));
      expect(guidanceJson, isNot(contains('"approved"')));
    });

    test('the asset comes from the generator source', () {
      final source = File(
        'content_source/build/fertile_guidance.js',
      ).readAsStringSync();
      for (final id in FertileGuidance.requiredIds) {
        expect(source, contains("'$id'"), reason: id);
      }
    });

    test('no pregnancy chance, diagnosis, month count or sex selection', () {
      final lower = guidanceJson.toLowerCase();
      for (final banned in [
        'giới tính',
        'bé trai',
        'bé gái',
        'thất bại',
        'chắc chắn',
        'vô sinh',
        'đã rụng trứng rồi',
      ]) {
        expect(lower.contains(banned), isFalse, reason: banned);
      }
      for (final id in FertileGuidance.requiredIds) {
        expect(guidance.text(id).contains('%'), isFalse, reason: id);
      }
      expect(guidance.text('lh_note'), contains('không xác nhận'));
      expect(guidance.text('signals_history_note'), contains('không dùng'));
      expect(guidance.text('intimacy_label'), 'Ngày gần gũi');
      expect(guidance.text('lh_source'), 'theo que thử');
    });

    test('the doctor card has no thresholds and marks them for a doctor', () {
      final ids = FertileGuidance.requiredIds.where(
        (id) => id.startsWith('doctor_'),
      );
      expect(ids, hasLength(5));
      for (final id in ids) {
        expect(
          RegExp(r'\d').hasMatch(guidance.text(id)),
          isFalse,
          reason: '$id must not state a number',
        );
      }
      expect(guidance.text('doctor_age'), contains('bác sĩ xác nhận'));
      expect(guidance.text('doctor_anytime'), contains('không phải chẩn đoán'));
    });
  });

  group('screens', () {
    setUpAll(() async {
      final loader = FontLoader(AppTheme.fontFamily);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        final bytes = File(
          'assets/fonts/BeVietnamPro-$weight.ttf',
        ).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
      Hive.init(Directory.systemTemp.path);
      await _openMemoryBoxes();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    late _FakeBackend backend;

    setUp(() async {
      await _clearMemoryBoxes();
      backend = _FakeBackend();
      FertilityReminderService.backend = backend;
      SharedPreferences.setMockInitialValues({
        AppConstants.appModeKey: 'prePregnancy',
      });
      ContentPackService.debugGuides = const [];
      ContentPackService.debugFertileGuidance = guidance;
    });

    tearDown(() {
      ContentPackService.debugFertileGuidance = const FertileGuidance.empty();
    });

    Widget app(Widget home, {bool dark = false, double scale = 1}) {
      return ProviderScope(
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
          home: home,
        ),
      );
    }

    Future<void> pumpPlanner(
      WidgetTester tester, {
      bool dark = false,
      double scale = 1,
      double width = 412,
      double height = 5000,
    }) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(const FertilityPlannerScreen(), dark: dark, scale: scale),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    DateTime dayAgo(int days) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - days);
    }

    /// A regular current cycle started [daysAgo] days ago.
    Future<List<MenstrualCycleModel>> seedCycles(int daysAgo) async {
      final cycles = _cycles(dayAgo(daysAgo + 56), [28, 28]);
      for (final cycle in cycles) {
        await DatabaseService.menstrualCycleBox.put(cycle.id, cycle);
      }
      return cycles;
    }

    Finder sheetChip(String key) => find.byKey(ValueKey(key));

    testWidgets('log from Chu kỳ in two taps', (tester) async {
      await seedCycles(10);
      await pumpPlanner(tester);

      await tester.tap(find.byKey(const ValueKey('fertility-log-open')));
      await tester.pumpAndSettle();
      await tester.tap(sheetChip('fertility-lh-positive'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final log = FertilityLogService.forDay(DateTime.now())!;
      expect(log.lh, LhResult.positive);
    });

    testWidgets('log from the Hôm nay card', (tester) async {
      final cycles = await seedCycles(10);
      tester.view.physicalSize = const Size(412, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(PrePregnancyHomeScreen(debugCycles: cycles)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const ValueKey('fertile-today-log')));
      await tester.pumpAndSettle();
      await tester.tap(sheetChip('fertility-mucus-watery'));
      await tester.pumpAndSettle();
      expect(
        FertilityLogService.forDay(DateTime.now())!.mucus,
        CervicalMucus.watery,
      );
    });

    testWidgets('sheet edits, clears a choice, deletes the day', (
      tester,
    ) async {
      await seedCycles(10);
      final day = dayAgo(1);
      await FertilityLogService.save(
        _log(day, lh: LhResult.negative, temperatureC: 36.5),
      );
      await pumpPlanner(tester);

      await tester.tap(
        find.byKey(
          ValueKey('fertility-history-${FertilityLogModel.dayKey(day)}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('36,5'), findsOneWidget);

      await tester.tap(sheetChip('fertility-lh-peak'));
      await tester.pumpAndSettle();
      expect(FertilityLogService.forDay(day)!.lh, LhResult.peak);
      await tester.tap(sheetChip('fertility-lh-peak'));
      await tester.pumpAndSettle();
      expect(FertilityLogService.forDay(day)!.lh, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('fertility-temperature')),
        '50',
      );
      await tester.pumpAndSettle();
      expect(find.text(guidance.text('temperature_invalid')), findsOneWidget);
      expect(FertilityLogService.forDay(day)!.temperatureC, 36.5);

      await tester.enterText(
        find.byKey(const ValueKey('fertility-temperature')),
        '36,7',
      );
      await tester.pumpAndSettle();
      expect(FertilityLogService.forDay(day)!.temperatureC, 36.7);

      await tester.tap(find.byKey(const ValueKey('fertility-log-delete')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('fertility-log-delete-confirm')),
      );
      await tester.pumpAndSettle();
      expect(FertilityLogService.forDay(day), isNull);
      expect(find.byKey(const ValueKey('fertility-log-sheet')), findsNothing);
    });

    testWidgets('intimacy is hidden until enabled, markers too', (
      tester,
    ) async {
      await seedCycles(10);
      final day = dayAgo(1);
      await FertilityLogService.save(_log(day, intimacy: true));
      await pumpPlanner(tester);

      expect(find.byKey(const ValueKey('cycle-marker-intimacy')), findsNothing);
      expect(find.byKey(const ValueKey('cycle-marker-logged')), findsNothing);
      expect(find.byKey(const ValueKey('cycle-legend-intimacy')), findsNothing);
      expect(find.textContaining('Ngày gần gũi'), findsNothing);
      expect(
        find.byKey(
          ValueKey('fertility-history-${FertilityLogModel.dayKey(day)}'),
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('fertility-log-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fertility-intimacy')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('fertility-log-done')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('fertility-signals-settings')),
      );
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('fertility-setting-intimacy'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cycle-marker-intimacy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cycle-legend-intimacy')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('fertility-log-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fertility-intimacy')), findsOneWidget);
    });

    testWidgets('a logged day has its calendar mark beside the cycle mark', (
      tester,
    ) async {
      await seedCycles(1); // Today is a period day.
      await FertilityLogService.save(_log(dayAgo(0), lh: LhResult.negative));
      await pumpPlanner(tester);
      expect(find.byKey(const ValueKey('cycle-marker-logged')), findsOneWidget);
      expect(find.byKey(const ValueKey('cycle-marker-period')), findsWidgets);
    });

    testWidgets('reminder switches are off, opt in and show denial', (
      tester,
    ) async {
      await seedCycles(2);
      await pumpPlanner(tester);
      await tester.tap(
        find.byKey(const ValueKey('fertility-signals-settings')),
      );
      await tester.pumpAndSettle();

      final window = find.byKey(
        const ValueKey('fertility-setting-reminder-window'),
      );
      expect(tester.widget<SwitchListTile>(window).value, isFalse);
      expect(
        find.byKey(const ValueKey('fertility-setting-reminder-time')),
        findsNothing,
      );

      backend.allowed = false;
      await tester.tap(window);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(window).value, isFalse);
      expect(
        find.byKey(const ValueKey('fertility-reminder-denied')),
        findsOneWidget,
      );

      backend.allowed = true;
      await tester.tap(window);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(window).value, isTrue);
      expect(
        find.byKey(const ValueKey('fertility-setting-reminder-time')),
        findsOneWidget,
      );
    });

    testWidgets('Chu kỳ names the test as the source; history stays plain', (
      tester,
    ) async {
      await seedCycles(10);
      final positive = dayAgo(1);
      await FertilityLogService.save(
        _log(
          positive,
          lh: LhResult.positive,
          mucus: CervicalMucus.eggWhite,
          temperatureC: 37.1,
        ),
      );
      await pumpPlanner(tester);

      expect(
        find.text('Ngày rụng trứng dự kiến (theo que thử)'),
        findsOneWidget,
      );
      expect(find.text('Cửa sổ thụ thai (theo que thử)'), findsOneWidget);
      expect(
        find.text(
          DateFormatter.formatDateRange(
            positive,
            CycleStats.addDays(positive, 2),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(guidance.text('lh_note')), findsOneWidget);
      expect(find.text(guidance.text('signals_history_note')), findsOneWidget);
      expect(find.textContaining('37,1°C'), findsOneWidget);
    });

    testWidgets('Hôm nay and Chu kỳ agree on the test dates', (tester) async {
      final cycles = await seedCycles(10);
      final positive = dayAgo(0);
      await FertilityLogService.save(_log(positive, lh: LhResult.positive));
      final range = DateFormatter.formatDateRange(
        positive,
        CycleStats.addDays(positive, 2),
      );

      await pumpPlanner(tester);
      expect(find.text(range), findsOneWidget);

      await tester.pumpWidget(app(PrePregnancyHomeScreen(debugCycles: cycles)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Đỉnh (ước tính)'), findsOneWidget);
      expect(find.text(range), findsOneWidget);
      expect(
        find.text('Ngày rụng trứng dự kiến (theo que thử)'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fertile-today-lh-note')),
        findsOneWidget,
      );
      expect(find.textContaining('không dùng để tránh thai'), findsOneWidget);
    });

    testWidgets('a late cycle ignores the test on both screens', (
      tester,
    ) async {
      final cycles = await seedCycles(30);
      await FertilityLogService.save(_log(dayAgo(15), lh: LhResult.positive));
      await pumpPlanner(tester);
      expect(find.textContaining('theo que thử'), findsNothing);
      expect(find.byKey(const ValueKey('cycle-late-state')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('fertility-signals-card')),
        findsOneWidget,
      );

      await tester.pumpWidget(app(PrePregnancyHomeScreen(debugCycles: cycles)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('theo que thử'), findsNothing);
      expect(find.byKey(const ValueKey('late-period-card')), findsOneWidget);
    });

    testWidgets('first pre-pregnancy Hôm nay asks once, no card', (
      tester,
    ) async {
      final cycles = await seedCycles(10);
      Future<void> pumpHome() async {
        await tester.pumpWidget(
          app(PrePregnancyHomeScreen(debugCycles: cycles)),
        );
        await tester.pumpAndSettle();
      }

      tester.view.physicalSize = const Size(412, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpHome();
      expect(backend.permissionRequests, 1);
      expect(FertilityReminderService.load().windowEnabled, isTrue);
      expect(find.textContaining('Nhận thông báo'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await pumpHome();
      expect(backend.permissionRequests, 1);
    });

    testWidgets('Chu kỳ never asks by itself', (tester) async {
      await seedCycles(2);
      await pumpPlanner(tester);
      expect(backend.permissionRequests, 0);
      expect(FertilityReminderService.load().anyEnabled, isFalse);
    });

    testWidgets('typing 08 in the time picker saves 08:00 (P25-R1-01)', (
      tester,
    ) async {
      await seedCycles(2);
      await FertilityReminderService.update(
        const FertilityReminderSettings(windowEnabled: true, hour: 21),
      );
      await pumpPlanner(tester);
      await tester.tap(
        find.byKey(const ValueKey('fertility-signals-settings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('fertility-setting-reminder-time')),
      );
      await tester.pumpAndSettle();

      final dialog = find.byType(TimePickerDialog);
      expect(dialog, findsOneWidget);
      expect(
        MediaQuery.of(tester.element(dialog)).alwaysUse24HourFormat,
        isTrue,
      );

      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '08');
      await tester.enterText(fields.at(1), '00');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: dialog, matching: find.byType(TextButton)).last,
      );
      await tester.pumpAndSettle();

      final saved = FertilityReminderService.load();
      expect((saved.hour, saved.minute), (8, 0));
      expect(backend.scheduled.values.every((d) => d.hour == 8), isTrue);
    });

    testWidgets('style setting shows the default and can change', (
      tester,
    ) async {
      await seedCycles(2);
      await FertilityReminderService.update(
        const FertilityReminderSettings(windowEnabled: true),
      );
      await pumpPlanner(tester);
      await tester.tap(
        find.byKey(const ValueKey('fertility-signals-settings')),
      );
      await tester.pumpAndSettle();
      ChoiceChip chip(String name) => tester.widget<ChoiceChip>(
        find.byKey(ValueKey('fertility-style-$name')),
      );
      expect(chip('full').selected, isTrue); // Android default.
      await tester.tap(find.byKey(const ValueKey('fertility-style-discreet')));
      await tester.pumpAndSettle();
      expect(chip('discreet').selected, isTrue);
      expect(
        FertilityReminderService.load().chosenStyle,
        FertilityNotificationStyle.discreet,
      );
      expect(find.text(guidance.text('style_note')), findsOneWidget);
      expect(
        guidance.text('style_note'),
        contains('màn hình khóa sẽ hiện đầy đủ nội dung này'),
      );
    });

    testWidgets('a notification tap opens Chu kỳ', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(appModeProvider.notifier)
          .setMode(AppMode.prePregnancy);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QuickCameraListener(child: Scaffold()),
          ),
        ),
      );
      Navigator.of(
        tester.element(find.byType(Scaffold)),
      ).push(MaterialPageRoute<void>(builder: (_) => const Text('pushed')));
      await tester.pumpAndSettle();

      container.read(openCycleRequestProvider.notifier).state = true;
      await tester.pumpAndSettle();
      expect(find.text('pushed'), findsNothing);
      expect(container.read(navigationIndexProvider), cycleTabIndex);
      expect(container.read(openCycleRequestProvider), isFalse);
    });

    testWidgets('a tap that launched the app waits for the gates', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(appModeProvider.notifier)
          .setMode(AppMode.prePregnancy);
      container.read(openCycleRequestProvider.notifier).state = true;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold()),
        ),
      );
      await tester.pump();
      expect(container.read(navigationIndexProvider), 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QuickCameraListener(child: Scaffold()),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(navigationIndexProvider), cycleTabIndex);
      expect(container.read(openCycleRequestProvider), isFalse);
    });

    testWidgets('a tap in pregnancy mode changes nothing', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(appModeProvider.notifier).setMode(AppMode.pregnancy);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QuickCameraListener(child: Scaffold()),
          ),
        ),
      );
      container.read(openCycleRequestProvider.notifier).state = true;
      await tester.pumpAndSettle();
      expect(container.read(navigationIndexProvider), 0);
    });

    testWidgets('a tap returns from Sức khỏe to the Chu kỳ page', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TabbedScaffold(
              title: 't',
              followsCycleRequest: true,
              pages: [
                TabbedPage(
                  id: 'cycle',
                  label: 'Chu kỳ',
                  icon: Icons.calendar_month,
                  child: Text('cycle page'),
                ),
                TabbedPage(
                  id: 'health',
                  label: 'Sức khỏe',
                  icon: Icons.favorite,
                  child: Text('health page'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('tab-health')));
      await tester.pumpAndSettle();
      expect(find.text('health page'), findsOneWidget);

      container.read(openCycleEventProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(find.text('cycle page'), findsOneWidget);
    });

    testWidgets('a tap opens Chu kỳ at the calendar (P25-F-07)', (
      tester,
    ) async {
      await seedCycles(10);
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(appModeProvider.notifier)
          .setMode(AppMode.prePregnancy);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app(
            const QuickCameraListener(child: FertilityPlannerScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      ScrollPosition position() => tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('cycle-planner-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      position().jumpTo(800);
      await tester.pumpAndSettle();
      expect(position().pixels, greaterThan(0));

      container.read(openCycleRequestProvider.notifier).state = true;
      await tester.pumpAndSettle();
      expect(position().pixels, 0);
      expect(container.read(navigationIndexProvider), cycleTabIndex);
    });

    testWidgets('no request while Hôm nay is not on screen (P25-F-01)', (
      tester,
    ) async {
      final cycles = await seedCycles(10);
      tester.view.physicalSize = const Size(412, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Mode switched from Cài đặt: the home is built on another tab.
      container.read(navigationIndexProvider.notifier).state = 4;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: app(PrePregnancyHomeScreen(debugCycles: cycles)),
        ),
      );
      await tester.pumpAndSettle();
      expect(backend.permissionRequests, 0);
      expect(FertilityReminderService.permissionAsked, isFalse);

      // A route above Hôm nay, e.g. a dialog, also counts as not seen.
      final nav = Navigator.of(
        tester.element(find.byType(PrePregnancyHomeScreen)),
      );
      nav.push(MaterialPageRoute<void>(builder: (_) => const Text('above')));
      await tester.pumpAndSettle();
      container.read(navigationIndexProvider.notifier).state = 0;
      await tester.pumpAndSettle();
      expect(backend.permissionRequests, 0);

      nav.pop();
      await tester.pumpAndSettle();
      expect(backend.permissionRequests, 1);
      expect(FertilityReminderService.permissionAsked, isTrue);
    });

    testWidgets('the focused temperature field stays above the keyboard '
        '(P25-F-05)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFertilityLogSheet(context, DateTime.now()),
                child: const Text('open'),
              ),
            ),
          ),
          scale: 1.5,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('fertility-temperature'));
      await tester.showKeyboard(field);
      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(field).bottom, lessThanOrEqualTo(640 - keyboard));
      await tester.enterText(field, '50');
      await tester.pumpAndSettle();
      final error = find.text(guidance.text('temperature_invalid'));
      expect(error, findsOneWidget);
      expect(tester.getRect(error).bottom, lessThanOrEqualTo(640 - keyboard));
    });

    testWidgets('doctor card shows wording only', (tester) async {
      await pumpPlanner(tester);
      final card = find.byKey(const ValueKey('fertility-doctor-card'));
      expect(card, findsOneWidget);
      for (final id in [
        'doctor_title',
        'doctor_cycles',
        'doctor_trying',
        'doctor_age',
        'doctor_anytime',
      ]) {
        expect(
          find.descendant(of: card, matching: find.text(guidance.text(id))),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: card,
          matching: find.text('Nội dung đang chờ bác sĩ duyệt'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no wording pack hides the new cards', (tester) async {
      ContentPackService.debugFertileGuidance = const FertileGuidance.empty();
      await pumpPlanner(tester);
      expect(
        find.byKey(const ValueKey('fertility-signals-card')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('fertility-doctor-card')), findsNothing);
    });

    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('$mode: Chu kỳ fits 360 dp at 1.5x with Be Vietnam Pro', (
        tester,
      ) async {
        await seedCycles(10);
        await FertilityLogService.setShowIntimacy(true);
        await FertilityLogService.save(
          _log(
            dayAgo(1),
            lh: LhResult.positive,
            mucus: CervicalMucus.eggWhite,
            temperatureC: 36.55,
            intimacy: true,
          ),
        );
        await pumpPlanner(
          tester,
          dark: dark,
          scale: 1.5,
          width: 360,
          height: 7000,
        );
      });

      testWidgets('$mode: log sheet fits 360 dp at 1.5x', (tester) async {
        await FertilityLogService.setShowIntimacy(true);
        await FertilityLogService.save(
          _log(dayAgo(0), lh: LhResult.peak, intimacy: true),
        );
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showFertilityLogSheet(context, DateTime.now()),
                  child: const Text('open'),
                ),
              ),
            ),
            dark: dark,
            scale: 1.5,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final sheet = find.byKey(const ValueKey('fertility-log-sheet'));
        await tester.drag(sheet, const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('fertility-log-delete')),
          findsOneWidget,
        );
      });

      testWidgets('$mode: settings sheet fits 360 dp at 1.5x', (tester) async {
        await FertilityReminderService.update(
          const FertilityReminderSettings(windowEnabled: true),
        );
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showFertilitySettingsSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
            dark: dark,
            scale: 1.5,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('$mode: Hôm nay card with a test fits 360 dp at 1.5x', (
        tester,
      ) async {
        final cycles = await seedCycles(10);
        tester.view.physicalSize = const Size(360, 3600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          app(
            PrePregnancyHomeScreen(
              debugCycles: cycles,
              debugPositiveLhDays: [dayAgo(0)],
            ),
            dark: dark,
            scale: 1.5,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      });

      testWidgets('$mode: card and sheet text meet 4.5:1', (tester) async {
        await seedCycles(10);
        await FertilityLogService.save(
          _log(dayAgo(1), lh: LhResult.negative, temperatureC: 36.5),
        );
        await pumpPlanner(tester, dark: dark);

        void check(Finder root, Color background, ColorScheme scheme) {
          final texts = find.descendant(of: root, matching: find.byType(Text));
          // Buttons and selected chips have their own background.
          final skipped = find.descendant(
            of: root,
            matching: find.descendant(
              of: find.byWidgetPredicate(
                (w) => w is ButtonStyleButton || w is ChoiceChip,
              ),
              matching: find.byType(Text),
            ),
          );
          final skip = tester.widgetList<Text>(skipped).toSet();
          for (final text in tester.widgetList<Text>(texts)) {
            if (skip.contains(text)) continue;
            final data = text.data ?? '';
            if (data == 'Nội dung đang chờ bác sĩ duyệt') continue;
            final effective = DefaultTextStyle.of(
              tester.element(find.byWidget(text)),
            ).style.merge(text.style);
            final color = effective.color ?? scheme.onSurface;
            expect(
              _contrast(color, background),
              greaterThanOrEqualTo(4.5),
              reason: data,
            );
          }
        }

        final card = find.byKey(const ValueKey('fertility-signals-card'));
        final scheme = Theme.of(tester.element(card)).colorScheme;
        check(card, scheme.surfaceContainerLow, scheme);
        check(
          find.byKey(const ValueKey('fertility-doctor-card')),
          scheme.surfaceContainerLow,
          scheme,
        );

        await tester.tap(find.byKey(const ValueKey('fertility-log-open')));
        await tester.pumpAndSettle();
        final sheet = find.byKey(const ValueKey('fertility-log-sheet'));
        check(sheet, scheme.surfaceContainerLow, scheme);

        for (final (key, background) in [
          ('fertility-lh-negative', scheme.secondaryContainer), // selected
          ('fertility-lh-peak', scheme.surfaceContainerLow),
        ]) {
          final label = find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(Text),
          );
          final color = DefaultTextStyle.of(
            tester.element(label),
          ).style.merge(tester.widget<Text>(label).style).color;
          expect(
            _contrast(color!, background),
            greaterThanOrEqualTo(4.5),
            reason: key,
          );
        }
      });

      testWidgets('$mode: new markers stand out from the card', (tester) async {
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) {
                final surface = Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow;
                for (final kind in const [
                  CycleMarkerKind.logged,
                  CycleMarkerKind.intimacy,
                ]) {
                  expect(
                    _contrast(CycleMarkerSpec.of(context, kind).color, surface),
                    greaterThanOrEqualTo(3),
                  );
                }
                return const SizedBox();
              },
            ),
            dark: dark,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    test('no peach or mint in the new UI', () {
      for (final path in [
        'lib/features/fertility/widgets/fertility_log_sheet.dart',
        'lib/features/fertility/widgets/fertility_signals_card.dart',
        'lib/features/fertility/widgets/doctor_visit_card.dart',
      ]) {
        final source = File(path).readAsStringSync().toLowerCase();
        expect(source.contains('peach'), isFalse, reason: path);
        expect(source.contains('mint'), isFalse, reason: path);
      }
    });
  });
}

/// Answers `path_provider` for `Hive.initFlutter`.
class PathProviderMock {
  static const _channel = MethodChannel('plugins.flutter.io/path_provider');

  static void install(String path) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async => path);
  }

  static void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}
