import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_mode_provider.dart';
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

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: destinations,
      ),
    );
  }
}

class _TrackTabScreen extends StatelessWidget {
  final bool isPrePregnancy;

  const _TrackTabScreen({required this.isPrePregnancy});

  @override
  Widget build(BuildContext context) {
    // Cycle tracking is only offered in pre-pregnancy mode.
    return DefaultTabController(
      key: ValueKey(isPrePregnancy),
      length: 2,
      child: _CollapsibleTabScaffold(
        title: isPrePregnancy ? 'Chu kỳ & sức khỏe' : 'Tuần thai & sức khỏe',
        tabBar: TabBar(
          tabs: isPrePregnancy
              ? const [
                  Tab(text: 'Chu kỳ', icon: Icon(Icons.calendar_month)),
                  Tab(text: 'Sức khỏe', icon: Icon(Icons.favorite)),
                ]
              : const [
                  Tab(text: 'Thai kỳ', icon: Icon(Icons.track_changes)),
                  Tab(text: 'Sức khỏe', icon: Icon(Icons.favorite)),
                ],
        ),
        body: TabBarView(
          children: isPrePregnancy
              ? const [
                  FertilityPlannerScreen(showAppBar: false),
                  HealthDiaryScreen(showAppBar: false),
                ]
              : const [
                  TrackingScreen(showAppBar: false),
                  HealthDiaryScreen(showAppBar: false),
                ],
        ),
      ),
    );
  }
}

class _ToolsTabScreen extends ConsumerWidget {
  const _ToolsTabScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrePregnancy = ref.watch(appModeProvider) == AppMode.prePregnancy;
    // "Bộ đếm" (kick counter, contraction timer) is pregnancy-only.
    return DefaultTabController(
      key: ValueKey(isPrePregnancy),
      length: isPrePregnancy ? 3 : 4,
      child: _CollapsibleTabScaffold(
        title: 'Công cụ',
        actions: [
          IconButton(
            key: const ValueKey('tools-find-hospital'),
            tooltip: 'Tìm bệnh viện gần tôi',
            icon: const Icon(Icons.local_hospital_outlined),
            onPressed: () => MyClinicCard.findNearbyHospital(context),
          ),
        ],
        tabBar: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            const Tab(text: 'Dinh dưỡng', icon: Icon(Icons.restaurant_menu)),
            const Tab(text: 'Lịch hẹn', icon: Icon(Icons.calendar_today)),
            if (!isPrePregnancy)
              const Tab(text: 'Bộ đếm', icon: Icon(Icons.timer_outlined)),
            const Tab(
              text: 'Cần khám',
              icon: Icon(Icons.warning_amber_rounded),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            const NutritionScreen(showAppBar: false),
            const AppointmentsScreen(showAppBar: false),
            if (!isPrePregnancy) const CounterToolsScreen(),
            const EmergencyWarningScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }
}

class _CollapsibleTabScaffold extends StatelessWidget {
  final String title;
  final TabBar tabBar;
  final Widget body;
  final List<Widget>? actions;

  const _CollapsibleTabScaffold({
    required this.title,
    required this.tabBar,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(title),
              actions: actions,
              floating: true,
              snap: true,
              forceElevated: innerBoxIsScrolled,
              bottom: tabBar,
            ),
          ];
        },
        body: body,
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
