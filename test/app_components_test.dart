// Phase 22.4 / 22.9: shared components (AppCard, SectionHeader,
// AppEmptyState) in both themes, with contrast and tap-target guidelines.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/core/widgets/app_card.dart';
import 'package:momcare/core/widgets/empty_state.dart';
import 'package:momcare/core/widgets/section_header.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _app(ThemeData theme, Widget home, {double textScale = 1.0}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

class _ComponentGallery extends StatelessWidget {
  const _ComponentGallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            key: const ValueKey('header'),
            title: 'Lịch hẹn sắp tới',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả'),
            ),
          ),
          for (final variant in AppCardVariant.values)
            AppCard(
              key: ValueKey('card-${variant.name}'),
              variant: variant,
              icon: Icons.favorite,
              title: 'Tiêu đề ${variant.name}',
              trailing: IconButton(
                tooltip: 'Thêm',
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
              onTap: variant == AppCardVariant.alert ? () {} : null,
              child: Text('Nội dung thẻ ${variant.name}'),
            ),
          AppEmptyState(
            key: const ValueKey('empty'),
            icon: Icons.event_available,
            title: 'Chưa có lịch hẹn nào',
            message: 'Thêm lịch hẹn đầu tiên để bắt đầu',
            action: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Thêm lịch hẹn'),
            ),
          ),
          const AppEmptyState.compact(
            icon: Icons.timer_outlined,
            title: 'Chưa có lượt đếm nào.',
          ),
        ],
      ),
    );
  }
}

void main() {
  final themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};

  Color textColor(WidgetTester tester, Finder finder) {
    final style = DefaultTextStyle.of(
      tester.element(finder),
    ).style.merge(tester.widget<Text>(finder).style);
    return style.color!;
  }

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    final s = theme.colorScheme;
    final sem = theme.extension<AppSemanticColors>()!;

    for (final scale in [1.0, 1.5]) {
      testWidgets('components meet text contrast and tap targets '
          '($name, x$scale)', (tester) async {
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1080, 4000);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(theme, const _ComponentGallery(), textScale: scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('AppCard variants use their scheme roles ($name)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(theme, const _ComponentGallery()));
      await tester.pumpAndSettle();
      final expected = {
        AppCardVariant.standard: (s.surfaceContainerLow, s.onSurface),
        AppCardVariant.hero: (s.primaryContainer, s.onPrimaryContainer),
        AppCardVariant.spotlight: (
          sem.spotlightContainer,
          sem.onSpotlightContainer,
        ),
        AppCardVariant.alert: (s.errorContainer, s.onErrorContainer),
        AppCardVariant.notice: (sem.warningContainer, sem.onWarningContainer),
        AppCardVariant.emergency: (sem.emergency, sem.onEmergency),
        AppCardVariant.peach: (sem.peachContainer, sem.onPeachContainer),
        AppCardVariant.mint: (sem.mintContainer, sem.onMintContainer),
      };
      for (final MapEntry(key: variant, value: (bg, fg)) in expected.entries) {
        final card = find.byKey(ValueKey('card-${variant.name}'));
        final material = tester.widget<Card>(
          find.descendant(of: card, matching: find.byType(Card)),
        );
        expect(material.color, bg, reason: variant.name);
        final shape = material.shape ?? theme.cardTheme.shape;
        expect(
          (shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(AppRadius.lg),
        );
        for (final text in [
          'Tiêu đề ${variant.name}',
          'Nội dung thẻ ${variant.name}',
        ]) {
          final color = textColor(tester, find.text(text));
          expect(color, fg, reason: text);
          expect(_contrast(color, bg), greaterThanOrEqualTo(4.5));
        }
        final icon = tester.widget<Icon>(
          find.descendant(of: card, matching: find.byIcon(Icons.favorite)),
        );
        expect(_contrast(icon.color!, bg), greaterThanOrEqualTo(3));
      }
    });

    testWidgets('AppEmptyState and SectionHeader colours ($name)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(theme, const _ComponentGallery()));
      await tester.pumpAndSettle();
      final empty = find.byKey(const ValueKey('empty'));
      final icon = tester.widget<Icon>(
        find.descendant(
          of: empty,
          matching: find.byIcon(Icons.event_available),
        ),
      );
      expect(icon.color, s.onSurfaceVariant);
      expect(
        _contrast(
          textColor(tester, find.text('Chưa có lịch hẹn nào')),
          s.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          textColor(tester, find.text('Thêm lịch hẹn đầu tiên để bắt đầu')),
          s.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(find.text('Thêm lịch hẹn'), findsOneWidget);
      expect(textColor(tester, find.text('Lịch hẹn sắp tới')), s.onSurface);
    });
  }

  testWidgets('AppCard onTap and header layout', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        AppTheme.light(),
        Scaffold(
          body: AppCard(
            title: 'Một tiêu đề rất dài cần xuống dòng khi màn hình hẹp',
            icon: Icons.info_outline,
            onTap: () => taps++,
            child: const Text('Nội dung'),
          ),
        ),
        textScale: 1.5,
      ),
    );
    await tester.tap(find.text('Nội dung'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
