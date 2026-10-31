import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../bump_journal/quick_camera.dart';
import 'home_screen.dart';
import 'pre_pregnancy_home_screen.dart';
import '../../tracking/screens/tracking_screen.dart';
import '../../health_diary/screens/health_diary_screen.dart';
import '../../nutrition/screens/nutrition_screen.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../emergency/screens/emergency_warning_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../fertility/screens/fertility_planner_screen.dart';
import '../../guides/screens/guides_screen.dart';
import '../../settings/widgets/my_clinic_card.dart';
import '../../tools/screens/counter_tools_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom navigation destinations for the given mode (Phase 13 IA):
/// Hôm nay / Tuần thai (Chu kỳ) / Cẩm nang / Công cụ / Cài đặt.
List<NavigationDestination> mainDestinations({required bool isPrePregnancy}) {
  return [
    const NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Hôm nay',
    ),
    NavigationDestination(
      icon: Icon(
        isPrePregnancy ? Icons.calendar_month_outlined : Icons.pregnant_woman,
      ),
      selectedIcon: Icon(
        isPrePregnancy ? Icons.calendar_month : Icons.pregnant_woman,
      ),
      label: isPrePregnancy ? 'Chu kỳ' : 'Tuần thai',
    ),
    const NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Cẩm nang',
    ),
    const NavigationDestination(
      icon: Icon(Icons.widgets_outlined),
      selectedIcon: Icon(Icons.widgets),
      label: 'Công cụ',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Cài đặt',
    ),
  ];
}

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final isPrePregnancy = appMode == AppMode.prePregnancy;
    final destinations = mainDestinations(isPrePregnancy: isPrePregnancy);
    final currentIndex = ref
        .watch(navigationIndexProvider)
        .clamp(0, destinations.length - 1);

    final screens = [
      isPrePregnancy ? const PrePregnancyHomeScreen() : const HomeScreen(),
      _TrackTabScreen(isPrePregnancy: isPrePregnancy),
      const GuidesScreen(),
      const _ToolsTabScreen(),
      const _ProfileTabScreen(),
    ];

    return QuickCameraListener(
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: SingleLineNavigationLabels(
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(navigationIndexProvider.notifier).state = index;
            },
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}

/// Keeps the [NavigationBar] labels on one line (P18-R2-01): limits the
/// label text scale to the largest factor (at most the NavigationBar's own
/// 1.3 cap) at which the widest label fits its destination. On a 412 dp
/// phone labels keep the full 1.3 scale; on a 360 dp phone at font scale
/// 1.5 they are drawn at about 1.15.
class SingleLineNavigationLabels extends StatelessWidget {
  /// The NavigationBar's own label text-scale cap.
  static const double maxLabelScale = 1.3;

  final NavigationBar child;

  const SingleLineNavigationLabels({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final style =
            theme.navigationBarTheme.labelTextStyle?.resolve({
              WidgetState.selected,
            }) ??
            theme.textTheme.labelMedium;
        final slot = constraints.maxWidth / child.destinations.length - 2;
        var widest = 0.0;
        for (final destination in child.destinations) {
          if (destination is! NavigationDestination) continue;
          final painter = TextPainter(
            text: TextSpan(text: destination.label, style: style),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          if (painter.width > widest) widest = painter.width;
          painter.dispose();
        }
        if (widest == 0 || !slot.isFinite) return child;
        final fit = (slot / widest).clamp(1.0, maxLabelScale);
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: fit,
          child: child,
        );
      },
    );
  }
}

class _TrackTabScreen extends StatelessWidget {
  final bool isPrePregnancy;

  const _TrackTabScreen({required this.isPrePregnancy});

  @override
  Widget build(BuildContext context) {
    // Cycle tracking is only offered in pre-pregnancy mode.
    return TabbedScaffold(
      key: ValueKey(isPrePregnancy),
      title: isPrePregnancy ? 'Chu kỳ & sức khỏe' : 'Tuần thai & sức khỏe',
      pages: isPrePregnancy
          ? const [
              TabbedPage(
                id: 'cycle',
                label: 'Chu kỳ',
                icon: Icons.calendar_month,
                child: FertilityPlannerScreen(showAppBar: false),
              ),
              TabbedPage(
                id: 'health',
                label: 'Sức khỏe',
                icon: Icons.favorite,
                child: HealthDiaryScreen(showAppBar: false),
              ),
            ]
          : const [
              TabbedPage(
                id: 'pregnancy',
                label: 'Thai kỳ',
                icon: Icons.track_changes,
                child: TrackingScreen(showAppBar: false),
              ),
              TabbedPage(
                id: 'health',
                label: 'Sức khỏe',
                icon: Icons.favorite,
                child: HealthDiaryScreen(showAppBar: false),
              ),
            ],
    );
  }
}

class _ToolsTabScreen extends ConsumerWidget {
  const _ToolsTabScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrePregnancy = ref.watch(appModeProvider) == AppMode.prePregnancy;
    // "Bộ đếm" (kick counter, contraction timer) is pregnancy-only.
    return TabbedScaffold(
      key: ValueKey(isPrePregnancy),
      title: 'Công cụ',
      actions: [
        IconButton(
          key: const ValueKey('tools-find-hospital'),
          tooltip: 'Tìm bệnh viện gần tôi',
          icon: const Icon(Icons.local_hospital_outlined),
          onPressed: () => MyClinicCard.findNearbyHospital(context),
        ),
      ],
      pages: [
        const TabbedPage(
          id: 'nutrition',
          label: 'Dinh dưỡng',
          icon: Icons.restaurant_menu,
          child: NutritionScreen(showAppBar: false),
        ),
        const TabbedPage(
          id: 'appointments',
          label: 'Lịch hẹn',
          icon: Icons.calendar_today,
          child: AppointmentsScreen(showAppBar: false),
        ),
        if (!isPrePregnancy) toolsCounterPage,
        toolsEmergencyPage,
      ],
    );
  }
}

/// "Bộ đếm" tab of Công cụ (pregnancy mode).
const TabbedPage toolsCounterPage = TabbedPage(
  id: 'counters',
  label: 'Bộ đếm',
  icon: Icons.timer_outlined,
  child: CounterToolsScreen(),
);

/// "Cần khám" tab of Công cụ.
const TabbedPage toolsEmergencyPage = TabbedPage(
  id: 'emergency',
  label: 'Cần khám',
  icon: Icons.warning_amber_rounded,
  child: EmergencyWarningScreen(showAppBar: false),
);

/// One tab of a [TabbedScaffold].
class TabbedPage {
  /// Stable id, used for the tab's [PageStorageKey].
  final String id;
  final String label;
  final IconData icon;
  final Widget child;

  const TabbedPage({
    required this.id,
    required this.label,
    required this.icon,
    required this.child,
  });
}

/// Scaffold with an AppBar whose bottom is a scrollable [TabBar]. Each tab
/// owns its scroll position (a [PageStorageKey] per tab), so scrolling one
/// tab never moves another (P20-R2-02), and labels are never clipped at
/// large font scales (P18-R2-01).
class TabbedScaffold extends StatelessWidget {
  final String title;
  final List<TabbedPage> pages;
  final List<Widget>? actions;

  const TabbedScaffold({
    super.key,
    required this.title,
    required this.pages,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: pages.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final page in pages)
                Tab(
                  key: ValueKey('tab-${page.id}'),
                  text: page.label,
                  icon: Icon(page.icon),
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final page in pages)
              KeyedSubtree(
                key: PageStorageKey<String>('tab-page-${page.id}'),
                child: page.child,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabScreen extends StatelessWidget {
  const _ProfileTabScreen();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
