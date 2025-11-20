import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_mode_provider.dart';
import 'home_screen.dart';
import 'pre_pregnancy_home_screen.dart';
import '../../tracking/screens/tracking_screen.dart';
import '../../health_diary/screens/health_diary_screen.dart';
import '../../nutrition/screens/nutrition_screen.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../fertility/screens/fertility_planner_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final appMode = ref.watch(appModeProvider);
    final isPrePregnancy = appMode == AppMode.prePregnancy;

    // Different screens based on mode
    final screens = isPrePregnancy
        ? [
            const PrePregnancyHomeScreen(),
            const _TrackTabScreen(isPrePregnancy: true),
            const _ToolsTabScreen(),
            const _ProfileTabScreen(),
          ]
        : [
            const HomeScreen(),
            const _TrackTabScreen(isPrePregnancy: false),
            const _ToolsTabScreen(),
            const _ProfileTabScreen(),
          ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Theo dõi',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Công cụ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

/// Track Tab - Contains Tracking, Health Diary, Fertility
class _TrackTabScreen extends StatelessWidget {
  final bool isPrePregnancy;

  const _TrackTabScreen({required this.isPrePregnancy});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: isPrePregnancy ? 2 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Theo dõi sức khỏe'),
          bottom: TabBar(
            tabs: isPrePregnancy
                ? const [
                    Tab(text: 'Chu kỳ', icon: Icon(Icons.calendar_month)),
                    Tab(text: 'Sức khỏe', icon: Icon(Icons.favorite)),
                  ]
                : const [
                    Tab(text: 'Thai kỳ', icon: Icon(Icons.track_changes)),
                    Tab(text: 'Sức khỏe', icon: Icon(Icons.favorite)),
                    Tab(text: 'Chu kỳ', icon: Icon(Icons.calendar_month)),
                  ],
          ),
        ),
        body: TabBarView(
          children: isPrePregnancy
              ? const [
                  FertilityPlannerScreen(),
                  HealthDiaryScreen(),
                ]
              : const [
                  TrackingScreen(),
                  HealthDiaryScreen(),
                  FertilityPlannerScreen(),
                ],
        ),
      ),
    );
  }
}

/// Tools Tab - Contains Nutrition, Appointments
class _ToolsTabScreen extends StatelessWidget {
  const _ToolsTabScreen();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công cụ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dinh dưỡng', icon: Icon(Icons.restaurant_menu)),
              Tab(text: 'Lịch hẹn', icon: Icon(Icons.calendar_today)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NutritionScreen(),
            AppointmentsScreen(),
          ],
        ),
      ),
    );
  }
}

/// Profile Tab - Contains Settings and more
class _ProfileTabScreen extends StatelessWidget {
  const _ProfileTabScreen();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
