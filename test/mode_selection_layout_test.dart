import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/widgets/brand_mark.dart';
import 'package:momcare/features/onboarding/screens/mode_selection_screen.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final bytes = File(
        'assets/fonts/BeVietnamPro-$weight.ttf',
      ).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('fits 360x640 at text scale $scale and uses the brand mark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const ModeSelectionScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(BrandMark), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Đã mang thai'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Đã mang thai'), findsOneWidget);
    });
  }
}
