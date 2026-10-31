// P22-R1-01: Chu kỳ calendar markers (period / ovulation / fertile /
// predicted period) differ by shape and by clearly different colours in
// both themes, and the legend uses the same markers.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/models/menstrual_cycle_model.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/features/fertility/screens/fertility_planner_screen.dart';
import 'package:momcare/features/fertility/widgets/cycle_marker.dart';
import 'package:momcare/l10n/app_localizations.dart';

/// CIE L*a*b* (D65) of an sRGB colour.
List<double> _lab(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) => t > 216 / 24389
      ? math.pow(t, 1 / 3).toDouble()
      : (24389 / 27 * t + 16) / 116;
  final fx = f(x), fy = f(y), fz = f(z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

/// CIE76 colour difference.
double _deltaE(Color a, Color b) {
  final la = _lab(a), lb = _lab(b);
  return math.sqrt(
    math.pow(la[0] - lb[0], 2) +
        math.pow(la[1] - lb[1], 2) +
        math.pow(la[2] - lb[2], 2),
  );
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Widget _app(Widget home, {required bool dark}) => ProviderScope(
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
  setUpAll(_loadAppFont);

  test('deltaE helper sanity', () {
    expect(
      _deltaE(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(100, 0.01),
    );
    expect(
      _deltaE(const Color(0xFF123456), const Color(0xFF123456)),
      closeTo(0, 1e-9),
    );
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('$mode: every marker kind has its own shape and the colours '
        'are far apart (deltaE >= 20)', (tester) async {
      late Map<CycleMarkerKind, CycleMarkerSpec> specs;
      late ColorScheme scheme;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              specs = {
                for (final k in CycleMarkerKind.values)
                  k: CycleMarkerSpec.of(context, k),
              };
              return const SizedBox();
            },
          ),
          dark: dark,
        ),
      );

      // Shapes: all different, so colour is never the only cue.
      final shapes = specs.values.map((s) => s.shape).toSet();
      expect(shapes, hasLength(CycleMarkerKind.values.length));
      expect(specs[CycleMarkerKind.period]!.shape, CycleMarkerShape.filledDot);
      expect(
        specs[CycleMarkerKind.predictedPeriod]!.shape,
        CycleMarkerShape.dashedRing,
        reason: 'predicted period is hollow, the real period is filled',
      );

      // Colours: every pair except period / predicted period (same meaning,
      // told apart by filled vs hollow) differs by deltaE >= 20.
      const sameMeaning = {
        CycleMarkerKind.period,
        CycleMarkerKind.predictedPeriod,
      };
      final kinds = CycleMarkerKind.values;
      for (var i = 0; i < kinds.length; i++) {
        for (var j = i + 1; j < kinds.length; j++) {
          if (sameMeaning.contains(kinds[i]) &&
              sameMeaning.contains(kinds[j])) {
            continue;
          }
          final d = _deltaE(specs[kinds[i]]!.color, specs[kinds[j]]!.color);
          expect(
            d,
            greaterThanOrEqualTo(20),
            reason: '${kinds[i].name} vs ${kinds[j].name}: deltaE $d',
          );
        }
      }

      // Each marker stands out from the card surface (non-text 3:1).
      for (final spec in specs.values) {
        expect(
          _contrast(spec.color, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(3),
          reason: '${spec.kind.name} on surface',
        );
      }
    });

    testWidgets('$mode: legend shows the same markers as the calendar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(body: CycleMarkerLegend(showIntimacy: true)),
          dark: dark,
        ),
      );
      for (final kind in CycleMarkerKind.values) {
        final item = find.byKey(ValueKey('cycle-legend-${kind.name}'));
        expect(item, findsOneWidget);
        final marker = tester.widget<CycleMarker>(
          find.descendant(of: item, matching: find.byType(CycleMarker)),
        );
        expect(marker.kind, kind);
      }
      expect(find.text('Kỳ kinh'), findsOneWidget);
      expect(find.text('Rụng trứng'), findsOneWidget);
      expect(find.text('Dễ thụ thai'), findsOneWidget);
      expect(find.text('Kỳ kinh dự kiến'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  group('planner calendar', () {
    late Directory hiveDir;

    setUpAll(() async {
      hiveDir = await Directory.systemTemp.createTemp('momcare_markers');
      Hive.init(hiveDir.path);
      if (!Hive.isAdapterRegistered(MenstrualCycleModelAdapter().typeId)) {
        Hive.registerAdapter(MenstrualCycleModelAdapter());
      }
      final box = await Hive.openBox<MenstrualCycleModel>(
        AppConstants.menstrualCycleBox,
      );
      final now = DateTime.now();
      final cycle = MenstrualCycleModel(
        id: 'c1',
        startDate: DateTime(now.year, now.month, now.day),
        createdAt: now,
        updatedAt: now,
      );
      await box.put(cycle.id, cycle);
    });

    tearDownAll(() async {
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    testWidgets('day markers are CycleMarkers (period shown as filled dot)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(412 * 3, 915 * 3);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_app(const FertilityPlannerScreen(), dark: true));
      await tester.pumpAndSettle();
      final calendar = find.byWidgetPredicate((w) => w is TableCalendar);
      expect(calendar, findsOneWidget);
      final inCalendar = find.descendant(
        of: calendar,
        matching: find.byType(CycleMarker),
      );
      expect(inCalendar, findsWidgets);
      expect(find.byKey(const ValueKey('cycle-marker-period')), findsWidgets);
      // No plain dot containers are left in the calendar.
      final circles = find.descendant(
        of: calendar,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              w.constraints?.maxWidth == 7,
        ),
      );
      expect(circles, findsNothing);
    });
  });
}
