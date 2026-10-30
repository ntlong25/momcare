// P22-R1-02: the in-app splash shows the launcher-icon brand mark at the
// same size and position as the Android 12 system splash icon (160 dp
// circle centred on the screen), not a generic heart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/core/widgets/brand_mark.dart';
import 'package:momcare/features/splash/screens/splash_screen.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('splash brand mark matches the system splash icon '
        '(dark: $dark)', (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: const SplashScreen(nextScreen: Scaffold(body: Text('next'))),
        ),
      );
      await tester.pump();

      final mark = find.byKey(const ValueKey('splash-brand-mark'));
      expect(mark, findsOneWidget);
      expect(tester.widget(mark), isA<BrandMark>());
      final rect = tester.getRect(mark);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      // 160 dp, centred on the full screen, full size from the first frame.
      expect(rect.width, closeTo(160, 0.01));
      expect(rect.height, closeTo(160, 0.01));
      expect(rect.center.dx, closeTo(screen.width / 2, 0.5));
      expect(rect.center.dy, closeTo(screen.height / 2, 0.5));
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(
        find.descendant(of: mark, matching: find.byType(ScaleTransition)),
        findsNothing,
      );

      // Title and tagline sit below the mark without overlapping it.
      final title = tester.getRect(find.text('MomCare+'));
      expect(title.top, greaterThan(rect.bottom));
      expect(find.text('Người bạn đồng hành thai kỳ'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Let the splash timer navigate on.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });
  }

  test('brand mark uses the launcher icon colours and SVG geometry', () {
    // Plum adaptive-icon background (flutter_launcher_icons.yaml).
    expect(AppBrandColors.primary, const Color(0xFF894A68));
    expect(
      File('flutter_launcher_icons.yaml').readAsStringSync(),
      contains('adaptive_icon_background: "#894A68"'),
    );
    expect(AppBrandColors.onPrimary, const Color(0xFFFFFFFF));
    // BrandMarkPainter copies these from the SVG master; fail if it moves.
    final svg = File(
      'assets/branding/app_icon_foreground.svg',
    ).readAsStringSync();
    expect(svg, contains('viewBox="0 0 432 432"'));
    expect(svg, contains('translate(83.4 78.2) scale(2.6)'));
    expect(
      svg,
      contains(
        'M50 34 C53 26 60 21 69 21 C80 21 88 29 88 40 C88 56 74 70 50 85 '
        'C30 73 17 61 15 46',
      ),
    );
    expect(svg, contains('stroke-width="8"'));
    expect(svg, contains('<circle cx="31" cy="28" r="12"'));
    expect(svg, contains('<circle cx="46" cy="61" r="9.5"'));
  });
}
