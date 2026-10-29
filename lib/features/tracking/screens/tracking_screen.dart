import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/hive_boxes_listener.dart';
import '../../../core/data/content_pack_service.dart';
import '../../../core/data/pregnancy_weeks_data.dart';
import '../../../core/models/week_detail_model.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../bump_journal/widgets/bump_journal_entry_card.dart';
import '../widgets/baby_development_card.dart';
import '../widgets/mother_changes_card.dart';
import '../widgets/weekly_tips_card.dart';
import '../widgets/weight_gain_chart.dart';

class TrackingScreen extends ConsumerWidget {
  final bool showAppBar;

  /// Overrides the active pregnancy from Hive (tests).
  final PregnancyModel? pregnancy;

  const TrackingScreen({super.key, this.showAppBar = true, this.pregnancy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild when pregnancy/health-log data changes in another tab.
    return HiveBoxesListener(
      boxNames: const [AppConstants.pregnancyBox, AppConstants.healthLogBox],
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    // Get active pregnancy (returns null if not found, no exception thrown)
    final pregnancy = this.pregnancy ?? DatabaseService.getActivePregnancy();

    if (pregnancy == null) {
      return Scaffold(
        appBar: showAppBar
            ? AppBar(title: const Text('Theo dõi thai kỳ'))
            : null,
        body: _buildNoPregnancyView(context),
      );
    }

    final currentWeek = pregnancy.currentWeek;
    final weekData = PregnancyWeeksDatabase.getWeekData(currentWeek);
    // Same resolver as the week pages so both show identical baby stats.
    final weekDetail = ContentPackService.weekDetail(currentWeek);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Theo dõi thai kỳ'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Xem chi tiết từng tuần',
                  onPressed: () => _openWeekDetail(context, currentWeek),
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeekHeader(context, pregnancy, weekData, weekDetail),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openWeekDetail(context, currentWeek),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text('Xem chi tiết tuần $currentWeek'),
                ),
              ),
              const SizedBox(height: 16),
              BabyDevelopmentCard(weekData: weekData, weekDetail: weekDetail),
              const SizedBox(height: 16),
              MotherChangesCard(weekData: weekData),
              const SizedBox(height: 16),
              WeeklyTipsCard(weekData: weekData),
              const SizedBox(height: 16),
              const BumpJournalEntryCard(),
              const SizedBox(height: 16),
              WeightGainChart(pregnancy: pregnancy),
              const SizedBox(height: 16),
              _buildMilestones(context, currentWeek),
            ],
          ),
        ),
      ),
    );
  }

  void _openWeekDetail(BuildContext context, int week) {
    NavigationHelper.toWeekDetail(context, week);
  }

  Widget _buildNoPregnancyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 100,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có thai kỳ đang theo dõi',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Thiết lập thông tin thai kỳ để bắt đầu theo dõi',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => NavigationHelper.toPregnancySetup(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thai kỳ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader(
    BuildContext context,
    PregnancyModel pregnancy,
    PregnancyWeekData weekData,
    WeekDetail weekDetail,
  ) {
    final header = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tuần ${pregnancy.currentWeek}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pregnancy.trimester,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      'Em bé',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Còn lại',
                '${pregnancy.daysUntilDue < 0 ? 0 : pregnancy.daysUntilDue} ngày',
                Icons.calendar_today,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                context,
                'Kích thước',
                WeekDetail.statText(weekDetail.sizeCompare, weekData.babySize),
                Icons.spa,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                context,
                'Cân nặng',
                WeekDetail.statText(weekDetail.weightText, weekData.babyWeight),
                Icons.monitor_weight,
              ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: 'Xem chi tiết tuần ${pregnancy.currentWeek}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('tracking-week-header'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openWeekDetail(context, pregnancy.currentWeek),
          child: header,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestones(BuildContext context, int currentWeek) {
    final milestones = [
      {
        'week': 12,
        'title': 'Kết thúc tam cá nguyệt 1',
        'icon': Icons.celebration,
      },
      {'week': 20, 'title': 'Đi được nửa hành trình', 'icon': Icons.favorite},
      {'week': 28, 'title': 'Bắt đầu tam cá nguyệt 3', 'icon': Icons.star},
      {'week': 37, 'title': 'Thai đủ tháng', 'icon': Icons.child_care},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mốc sắp tới', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...milestones.map((milestone) {
              final week = milestone['week'] as int;
              final isPassed = currentWeek >= week;
              final isCurrent = currentWeek == week;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        milestone['icon'] as IconData,
                        color: isPassed ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isPassed
                                      ? Theme.of(context).primaryColor
                                      : null,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : null,
                                ),
                          ),
                          Text(
                            'Tuần $week',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Chip(
                        label: const Text('Hiện tại'),
                        backgroundColor: Theme.of(context).primaryColor,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
