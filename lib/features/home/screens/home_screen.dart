import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/widgets/hive_boxes_listener.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../bump_journal/widgets/bump_spotlight_card.dart';
import '../../emergency/widgets/emergency_app_bar_button.dart';
import '../../emergency/widgets/emergency_entry_card.dart';
import '../widgets/pregnancy_progress_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/upcoming_appointments_card.dart';
import '../widgets/maternal_habits_card.dart';
import '../widgets/next_milestone_card.dart';
import '../widgets/pregnancy_day_card.dart';
import '../widgets/today_thai_giao_card.dart';
import '../widgets/today_tip_card.dart';
import '../widgets/week_todo_card.dart';
import '../../settings/widgets/my_clinic_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  /// Calendar date the daily cards were last built for.
  DateTime? _builtDate;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recompute the content day when the app resumes on a new date.
    if (state == AppLifecycleState.resumed &&
        _builtDate != null &&
        _builtDate != _today()) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when pregnancy/appointment data changes in another tab.
    return HiveBoxesListener(
      boxNames: const [AppConstants.pregnancyBox, AppConstants.appointmentBox],
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    // Get active pregnancy (returns null if not found, no exception thrown)
    final pregnancy = DatabaseService.getActivePregnancy();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const EmergencyAppBarButton(),
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => NavigationHelper.showNotificationsDialog(context),
          ),
        ],
      ),
      body: pregnancy == null
          ? _buildNoPregnancyView(context)
          : _buildPregnancyView(context, pregnancy),
    );
  }

  Widget _buildNoPregnancyView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.welcomeToMomCare,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.startYourJourney,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => NavigationHelper.toPregnancySetup(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.setUpPregnancy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyView(BuildContext context, PregnancyModel pregnancy) {
    final now = DateTime.now();
    _builtDate = DateTime(now.year, now.month, now.day);
    final contentDay = pregnancy.contentDayAt(now);
    // Order (Phase 22.5): greeting, hero day card, bump photo, time-bound
    // actions, today's content, habits, quick actions, emergency + clinic, progress.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(context, pregnancy),
          const SizedBox(height: 12),
          PregnancyDayCard(
            key: const ValueKey('home-day-card'),
            pregnancy: pregnancy,
            now: now,
          ),
          const SizedBox(height: 12),
          BumpSpotlightCard(
            key: const ValueKey('home-bump-photo'),
            week: pregnancy.currentWeekAt(now),
          ),
          NextMilestoneCard(
            key: const ValueKey('home-next-milestone'),
            pregnancy: pregnancy,
            now: now,
          ),
          const SizedBox(height: 16),
          const UpcomingAppointmentsCard(key: ValueKey('home-appointments')),
          const SizedBox(height: 16),
          TodayThaiGiaoCard(
            key: const ValueKey('home-thai-giao'),
            day: contentDay,
          ),
          const SizedBox(height: 16),
          TodayTipCard(key: const ValueKey('home-tip'), day: contentDay),
          const SizedBox(height: 16),
          WeekTodoCard(
            key: const ValueKey('home-week-todo'),
            week: pregnancy.currentWeekAt(now),
          ),
          const SizedBox(height: 16),
          const MaternalHabitsCard(key: ValueKey('home-habits')),
          const SizedBox(height: 24),
          const QuickActionsGrid(key: ValueKey('home-quick-actions')),
          const SizedBox(height: 24),
          const EmergencyEntryCard(key: ValueKey('home-emergency-card')),
          const SizedBox(height: 16),
          const MyClinicCard(key: ValueKey('home-clinic')),
          const SizedBox(height: 16),
          PregnancyProgressCard(
            key: const ValueKey('home-progress'),
            pregnancy: pregnancy,
          ),
        ],
      ),
    );
  }

  /// One-line greeting, e.g. "Chào buổi chiều, An". The time left until
  /// the due date is shown in [PregnancyDayCard].
  Widget _buildGreeting(BuildContext context, PregnancyModel pregnancy) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = l10n.goodMorning;
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
    } else {
      greeting = l10n.goodEvening;
    }
    final name = pregnancy.motherName?.trim();
    return Text(
      name == null || name.isEmpty ? greeting : '$greeting, $name',
      key: const ValueKey('home-greeting'),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
