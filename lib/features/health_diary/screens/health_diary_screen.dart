import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/hive_boxes_listener.dart';
import '../../../core/models/health_log_model.dart';
import '../widgets/health_stats_card.dart';
import '../widgets/health_log_list.dart';
import '../widgets/health_charts_card.dart';
import 'add_health_log_screen.dart';
import '../../../core/widgets/empty_state.dart';

class HealthDiaryScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const HealthDiaryScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<HealthDiaryScreen> createState() => _HealthDiaryScreenState();
}

class _HealthDiaryScreenState extends ConsumerState<HealthDiaryScreen>
    with SingleTickerProviderStateMixin, HiveRefreshMixin {
  late TabController _tabController;

  @override
  List<String> get watchedBoxes => const [AppConstants.healthLogBox];

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
    final tabBar = TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.list), text: 'Nhật ký'),
        Tab(icon: Icon(Icons.show_chart), text: 'Biểu đồ'),
      ],
    );
    final tabBarView = TabBarView(
      controller: _tabController,
      children: [_buildLogsTab(healthLogs), _buildChartsTab(healthLogs)],
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Nhật ký sức khỏe'), bottom: tabBar)
          : null,
      body: widget.showAppBar
          ? tabBarView
          : Column(
              children: [
                tabBar,
                Expanded(child: tabBarView),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddHealthLogScreen()),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm ghi nhận'),
      ),
    );
  }

  Widget _buildLogsTab(List<HealthLogModel> healthLogs) {
    if (healthLogs.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            icon: Icons.favorite_border,
            title: 'Chưa có ghi nhận sức khỏe',
            message: 'Bắt đầu theo dõi bằng cách thêm ghi nhận đầu tiên',
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
        key: const ValueKey('health-diary-logs-scroll'),
        padding: AppSpacing.fabPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('health-export-pdf'),
                onPressed: () => NavigationHelper.toHealthReportExport(
                  context,
                  includePregnancy:
                      ref.read(appModeProvider) != AppMode.prePregnancy,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Xuất PDF cho bác sĩ'),
              ),
            ),
            const SizedBox(height: 16),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Chưa có dữ liệu để hiển thị',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Thêm ghi nhận sức khỏe để xem xu hướng và biểu đồ',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.fabPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [HealthChartsCard(healthLogs: healthLogs)],
      ),
    );
  }
}
