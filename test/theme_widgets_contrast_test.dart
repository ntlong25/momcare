import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momcare/core/models/food_model.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/theme/app_tokens.dart';
import 'package:momcare/features/emergency/screens/emergency_warning_screen.dart';
import 'package:momcare/features/emergency/widgets/emergency_entry_card.dart';
import 'package:momcare/features/nutrition/widgets/food_verdict_badge.dart';
import 'package:momcare/features/references/widgets/draft_content_note.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hôm nay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Lưu')),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('Kết thúc'),
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Hoàn tác')),
              TextButton(onPressed: () {}, child: const Text('Hủy')),
              ElevatedButton(onPressed: () {}, child: const Text('Thêm')),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('30 ngày qua'),
                selected: true,
                onSelected: (_) {},
              ),
              ChoiceChip(
                label: const Text('Tùy chọn'),
                selected: false,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('Đã làm'),
                selected: true,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('Mệt mỏi'),
                selected: false,
                onSelected: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thai giáo hôm nay', style: text.titleMedium),
                  Text('Nội dung', style: text.bodyMedium),
                  Text(
                    'Ghi chú',
                    style: text.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 72, child: TabBarDemo()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Hôm nay'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Cẩm nang'),
        ],
      ),
    );
  }
}

/// Status widgets migrated in Phase 22.2: food verdict badges, the draft
/// content note and the red-tinted emergency entry card.
class _StatusGallery extends StatelessWidget {
  const _StatusGallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final verdict in FoodVerdict.values)
                FoodVerdictBadge(verdict: verdict),
            ],
          ),
          const SizedBox(height: 16),
          const DraftContentNote(),
          const SizedBox(height: 16),
          const EmergencyEntryCard(),
        ],
      ),
    );
  }
}

class TabBarDemo extends StatelessWidget {
  const TabBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: TabBar(
        tabs: [
          Tab(text: 'Bộ đếm'),
          Tab(text: 'Cần khám'),
        ],
      ),
    );
  }
}

void main() {
  final themes = {'light': AppTheme.light(), 'dark': AppTheme.dark()};

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('gallery meets text contrast and tap targets '
          '($name, x$scale)', (tester) async {
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(theme, const _Gallery(), textScale: scale),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('button foregrounds are >= 4.5:1 ($name)', (tester) async {
      await tester.pumpWidget(_app(theme, const _Gallery()));
      await tester.pumpAndSettle();
      final page = theme.colorScheme.surface;
      for (final type in [
        FilledButton,
        OutlinedButton,
        TextButton,
        ElevatedButton,
      ]) {
        for (final element in find.byType(type).evaluate()) {
          final material = tester.widget<Material>(
            find
                .descendant(
                  of: find.byWidget(element.widget),
                  matching: find.byType(Material),
                )
                .first,
          );
          final bg = material.type == MaterialType.transparency
              ? page
              : Color.alphaBlend(material.color ?? page, page);
          final fg = material.textStyle!.color!;
          expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$type');
        }
      }
      // Outlined button border is a control boundary: >= 3:1.
      final outline = theme.outlinedButtonTheme.style!.side!.resolve({})!;
      expect(_contrast(outline.color, page), greaterThanOrEqualTo(3.0));
    });

    testWidgets('chip labels are >= 4.5:1 selected and unselected ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(_app(theme, const _Gallery()));
      await tester.pumpAndSettle();
      final page = theme.colorScheme.surface;
      for (final label in ['30 ngày qua', 'Tùy chọn', 'Đã làm', 'Mệt mỏi']) {
        final textFinder = find.text(label);
        final style = DefaultTextStyle.of(
          tester.element(textFinder),
        ).style.merge(tester.widget<Text>(textFinder).style);
        final selected = label == '30 ngày qua' || label == 'Đã làm';
        final bg = selected ? theme.chipTheme.selectedColor! : page;
        expect(
          _contrast(style.color!, bg),
          greaterThanOrEqualTo(4.5),
          reason: label,
        );
      }
    });

    testWidgets('snackbar text and action are readable ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          theme,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã lưu'),
                    action: SnackBarAction(label: 'Hoàn tác', onPressed: () {}),
                  ),
                ),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      final s = theme.colorScheme;
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, s.inverseSurface);
      final content = DefaultTextStyle.of(tester.element(find.text('Đã lưu')));
      expect(
        _contrast(content.style.color!, s.inverseSurface),
        greaterThanOrEqualTo(4.5),
      );
      final action = DefaultTextStyle.of(
        tester.element(find.text('Hoàn tác')),
      ).style.merge(tester.widget<Text>(find.text('Hoàn tác')).style);
      expect(
        _contrast(action.color!, s.inverseSurface),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  group('status widgets (Phase 22.2)', () {
    Color textColor(WidgetTester tester, Finder finder) {
      final style = DefaultTextStyle.of(
        tester.element(finder),
      ).style.merge(tester.widget<Text>(finder).style);
      return style.color!;
    }

    Color decorationColor(WidgetTester tester, Finder ancestorOf) {
      final box = tester
          .widgetList<Container>(
            find.ancestor(of: ancestorOf, matching: find.byType(Container)),
          )
          .firstWhere((c) => c.decoration is BoxDecoration);
      return (box.decoration! as BoxDecoration).color!;
    }

    for (final MapEntry(key: name, value: theme) in themes.entries) {
      final s = theme.colorScheme;
      final sem = theme.extension<AppSemanticColors>()!;

      for (final scale in [1.0, 1.5]) {
        testWidgets('verdict chips, draft note and emergency card meet '
            'guidelines ($name, x$scale)', (tester) async {
          final handle = tester.ensureSemantics();
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 2.625;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _app(theme, const _StatusGallery(), textScale: scale),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          handle.dispose();
        });
      }

      testWidgets('verdict chips use the semantic tokens ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(_app(theme, const _StatusGallery()));
        await tester.pumpAndSettle();
        final expected = {
          FoodVerdict.ok: (sem.successContainer, sem.onSuccessContainer),
          FoodVerdict.limit: (sem.warningContainer, sem.onWarningContainer),
          FoodVerdict.avoid: (sem.dangerContainer, sem.onDangerContainer),
        };
        for (final MapEntry(key: verdict, value: (bg, fg))
            in expected.entries) {
          final label = find.text(verdict.label);
          expect(decorationColor(tester, label), bg, reason: verdict.name);
          expect(textColor(tester, label), fg, reason: verdict.name);
          expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
        }
      });

      testWidgets('draft note is a warning container ($name)', (tester) async {
        await tester.pumpWidget(_app(theme, const _StatusGallery()));
        await tester.pumpAndSettle();
        final label = find.text('Nội dung đang chờ bác sĩ duyệt');
        expect(decorationColor(tester, label), sem.warningContainer);
        expect(
          _contrast(textColor(tester, label), sem.warningContainer),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('emergency entry card is red-tinted ($name)', (tester) async {
        await tester.pumpWidget(_app(theme, const _StatusGallery()));
        await tester.pumpAndSettle();
        final card = tester.widget<Card>(
          find.descendant(
            of: find.byType(EmergencyEntryCard),
            matching: find.byType(Card),
          ),
        );
        expect(card.color, s.errorContainer);
        final title = find.text('Dấu hiệu cần đi khám ngay');
        expect(textColor(tester, title), s.onErrorContainer);
        expect(
          _contrast(textColor(tester, title), s.errorContainer),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('"Gọi 115" uses the error roles ($name)', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(child: _app(theme, const EmergencyWarningScreen())),
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
        expect(material.color, s.error);
        expect(material.textStyle!.color, s.onError);
        expect(_contrast(s.onError, s.error), greaterThanOrEqualTo(4.5));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('date pickers in the dark theme (P21-R2-01)', () {
    final theme = AppTheme.dark();
    final s = theme.colorScheme;

    Color textColor(WidgetTester tester, Finder finder) {
      final style = DefaultTextStyle.of(
        tester.element(finder),
      ).style.merge(tester.widget<Text>(finder).style);
      return style.color!;
    }

    testWidgets('date range picker: in-range, selected and header text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          theme,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2026, 10, 1),
                  lastDate: DateTime(2026, 10, 31),
                  currentDate: DateTime(2026, 10, 29),
                  initialDateRange: DateTimeRange(
                    start: DateTime(2026, 10, 10),
                    end: DateTime(2026, 10, 14),
                  ),
                  helpText: 'Chọn khoảng thời gian',
                  saveText: 'Xong',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final band = DatePickerTheme.of(
        tester.element(find.text('12')),
      ).rangeSelectionBackgroundColor!;
      expect(band, s.primaryContainer);
      for (final day in ['11', '12', '13']) {
        expect(
          _contrast(textColor(tester, find.text(day)), band),
          greaterThanOrEqualTo(4.5),
          reason: 'in-range day $day',
        );
      }
      for (final day in ['10', '14']) {
        expect(
          _contrast(textColor(tester, find.text(day)), s.primary),
          greaterThanOrEqualTo(4.5),
          reason: 'selected day $day',
        );
      }
      final header = theme.datePickerTheme.rangePickerBackgroundColor!;
      expect(
        _contrast(
          textColor(tester, find.text('Chọn khoảng thời gian')),
          header,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(textColor(tester, find.text('Xong')), header),
        greaterThanOrEqualTo(4.5),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('date picker: selected day and header text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          theme,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDatePicker(
                  context: context,
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 12, 31),
                  initialDate: DateTime(2026, 10, 12),
                  currentDate: DateTime(2026, 10, 29),
                  helpText: 'Chọn ngày',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final dialogBg = theme.datePickerTheme.backgroundColor!;
      expect(
        _contrast(textColor(tester, find.text('12')), s.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(textColor(tester, find.text('13')), dialogBg),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(textColor(tester, find.text('Chọn ngày')), dialogBg),
        greaterThanOrEqualTo(4.5),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
