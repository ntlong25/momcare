import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/data/content_pack_service.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/models/pre_readiness.dart';
import '../../../core/services/cycle_prediction.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../emergency/widgets/emergency_app_bar_button.dart';
import '../../emergency/widgets/emergency_entry_card.dart';
import '../widgets/fertile_today_card.dart';
import '../widgets/late_period_card.dart';
import '../widgets/pre_readiness_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/pregnant_switch_card.dart';
import '../../settings/widgets/my_clinic_card.dart';
import '../../../core/widgets/app_card.dart';

class PrePregnancyHomeScreen extends ConsumerStatefulWidget {
  /// Fixed cycles instead of the Hive box (tests only).
  @visibleForTesting
  final List<MenstrualCycleModel>? debugCycles;

  /// Fixed "today" for the late-period check (tests only).
  @visibleForTesting
  final DateTime? debugToday;

  const PrePregnancyHomeScreen({super.key, this.debugCycles, this.debugToday});

  @override
  ConsumerState<PrePregnancyHomeScreen> createState() =>
      _PrePregnancyHomeScreenState();
}

class _PrePregnancyHomeScreenState
    extends ConsumerState<PrePregnancyHomeScreen> {
  List<MenstrualCycleModel> _cycles = [];

  Listenable? _cycleListenable;

  @override
  void initState() {
    super.initState();
    _loadCycles();
    try {
      _cycleListenable = DatabaseService.menstrualCycleBox.listenable();
      _cycleListenable!.addListener(_loadCycles);
    } catch (_) {
      // Box not open (e.g. in isolated widget tests).
    }
  }

  @override
  void dispose() {
    _cycleListenable?.removeListener(_loadCycles);
    super.dispose();
  }

  Future<void> _loadCycles() async {
    if (!mounted) return;
    List<MenstrualCycleModel> cycles;
    try {
      cycles = widget.debugCycles ?? DatabaseService.getAllMenstrualCycles();
    } catch (_) {
      // Box not open (e.g. in isolated widget tests).
      cycles = [];
    }
    if (!mounted) return;
    setState(() {
      _cycles = cycles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = widget.debugToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prediction = CyclePrediction.compute(_cycles, today: today);
    final guidance = ContentPackService.fertileGuidance;
    final showLatePeriod = LatePeriodCard.isVisible(_cycles, today);
    final showReadiness = !PreReadiness.compute(
      ContentPackService.guides,
      const <String>{},
    ).isEmpty;
    final showEarlySigns =
        ContentPackService.guideById(earlySignsGuideId) != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MomCare+'),
        actions: [
          const EmergencyAppBarButton(),
          IconButton(
            tooltip: 'Thông báo',
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
              // Order (Phase 22.5, 24.3): greeting, late period, today's
              // fertility estimate, cycle predictions, readiness, early signs, tips, quick actions,
              // emergency + clinic, "Tôi đã có thai".
              _buildGreeting(theme),
              const SizedBox(height: 16),
              if (showLatePeriod) ...[
                LatePeriodCard(
                  key: const ValueKey('pre-home-late-period'),
                  cycles: _cycles,
                  today: today,
                ),
                const SizedBox(height: 16),
              ],
              // While late or stale, rolled-forward predictions would
              // contradict the late-period card; they return once a new
              // period is logged.
              if (!showLatePeriod) ...[
                if (FertileTodayCard.isVisible(prediction, guidance)) ...[
                  FertileTodayCard(
                    key: const ValueKey('pre-fertile-today-card'),
                    prediction: prediction!,
                    guidance: guidance,
                  ),
                  const SizedBox(height: 16),
                ],
                _FertileWindowWidget(
                  key: const ValueKey('pre-fertile-window-card'),
                  fertileWindow: prediction?.fertileDays,
                  hasCycles: _cycles.isNotEmpty,
                  onAddPeriod: () async {
                    await NavigationHelper.toFertilityPlanner(context);
                    _loadCycles();
                  },
                ),
                const SizedBox(height: 16),
                _OvulationCountdownWidget(
                  key: const ValueKey('pre-ovulation-card'),
                  prediction: prediction,
                  today: today,
                  inRangeLabel: guidance.text('ovulation_in_range'),
                ),
                const SizedBox(height: 16),
              ],
              if (showReadiness) ...[
                const PreReadinessCard(key: ValueKey('pre-home-readiness')),
                const SizedBox(height: 16),
              ],
              if (showEarlySigns) ...[
                const EarlySignsEntryCard(
                  key: ValueKey('pre-home-early-signs'),
                ),
                const SizedBox(height: 16),
              ],
              _DailyTipsWidget(
                key: const ValueKey('pre-home-tips'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              KeyedSubtree(
                key: const ValueKey('pre-home-quick-actions'),
                child: _buildQuickActions(context),
              ),
              const SizedBox(height: 16),
              const EmergencyEntryCard(key: ValueKey('pre-home-emergency')),
              const SizedBox(height: 16),
              const MyClinicCard(key: ValueKey('pre-home-clinic')),
              const SizedBox(height: 16),
              const PregnantSwitchCard(key: ValueKey('pre-home-switch')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 17
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';

    return Column(
      key: const ValueKey('pre-home-greeting'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chúc bạn một ngày tràn đầy năng lượng!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return QuickActionTileGrid(
      tiles: [
        QuickActionTile(
          key: const ValueKey('pre-quick-cycle'),
          icon: Icons.calendar_month,
          title: 'Theo dõi chu kỳ',
          tone: AppTone.primary,
          onTap: () => NavigationHelper.toFertilityPlanner(context),
        ),
        QuickActionTile(
          key: const ValueKey('pre-quick-nutrition'),
          icon: Icons.restaurant_menu,
          title: 'Dinh dưỡng',
          tone: AppTone.secondary,
          onTap: () => NavigationHelper.toNutrition(context),
        ),
      ],
    );
  }
}

class _FertileWindowWidget extends StatelessWidget {
  final List<DateTime>? fertileWindow;
  final bool hasCycles;
  final VoidCallback onAddPeriod;

  const _FertileWindowWidget({
    super.key,
    this.fertileWindow,
    required this.hasCycles,
    required this.onAddPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = AppTone.success.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: success.container,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.eco, color: success.onContainer),
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddPeriod,
                icon: const Icon(Icons.add),
                label: const Text('Thêm kỳ kinh'),
              ),
            ),
          ] else if (fertileWindow != null && fertileWindow!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: success.container,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${fertileWindow!.first.day}/${fertileWindow!.first.month}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: success.onContainer,
                          ),
                        ),
                        Text(
                          'Bắt đầu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: success.onContainer),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      color: success.onContainer,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${fertileWindow!.last.day}/${fertileWindow!.last.month}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: success.onContainer,
                          ),
                        ),
                        Text(
                          'Kết thúc',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: success.onContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đây là khoảng thời gian có khả năng thụ thai cao hơn trong chu kỳ.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              'Cần thêm dữ liệu để dự đoán.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OvulationCountdownWidget extends StatelessWidget {
  final CyclePrediction? prediction;
  final DateTime today;

  /// Shown instead of 'Hôm nay' when today is inside a range of dates.
  final String inRangeLabel;

  const _OvulationCountdownWidget({
    super.key,
    required this.prediction,
    required this.today,
    required this.inRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final prediction = this.prediction;
    if (prediction == null) return const SizedBox.shrink();

    final earliest = prediction.earliestOvulation;
    final latest = prediction.latestOvulation;
    final countdown = RangeCountdown.of(earliest, latest, today);
    final isToday = countdown.position == DateRangePosition.inside;
    final isPast = countdown.position == DateRangePosition.past;
    final info = AppTone.info.of(context);
    final scheme = theme.colorScheme;
    final boxBg = isToday
        ? info.main
        : isPast
        ? scheme.surfaceContainerHighest
        : info.container;
    final boxFg = isToday
        ? info.onMain
        : isPast
        ? scheme.onSurfaceVariant
        : info.onContainer;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: info.container,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.egg_alt, color: info.onContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ngày rụng trứng dự kiến',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  isToday
                      ? countdown.insideLabel(inRangeLabel)
                      : isPast
                      ? 'Đã qua'
                      : '${countdown.daysUntilStart}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: boxFg,
                  ),
                ),
                if (!isToday && !isPast)
                  Text(
                    'ngày nữa',
                    style: TextStyle(color: boxFg, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatDateRange(earliest, latest),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: boxFg),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Kỳ kinh tiếp theo: ${DateFormatter.formatDateRange(prediction.earliestPeriod, prediction.latestPeriod)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyTipsWidget extends StatelessWidget {
  final ThemeData theme;

  const _DailyTipsWidget({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final tips = [
      _Tip(
        icon: Icons.medication,
        title: 'Bổ sung axit folic',
        content:
            'Bạn có thể trao đổi với bác sĩ về việc bổ sung axit folic trước khi mang thai.',
        tone: AppTone.primary,
      ),
      _Tip(
        icon: Icons.no_drinks,
        title: 'Tránh rượu bia',
        content:
            'Nên hạn chế rượu bia khi đang lên kế hoạch mang thai để hỗ trợ sức khỏe sinh sản.',
        tone: AppTone.danger,
      ),
      _Tip(
        icon: Icons.fitness_center,
        title: 'Duy trì cân nặng phù hợp',
        content:
            'Cân nặng quá thấp hoặc quá cao có thể ảnh hưởng đến chu kỳ và khả năng thụ thai.',
        tone: AppTone.success,
      ),
      _Tip(
        icon: Icons.local_cafe,
        title: 'Theo dõi lượng caffeine',
        content:
            'Nếu dùng nhiều caffeine, bạn có thể cân nhắc giảm dần và hỏi bác sĩ khi cần.',
        tone: AppTone.secondary,
      ),
      _Tip(
        icon: Icons.medical_services,
        title: 'Khám tiền sản',
        content:
            'Một buổi khám trước mang thai có thể giúp bạn kiểm tra sức khỏe tổng quát và tiêm chủng cần thiết.',
        tone: AppTone.info,
      ),
    ];

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final todayTip = tips[dayOfYear % tips.length];
    final tipTone = todayTip.tone.of(context);
    final fg = AppTone.mint.of(context).onContainer;

    return AppCard(
      variant: AppCardVariant.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tipTone.container,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(todayTip.icon, color: tipTone.onContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý hôm nay',
                      style: theme.textTheme.bodySmall?.copyWith(color: fg),
                    ),
                    Text(
                      todayTip.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: fg,
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
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: fg),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  final IconData icon;
  final String title;
  final String content;
  final AppTone tone;

  _Tip({
    required this.icon,
    required this.title,
    required this.content,
    required this.tone,
  });
}
