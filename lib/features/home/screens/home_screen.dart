import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/pregnancy_progress_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/upcoming_appointments_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get active pregnancy (returns null if not found, no exception thrown)
    final pregnancy = DatabaseService.getActivePregnancy();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
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
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.welcomeToMomCare,
              style: Theme.of(context).textTheme.displaySmall,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(context, pregnancy),
          const SizedBox(height: 24),
          PregnancyProgressCard(pregnancy: pregnancy),
          const SizedBox(height: 24),
          const QuickActionsGrid(),
          const SizedBox(height: 24),
          const UpcomingAppointmentsCard(),
          const SizedBox(height: 24),
          _buildDailyTip(context),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, PregnancyModel pregnancy) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = l10n.goodMorning;
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
    } else {
      greeting = l10n.goodEvening;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (pregnancy.motherName != null) ...[
          const SizedBox(height: 4),
          Text(
            pregnancy.motherName!,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          DateFormatter.formatDaysRemaining(pregnancy.daysUntilDue),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ],
    );
  }

  Widget _buildDailyTip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.dailyTip,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.dailyTipMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
