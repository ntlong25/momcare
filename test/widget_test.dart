import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momcare/features/home/screens/main_navigation.dart';
import 'package:momcare/features/onboarding/screens/mode_selection_screen.dart';
import 'package:momcare/features/onboarding/screens/onboarding_screen.dart';
import 'package:momcare/l10n/app_localizations.dart';
import 'package:momcare/main.dart';

void main() {
  Widget testApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('vi')],
        home: child,
      ),
    );
  }

  testWidgets('MomCare app renders splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text('MomCare+'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('Onboarding renders Vietnamese first-run content', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _setPhoneViewport(tester);

    await tester.pumpWidget(testApp(const OnboardingScreen()));

    expect(find.text('Chào mừng đến với MomCare+'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
  });

  testWidgets('Mode selection renders both app modes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _setPhoneViewport(tester);

    await tester.pumpWidget(testApp(const ModeSelectionScreen()));

    expect(find.text('Đang lên kế hoạch mang thai'), findsOneWidget);
    expect(find.text('Đã mang thai'), findsOneWidget);
  });

  testWidgets('Primary navigation renders the five Phase 13 destinations', (
    WidgetTester tester,
  ) async {
    await _setPhoneViewport(tester);

    Future<void> pumpNav({required bool isPrePregnancy}) async {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: mainDestinations(isPrePregnancy: isPrePregnancy),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pumpNav(isPrePregnancy: false);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Tuần thai'), findsOneWidget);
    expect(find.text('Cẩm nang'), findsOneWidget);
    expect(find.text('Công cụ'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Chu kỳ'), findsNothing);

    await pumpNav(isPrePregnancy: true);
    expect(find.text('Chu kỳ'), findsOneWidget);
    expect(find.text('Tuần thai'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1290, 2796);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
