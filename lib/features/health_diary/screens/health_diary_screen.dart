import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/health_log_model.dart';
import '../widgets/health_stats_card.dart';
import '../widgets/health_log_list.dart';
import '../widgets/health_charts_card.dart';
import 'add_health_log_screen.dart';

class HealthDiaryScreen extends ConsumerStatefulWidget {
  const HealthDiaryScreen({super.key});

  @override
  ConsumerState<HealthDiaryScreen> createState() => _HealthDiaryScreenState();
}

class _HealthDiaryScreenState extends ConsumerState<HealthDiaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthLogs = DatabaseService.getAllHealthLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Diary'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Logs'),
            Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsTab(healthLogs),
          _buildChartsTab(healthLogs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddHealthLogScreen(),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Log'),
      ),
    );
  }

  Widget _buildLogsTab(List<HealthLogModel> healthLogs) {
    if (healthLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 100,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No Health Logs Yet',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Start tracking your health by adding your first log',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HealthStatsCard(healthLogs: healthLogs),
            const SizedBox(height: 16),
            HealthLogList(
              healthLogs: healthLogs,
              onDelete: (log) async {
                await DatabaseService.deleteHealthLog(log.id);
                setState(() {});
              },
              onEdit: (log) async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddHealthLogScreen(log: log),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab(List<HealthLogModel> healthLogs) {
    if (healthLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 100,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No Data to Display',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Add health logs to see your trends and charts',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthChartsCard(healthLogs: healthLogs),
        ],
      ),
    );
  }
}
