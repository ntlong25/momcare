import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/data/content_pack_service.dart';
import 'package:momcare/core/data/daily_content_parser.dart';
import 'package:momcare/core/models/contraction.dart';
import 'package:momcare/core/models/daily_item_model.dart';
import 'package:momcare/core/models/kick_session.dart';
import 'package:momcare/core/services/contraction_service.dart';
import 'package:momcare/core/services/kick_counter_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/core/utils/duration_format.dart';
import 'package:momcare/features/emergency/screens/emergency_warning_screen.dart';
import 'package:momcare/features/guides/guide_actions.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:momcare/features/settings/widgets/my_clinic_card.dart';
import 'package:momcare/features/tools/screens/contraction_timer_screen.dart';
import 'package:momcare/features/tools/screens/counter_tools_screen.dart';
import 'package:momcare/features/tools/screens/kick_counter_screen.dart';
import 'package:momcare/features/tools/tool_guidance.dart';
import 'package:momcare/features/tools/widgets/tool_guidance_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 10, 29, 10);

/// [count] completed contractions of [length], one every [every], the last
/// one starting [endingBefore] before [_now].
List<Contraction> _series(
  int count, {
  Duration every = const Duration(minutes: 5),
  Duration length = const Duration(seconds: 60),
  Duration endingBefore = const Duration(minutes: 2),
}) {
  final lastStart = _now.subtract(endingBefore);
  return [
    for (var i = count - 1; i >= 0; i--)
      Contraction(
        startedAt: lastStart.subtract(every * i),
        endedAt: lastStart.subtract(every * i).add(length),
      ),
  ];
}

KickSession _session(
  String id,
  DateTime start, {
  int count = 3,
  Duration length = const Duration(minutes: 20),
  bool active = false,
}) => KickSession(
  id: id,
  startedAt: start,
  endedAt: active ? null : start.add(length),
  count: count,
);

void _setView(WidgetTester tester, Size logical) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = logical * 3;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _app(
  Widget home, {
  double textScale = 1.0,
  DateTime Function()? clock,
  ThemeData? theme,
}) {
  final now = clock ?? () => _now;
  return ProviderScope(
    overrides: [
      kickCounterProvider.overrideWith((ref) => KickCounterNotifier(now: now)),
      contractionProvider.overrideWith((ref) => ContractionNotifier(now: now)),
    ],
    child: MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Replaces the tree so a still-running timer would fail the test.
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  expect(tester.takeException(), isNull);
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final launched = <Uri>[];
  var launchResult = true;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    launched.clear();
    launchResult = true;
    GuideActions.debugLauncher = (uri) async {
      launched.add(uri);
      return launchResult;
    };
  });

  tearDown(() {
    GuideActions.debugLauncher = null;
    ContentPackService.debugDailyTipsPack = const DailyPack.empty(
      DailyPack.dailyTipType,
    );
  });

  group('duration format', () {
    test('formatClock', () {
      expect(formatClock(Duration.zero), '00:00');
      expect(formatClock(const Duration(seconds: 65)), '01:05');
      expect(formatClock(const Duration(seconds: 3723)), '1:02:03');
      expect(formatClock(const Duration(seconds: -5)), '00:00');
    });

    test('formatMinutes', () {
      expect(formatMinutes(const Duration(seconds: 30)), 'dưới 1 phút');
      expect(formatMinutes(const Duration(minutes: 25)), '25 phút');
      expect(formatMinutes(const Duration(minutes: 65)), '1 giờ 5 phút');
      expect(formatMinutes(const Duration(minutes: 120)), '2 giờ');
    });
  });

  group('KickSession', () {
    test('10th kick sets tenthKickAt and undo clears it', () {
      var session = KickSession.start(_now);
      for (var i = 1; i <= 9; i++) {
        session = session.addKick(_now.add(Duration(minutes: i)));
      }
      expect(session.tenthKickAt, isNull);
      final tenth = _now.add(const Duration(minutes: 12));
      session = session.addKick(tenth);
      expect(session.count, 10);
      expect(session.tenthKickAt, tenth);
      expect(session.timeToTen, const Duration(minutes: 12));
      session = session.addKick(_now.add(const Duration(minutes: 13)));
      expect(session.tenthKickAt, tenth, reason: '11th keeps the 10th time');
      session = session.undoKick();
      expect(session.count, 10);
      expect(session.tenthKickAt, tenth);
      session = session.undoKick();
      expect(session.count, 9);
      expect(session.tenthKickAt, isNull);
      expect(session.timeToTen, isNull);
    });

    test('undo at 0 stays 0', () {
      final session = KickSession.start(_now).undoKick();
      expect(session.count, 0);
    });

    test('elapsed uses now while active and endedAt once stopped', () {
      final session = KickSession.start(_now);
      expect(
        session.elapsed(_now.add(const Duration(minutes: 3))),
        const Duration(minutes: 3),
      );
      final stopped = session.stop(_now.add(const Duration(minutes: 5)));
      expect(stopped.isActive, isFalse);
      expect(
        stopped.elapsed(_now.add(const Duration(hours: 4))),
        const Duration(minutes: 5),
      );
    });

    test('JSON round trip and invalid input', () {
      var session = KickSession.start(_now);
      for (var i = 0; i < 10; i++) {
        session = session.addKick(_now.add(Duration(minutes: i + 1)));
      }
      session = session.stop(_now.add(const Duration(minutes: 30)));
      expect(KickSession.fromJson(session.toJson()), session);
      expect(
        KickSession.fromJson(jsonDecode(jsonEncode(session.toJson()))),
        session,
      );
      expect(KickSession.fromJson('x'), isNull);
      expect(KickSession.fromJson({'count': 3}), isNull);
      expect(KickSession.fromJson({'startedAt': 'not a date'}), isNull);
      final partial = KickSession.fromJson({
        'startedAt': _now.toIso8601String(),
        'count': 'many',
      })!;
      expect(partial.count, 0);
      expect(partial.isActive, isTrue);
    });
  });

  group('KickCounterService', () {
    test('corrupt JSON gives [] and entries without startedAt are skipped', () {
      expect(KickCounterService.decode(null), isEmpty);
      expect(KickCounterService.decode('{broken'), isEmpty);
      expect(KickCounterService.decode('{"a":1}'), isEmpty);
      final raw = jsonEncode([
        _session('a', _now).toJson(),
        {'id': 'b', 'count': 4},
        42,
      ]);
      final decoded = KickCounterService.decode(raw);
      expect(decoded.map((s) => s.id), ['a']);
    });

    test('normalize: newest first, one active, newest 100 kept', () {
      final sessions = [
        for (var i = 0; i < 120; i++)
          _session('s$i', _now.subtract(Duration(hours: 120 - i))),
        _session(
          'active-old',
          _now.subtract(const Duration(hours: 1)),
          active: true,
        ),
        _session('active-new', _now, active: true),
      ];
      final result = KickCounterService.normalize(sessions);
      expect(result.first.id, 'active-new');
      expect(result.where((s) => s.isActive), hasLength(1));
      final completed = result.where((s) => !s.isActive).toList();
      expect(completed, hasLength(KickCounterService.maxHistory));
      expect(completed.first.id, 's119');
      expect(completed.last.id, 's20');
    });

    test('notifier flow, start twice, stop at 0, cap, resetLocal', () async {
      var clock = _now;
      final notifier = KickCounterNotifier(now: () => clock);
      addTearDown(notifier.dispose);
      await notifier.ready;

      await notifier.start();
      await notifier.start();
      expect(notifier.state, hasLength(1));
      await notifier.stop();
      expect(notifier.state, isEmpty, reason: 'stop at 0 adds no history');

      await notifier.start();
      await notifier.kick();
      await notifier.kick();
      await notifier.undo();
      expect(notifier.active!.count, 1);
      clock = _now.add(const Duration(minutes: 7));
      await notifier.stop();
      expect(notifier.active, isNull);
      expect(notifier.history.single.count, 1);
      expect(
        notifier.history.single.elapsed(clock),
        const Duration(minutes: 7),
      );

      final prefs = await SharedPreferences.getInstance();
      final stored = KickCounterService.decode(
        prefs.getString(AppConstants.kickSessionsKey),
      );
      expect(stored, notifier.state);

      for (var i = 0; i < 105; i++) {
        clock = clock.add(const Duration(minutes: 1));
        await notifier.start();
        await notifier.kick();
        await notifier.stop();
      }
      expect(notifier.history, hasLength(KickCounterService.maxHistory));
      expect(notifier.history.first.startedAt, clock);

      await notifier.delete(notifier.history.first.id);
      expect(notifier.history, hasLength(KickCounterService.maxHistory - 1));
      await notifier.clearHistory();
      expect(notifier.state, isEmpty);
      expect(prefs.getString(AppConstants.kickSessionsKey), isNull);

      await notifier.start();
      notifier.resetLocal();
      expect(notifier.state, isEmpty);
    });
  });

  group('Contraction', () {
    test('JSON round trip; invalid entries', () {
      final entry = Contraction(
        startedAt: _now,
        endedAt: _now.add(const Duration(seconds: 50)),
      );
      expect(Contraction.fromJson(entry.toJson()), entry);
      expect(entry.duration, const Duration(seconds: 50));
      expect(Contraction.fromJson({'endedAt': _now.toIso8601String()}), isNull);
      expect(
        Contraction.fromJson({
          'startedAt': _now.toIso8601String(),
          'endedAt': _now
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
        }),
        isNull,
        reason: 'an end before the start is invalid',
      );
      final running = Contraction.fromJson({
        'startedAt': _now.toIso8601String(),
      })!;
      expect(running.isActive, isTrue);
      expect(running.duration, isNull);
    });

    test('decode: corrupt gives [], invalid entry skipped, cap 300', () {
      expect(ContractionService.decode('nope'), isEmpty);
      expect(ContractionService.decode('{}'), isEmpty);
      final raw = jsonEncode([
        ..._series(2).map((c) => c.toJson()),
        {'startedAt': 'x'},
        null,
      ]);
      expect(ContractionService.decode(raw), _series(2));

      final many = _series(320, every: const Duration(minutes: 3));
      final capped = ContractionService.normalize(many);
      expect(capped, hasLength(ContractionService.maxEntries));
      expect(capped.last, many.last);
      expect(capped.first, many[20]);
    });

    test('intervalBefore', () {
      final list = _series(3);
      expect(ContractionService.intervalBefore(list, 0), isNull);
      expect(
        ContractionService.intervalBefore(list, 1),
        const Duration(minutes: 5),
      );
      expect(
        ContractionService.intervalBefore(list, 2),
        const Duration(minutes: 5),
      );
    });

    test('matches511 positive and negative cases', () {
      expect(ContractionService.matches511(_series(13)), isTrue);
      expect(
        ContractionService.matches511(
          _series(13, every: const Duration(minutes: 6)),
        ),
        isFalse,
      );
      final oneShort = _series(13);
      oneShort[6] = Contraction(
        startedAt: oneShort[6].startedAt,
        endedAt: oneShort[6].startedAt.add(const Duration(seconds: 40)),
      );
      expect(ContractionService.matches511(oneShort), isFalse);
      expect(
        ContractionService.matches511(_series(11)),
        isFalse,
        reason: '50 min',
      );
      expect(ContractionService.matches511(const []), isFalse);
    });

    test('matches511 ignores a running contraction', () {
      final running = Contraction(startedAt: _now);
      expect(ContractionService.matches511([..._series(13), running]), isTrue);
      expect(ContractionService.matches511([..._series(12), running]), isFalse);
    });

    test('summarize covers the last 60 min only', () {
      final old = Contraction(
        startedAt: _now.subtract(const Duration(minutes: 90)),
        endedAt: _now.subtract(const Duration(minutes: 89)),
      );
      final recent = [
        Contraction(
          startedAt: _now.subtract(const Duration(minutes: 20)),
          endedAt: _now.subtract(const Duration(minutes: 20, seconds: -40)),
        ),
        Contraction(
          startedAt: _now.subtract(const Duration(minutes: 10)),
          endedAt: _now.subtract(const Duration(minutes: 10, seconds: -60)),
        ),
      ];
      final summary = ContractionService.summarize([
        old,
        ...recent,
        Contraction(startedAt: _now),
      ], _now);
      expect(summary.count, 2);
      expect(summary.averageDuration, const Duration(seconds: 50));
      expect(summary.averageInterval, const Duration(minutes: 10));

      final none = ContractionService.summarize([old], _now);
      expect(none.count, 0);
      expect(none.averageDuration, isNull);
    });

    test('notifier toggle, delete, clearHistory, resetLocal', () async {
      var clock = _now;
      final notifier = ContractionNotifier(now: () => clock);
      addTearDown(notifier.dispose);
      await notifier.ready;

      await notifier.toggle();
      expect(notifier.active, isNotNull);
      clock = clock.add(const Duration(seconds: 45));
      await notifier.toggle();
      expect(notifier.active, isNull);
      expect(notifier.state.single.duration, const Duration(seconds: 45));

      final prefs = await SharedPreferences.getInstance();
      expect(
        ContractionService.decode(
          prefs.getString(AppConstants.contractionsKey),
        ),
        notifier.state,
      );

      clock = clock.add(const Duration(minutes: 4));
      await notifier.toggle();
      await notifier.delete(notifier.state.first);
      expect(notifier.state, hasLength(1));
      expect(notifier.active, isNotNull);
      await notifier.toggle();
      await notifier.clearHistory();
      expect(notifier.state, isEmpty);
      expect(prefs.getString(AppConstants.contractionsKey), isNull);

      await notifier.toggle();
      notifier.resetLocal();
      expect(notifier.state, isEmpty);
    });
  });

  group('ToolGuidance', () {
    test('bundled daily_tips.json has all three titles', () {
      final pack = DailyContentParser.parseDailyPack(
        File('assets/content/daily/daily_tips.json').readAsStringSync(),
        expectedType: DailyPack.dailyTipType,
      );
      final titles = pack.items.map((item) => item.title).toSet();
      for (final title in [
        ToolGuidance.kickTitle,
        ToolGuidance.fiveOneOneTitle,
        ToolGuidance.whenToGoTitle,
      ]) {
        expect(titles, contains(title));
      }
      expect(ToolGuidance.kickGuidance(pack), startsWith('Từ tuần 28'));
      expect(ToolGuidance.fiveOneOne(pack), contains('5 phút'));
      expect(ToolGuidance.whenToGo(pack), contains('Đến viện'));
    });

    test('empty pack gives non-empty fallbacks', () {
      const empty = DailyPack.empty(DailyPack.dailyTipType);
      expect(ToolGuidance.kickGuidance(empty), ToolGuidance.kickFallback);
      expect(ToolGuidance.fiveOneOne(empty), ToolGuidance.fiveOneOneFallback);
      expect(ToolGuidance.whenToGo(empty), ToolGuidance.whenToGoFallback);
      for (final text in [
        ToolGuidance.kickFallback,
        ToolGuidance.fiveOneOneFallback,
        ToolGuidance.whenToGoFallback,
      ]) {
        expect(text, isNotEmpty);
      }
    });

    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      testWidgets('guidance card text is readable (${entry.key})', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            const Scaffold(
              body: ToolGuidanceCard(
                title: 'Tiêu đề',
                paragraphs: ['Nội dung'],
              ),
            ),
            theme: entry.value,
          ),
        );
        final background = entry.value.semantic.warningContainer;
        final body = tester.widget<Text>(find.text('Nội dung'));
        expect(
          _contrast(body.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        final disclaimer = tester.widget<Text>(
          find.text(ToolGuidanceCard.disclaimer),
        );
        expect(
          _contrast(
            Color.alphaBlend(disclaimer.style!.color!, background),
            background,
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('KickCounterScreen', () {
    testWidgets('start, kick, undo, stop adds a row', (tester) async {
      _setView(tester, const Size(430, 932));
      var clock = _now;
      await tester.pumpWidget(
        _app(const KickCounterScreen(), clock: () => clock),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có lượt đếm nào.'), findsOneWidget);
      await _tapKey(tester, 'kick-start');
      Text count() =>
          tester.widget<Text>(find.byKey(const ValueKey('kick-count')));
      expect(count().data, '0');

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('kick-tap')));
        await tester.pump();
      }
      expect(count().data, '3');
      await _tapKey(tester, 'kick-undo');
      expect(count().data, '2');

      clock = _now.add(const Duration(minutes: 4));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('04:00'), findsOneWidget);

      await _tapKey(tester, 'kick-stop');
      expect(find.text('2 cử động · 4 phút'), findsOneWidget);
      expect(find.text('Chưa có lượt đếm nào.'), findsNothing);
      expect(find.byKey(const ValueKey('kick-start')), findsOneWidget);
      await _disposeTree(tester);
    });

    testWidgets('10-kick line appears and goes away on undo', (tester) async {
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const KickCounterScreen()));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'kick-start');
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const ValueKey('kick-tap')));
        await tester.pump();
      }
      expect(find.byKey(const ValueKey('kick-ten-line')), findsOneWidget);
      await _tapKey(tester, 'kick-undo');
      expect(find.byKey(const ValueKey('kick-ten-line')), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('stopping at 0 adds no row', (tester) async {
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const KickCounterScreen()));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'kick-start');
      await _tapKey(tester, 'kick-stop');
      expect(find.text('Chưa có lượt đếm nào.'), findsOneWidget);
      expect(find.textContaining('cử động ·'), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('delete after confirmation removes the row', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.kickSessionsKey: KickCounterService.encode([
          _session('a', _now.subtract(const Duration(hours: 2)), count: 7),
        ]),
      });
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const KickCounterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('7 cử động · 20 phút'), findsOneWidget);

      await _tapKey(tester, 'kick-delete-a');
      expect(find.text('Xóa lượt đếm này?'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('7 cử động · 20 phút'), findsOneWidget);

      await _tapKey(tester, 'kick-delete-a');
      await tester.tap(find.byKey(const ValueKey('tool-confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.text('7 cử động · 20 phút'), findsNothing);
      expect(find.text('Chưa có lượt đếm nào.'), findsOneWidget);
    });

    testWidgets('active session in prefs is restored', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.kickSessionsKey: KickCounterService.encode([
          _session(
            'live',
            _now.subtract(const Duration(minutes: 3, seconds: 5)),
            count: 5,
            active: true,
          ),
        ]),
      });
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const KickCounterScreen()));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('kick-count'))).data,
        '5',
      );
      expect(find.text('03:05'), findsOneWidget);
      expect(find.byKey(const ValueKey('kick-start')), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('guidance text and warning link are present', (tester) async {
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const KickCounterScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Khi nào cần đi khám'), findsOneWidget);
      expect(find.text(ToolGuidance.kickFallback), findsOneWidget);
      expect(find.text(ToolGuidanceCard.disclaimer), findsOneWidget);
      await _tapKey(tester, 'tool-guidance-warning-link');
      expect(find.byType(EmergencyWarningScreen), findsOneWidget);
    });

    testWidgets('no normal/abnormal wording', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.kickSessionsKey: KickCounterService.encode([
          _session('a', _now.subtract(const Duration(hours: 2)), count: 12),
        ]),
      });
      _setView(tester, const Size(430, 2000));
      await tester.pumpWidget(_app(const KickCounterScreen()));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'kick-start');
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map(
            (t) => (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase(),
          );
      for (final text in texts) {
        expect(text, isNot(contains('bình thường')));
        expect(text, isNot(contains('bất thường')));
      }
      await _disposeTree(tester);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('fits 360x640 at text scale $scale', (tester) async {
        SharedPreferences.setMockInitialValues({
          AppConstants.kickSessionsKey: KickCounterService.encode([
            _session('a', _now.subtract(const Duration(hours: 2)), count: 12),
          ]),
        });
        _setView(tester, const Size(360, 640));
        await tester.pumpWidget(
          _app(const KickCounterScreen(), textScale: scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _tapKey(tester, 'kick-start');
        await tester.ensureVisible(
          find.byKey(const ValueKey('kick-tap'), skipOffstage: false),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 10; i++) {
          await tester.tap(find.byKey(const ValueKey('kick-tap')));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Xóa lịch sử'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      });
    }

    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      testWidgets('stop button text is >= 4.5:1 (${entry.key})', (
        tester,
      ) async {
        _setView(tester, const Size(430, 932));
        await tester.pumpWidget(
          _app(const KickCounterScreen(), theme: entry.value),
        );
        await tester.pumpAndSettle();
        await _tapKey(tester, 'kick-start');

        final button = find.byKey(const ValueKey('kick-stop'));
        expect(button, findsOneWidget);
        // ButtonStyleButton paints its resolved background and foreground
        // onto the Material it builds.
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)).first,
        );
        final scheme = entry.value.colorScheme;
        final bg = material.color!;
        final fg = material.textStyle!.color!;
        expect(bg, scheme.secondaryContainer);
        expect(fg, scheme.onSecondaryContainer);
        expect(bg.a, 1.0, reason: 'background must be opaque');
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
        await _disposeTree(tester);
      });
    }
  });

  group('ContractionTimerScreen', () {
    String seed(List<Contraction> entries) =>
        ContractionService.encode(entries);

    testWidgets('toggling twice adds one row', (tester) async {
      _setView(tester, const Size(430, 932));
      var clock = _now;
      await tester.pumpWidget(
        _app(const ContractionTimerScreen(), clock: () => clock),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu cơn co'), findsOneWidget);

      await _tapKey(tester, 'contraction-toggle');
      expect(find.text('Kết thúc cơn co'), findsOneWidget);
      clock = _now.add(const Duration(seconds: 25));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:25'), findsOneWidget);

      await _tapKey(tester, 'contraction-toggle');
      expect(find.text('Bắt đầu cơn co'), findsOneWidget);
      expect(find.text('Dài 00:25 · Cách —'), findsOneWidget);
      expect(find.text('Từ cơn trước'), findsOneWidget);
      expect(find.textContaining('1 cơn trong 1 giờ qua'), findsOneWidget);
      expect(find.byKey(const ValueKey('contraction-511-hint')), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('5-min fixture shows the hint and Gọi 115 dials', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.contractionsKey: seed(_series(13)),
      });
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const ContractionTimerScreen()));
      await tester.pumpAndSettle();

      final hint = find.byKey(const ValueKey('contraction-511-hint'));
      expect(hint, findsOneWidget);
      expect(find.byType(MyClinicCard), findsOneWidget);
      final hintText = tester
          .widgetList<Text>(
            find.descendant(of: hint, matching: find.byType(Text)),
          )
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      for (final banned in ['chuyển dạ', 'sắp sinh', 'bình thường']) {
        expect(hintText, isNot(contains(banned)));
      }

      final callMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const ValueKey('contraction-call-115')),
              matching: find.byType(Material),
            )
            .first,
      );
      final semantic = tester.element(hint).semantic;
      expect(callMaterial.color, semantic.emergency);
      expect(callMaterial.textStyle!.color, semantic.onEmergency);

      await _tapKey(tester, 'contraction-call-115');
      expect(launched.single.toString(), 'tel:115');
      expect(find.text('Không mở được ứng dụng phù hợp'), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('failing launcher shows the snackbar', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.contractionsKey: seed(_series(13)),
      });
      launchResult = false;
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const ContractionTimerScreen()));
      await tester.pumpAndSettle();
      await _tapKey(tester, 'contraction-call-115');
      expect(find.text('Không mở được ứng dụng phù hợp'), findsOneWidget);
      await _disposeTree(tester);
    });

    testWidgets('7-min fixture shows no hint', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.contractionsKey: seed(
          _series(13, every: const Duration(minutes: 7)),
        ),
      });
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const ContractionTimerScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('contraction-511-hint')), findsNothing);
      expect(find.textContaining('Cách 07:00'), findsWidgets);
      await _disposeTree(tester);
    });

    testWidgets('guidance shows 5-1-1, when-to-go and under-37 text', (
      tester,
    ) async {
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(const ContractionTimerScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Khi nào cần đến viện'), findsOneWidget);
      expect(find.text(ToolGuidance.fiveOneOneFallback), findsOneWidget);
      expect(find.text(ToolGuidance.whenToGoFallback), findsOneWidget);
      expect(find.text(ToolGuidance.under37Weeks), findsOneWidget);
      expect(find.text('Chưa có cơn co nào được ghi.'), findsOneWidget);
    });

    testWidgets('delete and clear history', (tester) async {
      final entries = _series(3, every: const Duration(minutes: 8));
      SharedPreferences.setMockInitialValues({
        AppConstants.contractionsKey: seed(entries),
      });
      _setView(tester, const Size(430, 1400));
      await tester.pumpWidget(_app(const ContractionTimerScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dài 01:00'), findsNWidgets(3));

      await _tapKey(
        tester,
        'contraction-delete-${entries.last.startedAt.toIso8601String()}',
      );
      await tester.tap(find.byKey(const ValueKey('tool-confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dài 01:00'), findsNWidgets(2));

      await _tapKey(tester, 'contraction-clear');
      await tester.tap(find.byKey(const ValueKey('tool-confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dài 01:00'), findsNothing);
      expect(find.text('Chưa có cơn co nào được ghi.'), findsOneWidget);
      await _disposeTree(tester);
    });

    testWidgets('running contraction in prefs is restored', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.contractionsKey: seed([
          Contraction(startedAt: _now.subtract(const Duration(seconds: 42))),
        ]),
      });
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const ContractionTimerScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Kết thúc cơn co'), findsOneWidget);
      expect(find.text('00:42'), findsOneWidget);
      await _disposeTree(tester);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets('fits 360x640 at text scale $scale', (tester) async {
        SharedPreferences.setMockInitialValues({
          AppConstants.contractionsKey: seed(_series(13)),
        });
        _setView(tester, const Size(360, 640));
        await tester.pumpWidget(
          _app(const ContractionTimerScreen(), textScale: scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Xóa lịch sử'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      });
    }
  });

  group('CounterToolsScreen', () {
    testWidgets('cards render and push their screens', (tester) async {
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const Scaffold(body: CounterToolsScreen())));
      await tester.pumpAndSettle();
      expect(find.text('Đếm cử động thai'), findsOneWidget);
      expect(
        find.text('Thường bắt đầu theo dõi từ khoảng tuần 28'),
        findsOneWidget,
      );
      expect(find.text('Đếm cơn co'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tools-kick')));
      await tester.pumpAndSettle();
      expect(find.byType(KickCounterScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tools-contraction')));
      await tester.pumpAndSettle();
      expect(find.byType(ContractionTimerScreen), findsOneWidget);
      await _disposeTree(tester);
    });

    testWidgets('subtitles show the last session and running state', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.kickSessionsKey: KickCounterService.encode([
          _session('a', _now.subtract(const Duration(hours: 2)), count: 9),
        ]),
        AppConstants.contractionsKey: ContractionService.encode([
          Contraction(startedAt: _now),
        ]),
      });
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const Scaffold(body: CounterToolsScreen())));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lần gần nhất: 9 cử động'), findsOneWidget);
      expect(find.text('Đang ghi một cơn co'), findsOneWidget);
    });

    test('mainDestinations is unchanged', () {
      for (final pre in [true, false]) {
        final labels = mainDestinations(
          isPrePregnancy: pre,
        ).map((d) => d.label).toList();
        expect(labels, [
          'Hôm nay',
          pre ? 'Chu kỳ' : 'Tuần thai',
          'Cẩm nang',
          'Công cụ',
          'Cài đặt',
        ]);
      }
    });
  });

  group('EmergencyWarningScreen 115', () {
    testWidgets('button sits above "Trong thai kỳ" and dials 115', (
      tester,
    ) async {
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const EmergencyWarningScreen()));
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('emergency-call-115'));
      expect(button, findsOneWidget);
      expect(find.text('Gọi 115 (cấp cứu)'), findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(56));
      expect(
        tester.getRect(button).bottom,
        lessThan(tester.getRect(find.text('Trong thai kỳ')).top),
      );
      expect(
        tester.getRect(button).top,
        greaterThan(
          tester
              .getRect(find.text('Đừng chờ nếu có dấu hiệu bất thường'))
              .bottom,
        ),
      );
      await tester.tap(button);
      await tester.pump();
      expect(launched.map((u) => u.toString()), ['tel:115']);

      await tester.scrollUntilVisible(
        find.textContaining('hãy gọi 115 hoặc số cấp cứu tại địa phương'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    });

    testWidgets('failing launcher shows the snackbar', (tester) async {
      launchResult = false;
      _setView(tester, const Size(430, 932));
      await tester.pumpWidget(_app(const EmergencyWarningScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('emergency-call-115')));
      await tester.pumpAndSettle();
      expect(find.text('Không mở được ứng dụng phù hợp'), findsOneWidget);
    });

    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      testWidgets('115 button text is >= 4.5:1 (${entry.key})', (tester) async {
        await tester.pumpWidget(
          _app(const EmergencyWarningScreen(), theme: entry.value),
        );
        await tester.pumpAndSettle();
        final material = tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(const ValueKey('emergency-call-115')),
                matching: find.byType(Material),
              )
              .first,
        );
        final bg = material.color!;
        final fg = material.textStyle!.color!;
        expect(bg.a, 1.0);
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
      });
    }

    testWidgets('fits 360x640 at text scale 1.5', (tester) async {
      _setView(tester, const Size(360, 640));
      await tester.pumpWidget(
        _app(const EmergencyWarningScreen(), textScale: 1.5),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('emergency-call-115')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 22.2c counter button styles', () {
    Material buttonMaterial(WidgetTester tester, String key) =>
        tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(ValueKey(key)),
                matching: find.byType(Material),
              )
              .first,
        );

    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      final scheme = entry.value.colorScheme;

      testWidgets('"Bắt đầu đếm" and "Bắt đầu cơn co" share one filled '
          'style (${entry.key})', (tester) async {
        _setView(tester, const Size(430, 932));
        await tester.pumpWidget(
          _app(const KickCounterScreen(), theme: entry.value),
        );
        await tester.pumpAndSettle();
        final kick = buttonMaterial(tester, 'kick-start');
        final kickHeight = tester
            .getSize(find.byKey(const ValueKey('kick-start')))
            .height;
        await _disposeTree(tester);

        await tester.pumpWidget(
          _app(const ContractionTimerScreen(), theme: entry.value),
        );
        await tester.pumpAndSettle();
        final contraction = buttonMaterial(tester, 'contraction-toggle');
        final contractionHeight = tester
            .getSize(find.byKey(const ValueKey('contraction-toggle')))
            .height;

        expect(kick.color, scheme.primary);
        expect(contraction.color, kick.color);
        expect(contraction.textStyle!.color, kick.textStyle!.color);
        expect(contraction.textStyle!.fontSize, kick.textStyle!.fontSize);
        expect(contraction.textStyle!.fontWeight, kick.textStyle!.fontWeight);
        expect(contraction.shape, kick.shape);
        expect(contractionHeight, kickHeight);
        expect(
          _contrast(kick.textStyle!.color!, kick.color!),
          greaterThanOrEqualTo(4.5),
        );

        // Active "Kết thúc cơn co" uses the danger (error) roles.
        await _tapKey(tester, 'contraction-toggle');
        final active = buttonMaterial(tester, 'contraction-toggle');
        expect(active.color, scheme.error);
        expect(active.textStyle!.color, scheme.onError);
        await _disposeTree(tester);
      });

      testWidgets('"Hoàn tác" and "Kết thúc" have the same height '
          '(${entry.key})', (tester) async {
        _setView(tester, const Size(430, 932));
        await tester.pumpWidget(
          _app(const KickCounterScreen(), theme: entry.value),
        );
        await tester.pumpAndSettle();
        await _tapKey(tester, 'kick-start');
        for (final scale in [1.0, 1.5]) {
          if (scale != 1.0) {
            await tester.pumpWidget(
              _app(
                const KickCounterScreen(),
                theme: entry.value,
                textScale: scale,
              ),
            );
            await tester.pumpAndSettle();
          }
          final undo = tester.getSize(find.byKey(const ValueKey('kick-undo')));
          final stop = tester.getSize(find.byKey(const ValueKey('kick-stop')));
          expect(undo.height, stop.height, reason: 'x$scale');
          expect(undo.height, greaterThanOrEqualTo(48));
        }
        await _disposeTree(tester);
      });
    }
  });
}
