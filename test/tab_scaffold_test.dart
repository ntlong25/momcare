// Phase 22.6: per-tab scrolling (P20-R2-02) and tab labels at font scale
// 1.5 (P18-R2-01).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/services/contraction_service.dart';
import 'package:momcare/core/services/kick_counter_service.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/features/home/screens/main_navigation.dart';

final _now = DateTime(2026, 10, 29, 10);

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

Widget _app(Widget home, {double textScale = 1.0, ThemeData? theme}) {
  return ProviderScope(
    overrides: [
      kickCounterProvider.overrideWith(
        (ref) => KickCounterNotifier(now: () => _now),
      ),
      contractionProvider.overrideWith(
        (ref) => ContractionNotifier(now: () => _now),
      ),
    ],
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
}

TabbedPage _filler(String id, String label, IconData icon) => TabbedPage(
  id: id,
  label: label,
  icon: icon,
  child: ListView(
    children: [for (var i = 0; i < 40; i++) ListTile(title: Text('$label $i'))],
  ),
);

/// The Công cụ tabs in pregnancy mode: two filler pages plus the real
/// "Bộ đếm" and "Cần khám" pages.
final List<TabbedPage> _toolPages = [
  _filler('nutrition', 'Dinh dưỡng', Icons.restaurant_menu),
  _filler('appointments', 'Lịch hẹn', Icons.calendar_today),
  toolsCounterPage,
  toolsEmergencyPage,
];

Finder _pageScrollable(String id) => find
    .descendant(
      of: find.byKey(PageStorageKey<String>('tab-page-$id')),
      matching: find.byType(Scrollable),
    )
    .first;

double _offset(WidgetTester tester, String id) =>
    tester.state<ScrollableState>(_pageScrollable(id)).position.pixels;

/// True when [finder]'s paragraph shows its whole text on one line.
bool _fullyVisibleOneLine(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: TextDirection.ltr,
    textScaler: paragraph.textScaler,
  )..layout();
  final fits = painter.width <= paragraph.size.width + 0.5;
  final oneLine = paragraph.size.height <= painter.height + 0.5;
  painter.dispose();
  return fits && oneLine && !paragraph.didExceedMaxLines;
}

void main() {
  setUpAll(_loadAppFont);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('each tab keeps its own scroll offset (P20-R2-02)', (
    tester,
  ) async {
    _setView(tester);
    await tester.pumpWidget(
      _app(TabbedScaffold(title: 'Công cụ', pages: _toolPages)),
    );
    await tester.pumpAndSettle();

    // Scroll "Cần khám" to the bottom.
    await tester.tap(find.byKey(const ValueKey('tab-emergency')));
    await tester.pumpAndSettle();
    await tester.drag(_pageScrollable('emergency'), const Offset(0, -5000));
    await tester.pumpAndSettle();
    final emergencyOffset = _offset(tester, 'emergency');
    expect(emergencyOffset, greaterThan(0));

    // "Bộ đếm" opens at the top with its first card on screen.
    await tester.tap(find.byKey(const ValueKey('tab-counters')));
    await tester.pumpAndSettle();
    expect(_offset(tester, 'counters'), 0);
    final kick = find.byKey(const ValueKey('tools-kick'));
    expect(kick.hitTestable(), findsOneWidget);
    final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
    expect(tester.getTopLeft(kick).dy, lessThan(appBarBottom + 40));

    // Back on "Cần khám", the previous offset is restored.
    await tester.tap(find.byKey(const ValueKey('tab-emergency')));
    await tester.pumpAndSettle();
    expect(_offset(tester, 'emergency'), emergencyOffset);
  });

  testWidgets('tab bar is scrollable, start-aligned and in the AppBar', (
    tester,
  ) async {
    _setView(tester);
    await tester.pumpWidget(
      _app(TabbedScaffold(title: 'Công cụ', pages: _toolPages)),
    );
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isTrue);
    expect(tabBar.tabAlignment, TabAlignment.start);
    expect(
      tester.getSize(find.byKey(const ValueKey('tab-emergency'))).height,
      lessThanOrEqualTo(72),
    );
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byType(TabBar)),
      findsOneWidget,
    );
    expect(find.byType(NestedScrollView), findsNothing);
  });

  for (final pages in {
    'Công cụ': _toolPages,
    'Tuần thai': [
      _filler('pregnancy', 'Thai kỳ', Icons.track_changes),
      _filler('health', 'Sức khỏe', Icons.favorite),
    ],
  }.entries) {
    testWidgets('${pages.key} tab labels are fully visible at x1.5', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(
        _app(
          TabbedScaffold(title: pages.key, pages: pages.value),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final tabBar = find.byType(TabBar);
      for (final page in pages.value) {
        final label = find.descendant(
          of: tabBar,
          matching: find.text(page.label),
        );
        expect(label, findsOneWidget, reason: page.label);
        if (label.hitTestable().evaluate().isEmpty) {
          await tester.dragUntilVisible(label, tabBar, const Offset(-100, 0));
          await tester.pumpAndSettle();
        }
        expect(_fullyVisibleOneLine(tester, label), isTrue, reason: page.label);
      }
    });
  }

  for (final width in [360.0, 412.0]) {
    testWidgets('bottom navigation labels stay on one line at x1.5 '
        '(${width.toInt()} dp)', (tester) async {
      _setView(tester, width: width);
      await tester.pumpWidget(
        _app(
          Scaffold(
            bottomNavigationBar: SingleLineNavigationLabels(
              child: NavigationBar(
                selectedIndex: 2,
                destinations: mainDestinations(isPrePregnancy: false),
              ),
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Hôm nay',
        'Tuần thai',
        'Cẩm nang',
        'Công cụ',
        'Cài đặt',
      ]) {
        final text = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        );
        expect(_fullyVisibleOneLine(tester, text), isTrue, reason: label);
        if (width >= 412) {
          // Wide phones keep enlarged labels.
          final scale = tester
              .renderObject<RenderParagraph>(text)
              .textScaler
              .scale(10);
          expect(scale, greaterThan(10), reason: label);
        }
      }
    });
  }
}
