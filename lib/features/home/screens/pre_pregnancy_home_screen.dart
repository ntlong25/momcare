import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/health_service.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../fertility/screens/gender_selection_screen.dart';

class PrePregnancyHomeScreen extends ConsumerStatefulWidget {
  const PrePregnancyHomeScreen({super.key});

  @override
  ConsumerState<PrePregnancyHomeScreen> createState() =>
      _PrePregnancyHomeScreenState();
}

class _PrePregnancyHomeScreenState
    extends ConsumerState<PrePregnancyHomeScreen> {
  List<MenstrualCycleModel> _cycles = [];

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    final cycles = DatabaseService.getAllMenstrualCycles();
    setState(() {
      _cycles = cycles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate predictions
    final nextOvulation = HealthService.predictNextOvulation(_cycles);
    final fertileWindow = HealthService.predictFertileWindow(_cycles);
    final nextPeriod = HealthService.predictNextPeriod(_cycles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MomCare+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => NavigationHelper.showNotificationsDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCycles,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _buildGreeting(theme),
              const SizedBox(height: 24),

              // Widget 1: Fertile Window
              _FertileWindowWidget(
                fertileWindow: fertileWindow,
                nextOvulation: nextOvulation,
                hasCycles: _cycles.isNotEmpty,
                onAddPeriod: () async {
                  await NavigationHelper.toFertilityPlanner(context);
                  _loadCycles();
                },
              ),
              const SizedBox(height: 16),

              // Widget 2: Ovulation Countdown
              _OvulationCountdownWidget(
                nextOvulation: nextOvulation,
                nextPeriod: nextPeriod,
                hasCycles: _cycles.isNotEmpty,
              ),
              const SizedBox(height: 16),

              // Widget 3: Daily Tips
              _DailyTipsWidget(theme: theme),
              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng';
    } else if (hour < 17) {
      greeting = 'Chào buổi chiều';
    } else {
      greeting = 'Chào buổi tối';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chúc bạn một ngày tràn đầy năng lượng!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Truy cập nhanh',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.calendar_month,
                label: 'Kế hoạch\nthụ thai',
                color: Colors.purple,
                onTap: () => NavigationHelper.toFertilityPlanner(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.restaurant_menu,
                label: 'Dinh\ndưỡng',
                color: Colors.orange,
                onTap: () => NavigationHelper.toNutrition(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.wc,
                label: 'Chọn\ngiới tính',
                color: Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _GenderSelectionNavigator(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget 1: Fertile Window
class _FertileWindowWidget extends StatelessWidget {
  final List<DateTime>? fertileWindow;
  final DateTime? nextOvulation;
  final bool hasCycles;
  final VoidCallback onAddPeriod;

  const _FertileWindowWidget({
    this.fertileWindow,
    this.nextOvulation,
    required this.hasCycles,
    required this.onAddPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cửa sổ thụ thai',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasCycles) ...[
              Text(
                'Chưa có dữ liệu chu kỳ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddPeriod,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm ngày kinh nguyệt'),
                ),
              ),
            ] else if (fertileWindow != null && fertileWindow!.isNotEmpty) ...[
              // Show fertile window dates
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${fertileWindow!.first.day}/${fertileWindow!.first.month}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Bắt đầu'),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(Icons.arrow_forward, color: Colors.green),
                    ),
                    Column(
                      children: [
                        Text(
                          '${fertileWindow!.last.day}/${fertileWindow!.last.month}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Kết thúc'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đây là khoảng thời gian có khả năng thụ thai cao nhất',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Cần thêm dữ liệu để dự đoán',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget 2: Ovulation Countdown
class _OvulationCountdownWidget extends StatelessWidget {
  final DateTime? nextOvulation;
  final DateTime? nextPeriod;
  final bool hasCycles;

  const _OvulationCountdownWidget({
    this.nextOvulation,
    this.nextPeriod,
    required this.hasCycles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasCycles || nextOvulation == null) {
      return const SizedBox.shrink();
    }

    final daysUntilOvulation = nextOvulation!.difference(DateTime.now()).inDays;
    final isToday = daysUntilOvulation == 0;
    final isPast = daysUntilOvulation < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.egg_alt, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ngày rụng trứng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Countdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isToday
                      ? [Colors.blue, Colors.blue.shade700]
                      : isPast
                          ? [Colors.grey, Colors.grey.shade600]
                          : [Colors.blue.shade100, Colors.blue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isToday
                        ? 'HÔM NAY!'
                        : isPast
                            ? 'Đã qua'
                            : '$daysUntilOvulation',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isToday || isPast ? Colors.white : Colors.blue,
                    ),
                  ),
                  if (!isToday && !isPast)
                    Text(
                      'ngày nữa',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${nextOvulation!.day}/${nextOvulation!.month}/${nextOvulation!.year}',
                    style: TextStyle(
                      color: isToday || isPast
                          ? Colors.white70
                          : Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),

            if (nextPeriod != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Kỳ kinh tiếp: ${nextPeriod!.day}/${nextPeriod!.month}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget 3: Daily Tips
class _DailyTipsWidget extends StatelessWidget {
  final ThemeData theme;

  const _DailyTipsWidget({required this.theme});

  @override
  Widget build(BuildContext context) {
    // Tips for pre-pregnancy
    final tips = [
      _Tip(
        icon: Icons.medication,
        title: 'Bổ sung Folic Acid',
        content:
            'Uống 400-800mcg folic acid mỗi ngày, ít nhất 1 tháng trước khi mang thai để ngăn ngừa dị tật ống thần kinh.',
        color: Colors.purple,
      ),
      _Tip(
        icon: Icons.no_drinks,
        title: 'Tránh rượu bia',
        content:
            'Ngừng uống rượu bia khi bắt đầu lên kế hoạch mang thai. Rượu có thể ảnh hưởng đến khả năng thụ thai và phát triển thai nhi.',
        color: Colors.red,
      ),
      _Tip(
        icon: Icons.fitness_center,
        title: 'Duy trì cân nặng',
        content:
            'BMI từ 18.5-24.9 là lý tưởng. Cân nặng quá thấp hoặc quá cao đều ảnh hưởng đến khả năng thụ thai.',
        color: Colors.green,
      ),
      _Tip(
        icon: Icons.local_cafe,
        title: 'Giảm caffeine',
        content:
            'Giới hạn caffeine dưới 200mg/ngày (khoảng 1 ly cà phê). Caffeine cao có thể giảm khả năng thụ thai.',
        color: Colors.brown,
      ),
      _Tip(
        icon: Icons.medical_services,
        title: 'Khám tiền sản',
        content:
            'Đặt lịch khám sức khỏe tổng quát, xét nghiệm máu, kiểm tra vắc-xin và sàng lọc bệnh di truyền.',
        color: Colors.blue,
      ),
    ];

    // Get tip of the day based on day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final todayTip = tips[dayOfYear % tips.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: todayTip.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(todayTip.icon, color: todayTip.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip hôm nay',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        todayTip.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              todayTip.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  _Tip({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });
}

// Quick Action Button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigator to Gender Selection
class _GenderSelectionNavigator extends StatelessWidget {
  const _GenderSelectionNavigator();

  @override
  Widget build(BuildContext context) {
    return const GenderSelectionScreen();
  }
}
