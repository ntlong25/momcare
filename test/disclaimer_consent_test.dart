// P23-R1-09: mandatory disclaimer consent before onboarding.
// Delete-all clearing the acceptance is in p23_r1_regressions_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/core/constants/app_constants.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/features/legal/screens/disclaimer_consent_screen.dart';
import 'package:momcare/features/legal/screens/medical_disclaimer_screen.dart';
import 'package:momcare/features/onboarding/screens/mode_selection_screen.dart';
import 'package:momcare/features/onboarding/screens/onboarding_screen.dart';
import 'package:momcare/l10n/app_localizations.dart';
import 'package:momcare/main.dart';

const _scroll = ValueKey('disclaimer-consent-scroll');
const _accept = ValueKey('disclaimer-accept');

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

void _setView(
  WidgetTester tester, {
  double width = 360,
  double height = 800,
  double textScale = 1.5,
}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _app({bool dark = false, Key? key}) => ProviderScope(
  key: key,
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
    home: const AppInitializer(),
  ),
);

/// The button is on screen and tappable, not just laid out.
Finder _acceptVisible() => find.byKey(_accept).hitTestable();

Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(find.byKey(_scroll), const Offset(0, -5000));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadAppFont);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the same text as the disclaimer screen', (tester) async {
    _setView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
    expect(find.byType(MedicalDisclaimerBody), findsOneWidget);
    expect(find.text('Không chẩn đoán hoặc điều trị'), findsOneWidget);
  });

  testWidgets('"Đồng ý" is hidden until the end of the text', (tester) async {
    _setView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsNothing);

    await tester.drag(find.byKey(_scroll), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsNothing, reason: 'part way is not the end');

    await _scrollToEnd(tester);
    expect(_acceptVisible(), findsOneWidget);
  });

  testWidgets('shown at once when the text fits without scrolling', (
    tester,
  ) async {
    _setView(tester, width: 800, height: 2000, textScale: 1);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsOneWidget);
  });

  testWidgets('re-evaluated when the text scale changes', (tester) async {
    _setView(tester, width: 800, height: 900, textScale: 1);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsOneWidget);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsNothing);

    await _scrollToEnd(tester);
    expect(_acceptVisible(), findsOneWidget);
  });

  testWidgets('re-evaluated when the screen size changes', (tester) async {
    _setView(tester, height: 800);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsNothing);

    tester.view.physicalSize = const Size(360 * 3, 3000 * 3);
    await tester.pumpAndSettle();
    expect(_acceptVisible(), findsOneWidget);
  });

  testWidgets('accepting stores version and date, then onboarding; the next '
      'launch skips the gate', (tester) async {
    _setView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _scrollToEnd(tester);
    await tester.tap(_acceptVisible());
    await tester.pumpAndSettle();

    expect(find.byType(DisclaimerConsentScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt(AppConstants.disclaimerAcceptedVersionKey),
      AppConstants.disclaimerVersion,
    );
    final at = prefs.getString(AppConstants.disclaimerAcceptedAtKey);
    expect(DateTime.tryParse(at ?? ''), isNotNull);

    // A new ProviderScope is a new launch with the same prefs.
    await tester.pumpWidget(_app(key: UniqueKey()));
    await tester.pumpAndSettle();
    expect(find.byType(DisclaimerConsentScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('existing user without acceptance sees it once, then continues '
      'where they were', (tester) async {
    // Mode selection itself overflows at 360 dp x 1.5 (not part of this gate).
    _setView(tester, textScale: 1);
    SharedPreferences.setMockInitialValues({AppConstants.onboardingKey: true});
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
    expect(find.byType(ModeSelectionScreen), findsNothing);

    await _scrollToEnd(tester);
    await tester.tap(_acceptVisible());
    await tester.pumpAndSettle();
    expect(find.byType(ModeSelectionScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('a raised version asks again', (tester) async {
    _setView(tester);
    SharedPreferences.setMockInitialValues({
      AppConstants.disclaimerAcceptedVersionKey:
          AppConstants.disclaimerVersion - 1,
      AppConstants.onboardingKey: true,
    });
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
  });

  testWidgets('the back key cannot leave the screen', (tester) async {
    _setView(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Bỏ qua'), findsNothing);

    // Also after the button is showing, and with a route underneath.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const Text('under')),
      (_) => false,
    );
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const DisclaimerGate(child: Text('app')),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollToEnd(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DisclaimerConsentScreen), findsOneWidget);
    expect(find.text('app'), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets('no overflow at 360 dp x 1.5, dark: $dark', (tester) async {
      _setView(tester);
      await tester.pumpWidget(_app(dark: dark));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Cuộn đến cuối để tiếp tục'), findsOneWidget);

      await _scrollToEnd(tester);
      expect(tester.takeException(), isNull);
      expect(_acceptVisible(), findsOneWidget);
      expect(find.text('Cuộn đến cuối để tiếp tục'), findsNothing);
    });
  }
}
