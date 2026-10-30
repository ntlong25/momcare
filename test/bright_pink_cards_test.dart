import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momcare/core/models/daily_item_model.dart';
import 'package:momcare/core/models/guide_models.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/features/guides/guide_actions.dart';
import 'package:momcare/features/guides/screens/guide_detail_screen.dart';
import 'package:momcare/features/home/widgets/today_thai_giao_card.dart';
import 'package:momcare/features/home/widgets/today_tip_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Peach is the thai giáo card, mint the daily tip card; both keep their
/// text readable in each theme.
void main() {
  const pack = DailyPack(
    type: DailyPack.thaiGiaoType,
    items: [
      DailyItem(
        day: 1,
        week: 1,
        category: 'talk',
        title: 'Trò chuyện cùng bé',
        body: 'Dành vài phút nói chuyện nhẹ nhàng với bé.',
        durationMin: 5,
      ),
    ],
  );

  Widget app(ThemeData theme, Widget child) => ProviderScope(
    child: MaterialApp(
      theme: theme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  Color cardColor(WidgetTester tester, Type type) => tester
      .widget<Card>(
        find.descendant(of: find.byType(type), matching: find.byType(Card)),
      )
      .color!;

  for (final MapEntry(key: name, value: theme) in {
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    final sem = theme.extension<AppSemanticColors>()!;

    testWidgets('thai giáo card is peach ($name)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(theme, const TodayThaiGiaoCard(day: 1, pack: pack)),
      );
      await tester.pumpAndSettle();
      expect(cardColor(tester, TodayThaiGiaoCard), sem.peachContainer);
      expect(
        tester.widget<Text>(find.text('Thai giáo hôm nay')).style!.color,
        sem.onPeachContainer,
      );
      expect(
        tester.widget<Text>(find.text('Trò chuyện cùng bé')).style!.color,
        sem.onPeachContainer,
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('daily tip card is mint ($name)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(theme, const TodayTipCard(day: 1, pack: pack)),
      );
      await tester.pumpAndSettle();
      expect(cardColor(tester, TodayTipCard), sem.mintContainer);
      expect(
        tester.widget<Text>(find.text('Trò chuyện cùng bé')).style!.color,
        sem.onMintContainer,
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  for (final MapEntry(key: name, value: theme) in {
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    testWidgets('guide "Gọi 115" action is solid emergency ($name)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const guide = GuideArticle(
        id: 'pregnant_warning_signs',
        stage: GuideStage.pregnant,
        category: GuideCategory.warning,
        title: 'Dấu hiệu nguy hiểm cần đi khám ngay',
        checklist: [
          GuideChecklistItem(
            id: 'w_call',
            text: 'Gọi cấp cứu khi cần',
            actionType: GuideActionType.call,
            actionLabel: 'Gọi 115',
            actionValue: '115',
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: const GuideDetailScreen(guide: guide, sources: {}),
          ),
        ),
      );
      await tester.pump();
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const ValueKey('guide-call-115')),
              matching: find.byType(Material),
            )
            .first,
      );
      final sem = theme.extension<AppSemanticColors>()!;
      expect(material.color, sem.emergency);
      expect(material.textStyle!.color, sem.onEmergency);
      expect(
        find.byIcon(GuideActions.icon(GuideActionType.call)),
        findsOneWidget,
      );
    });
  }

  // THEME-R1-02: the seed's tertiary container looks like the peach card.
  test('peach-like tertiary fills are gone from the feature code', () {
    final tone = RegExp(r'tertiaryContainer|AppTone\.tertiary');
    final hits = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll('\\', '/');
      if (path.startsWith('lib/core/theme/')) continue;
      // Mood pie slices use the tertiary main colour, not a peach fill.
      if (path.endsWith('health_charts_card.dart')) continue;
      if (tone.hasMatch(file.readAsStringSync())) hits.add(path);
    }
    expect(hits, isEmpty);
  });

  test('only the 115 call counts as an emergency action', () {
    expect(
      GuideActions.isEmergencyCall(GuideActionType.call, '115'),
      isTrue,
      reason: 'the 115 guide action gets the solid emergency button',
    );
    expect(
      GuideActions.isEmergencyCall(GuideActionType.call, '02838295723'),
      isFalse,
    );
    expect(GuideActions.isEmergencyCall(GuideActionType.none, '115'), isFalse);
  });
}
