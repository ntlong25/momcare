import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/data/content_pack_service.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/services/cycle_prediction.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/health_service.dart';
import '../../../core/utils/calendar_style.dart';
import '../../../core/utils/date_formatter.dart';
import '../../home/widgets/late_period_card.dart';
import '../../references/widgets/draft_content_note.dart';
import '../widgets/cycle_marker.dart';
import 'add_period_screen.dart';
import '../../../core/theme/app_tokens.dart';

class FertilityPlannerScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const FertilityPlannerScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<FertilityPlannerScreen> createState() =>
      _FertilityPlannerScreenState();
}

class _FertilityPlannerScreenState
    extends ConsumerState<FertilityPlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<MenstrualCycleModel> _cycles = [];
  bool _isLoading = false;
  bool _isSyncing = false;

  ValueListenable<Box<MenstrualCycleModel>>? _cycleListenable;

  @override
  void initState() {
    super.initState();
    _loadCycles();
    try {
      _cycleListenable = DatabaseService.menstrualCycleBox.listenable();
      _cycleListenable!.addListener(_onCyclesChanged);
    } catch (_) {
      // Box not open (e.g. in isolated widget tests).
    }
  }

  @override
  void dispose() {
    _cycleListenable?.removeListener(_onCyclesChanged);
    super.dispose();
  }

  void _onCyclesChanged() {
    if (mounted) _loadCycles();
  }

  Future<void> _loadCycles() async {
    try {
      final cycles = DatabaseService.getAllMenstrualCycles();
      if (!mounted) return;
      setState(() {
        _cycles = cycles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFromHealthKit() async {
    final shouldContinue = await _showHealthSyncRationale();
    if (shouldContinue != true || !mounted) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      // Check if health data is available
      if (!HealthService.isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Dữ liệu sức khỏe không khả dụng trên thiết bị này',
              ),
            ),
          );
        }
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      final healthConnectAvailable =
          await HealthService.isHealthConnectAvailable();
      if (!healthConnectAvailable) {
        if (mounted) {
          await _showHealthConnectUnavailableDialog();
        }
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      // Request permission
      final hasPermission = await HealthService.requestAuthorization();

      if (!hasPermission) {
        if (mounted) {
          await _showHealthPermissionDeniedDialog();
        }
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      // Fetch data
      final healthCycles = await HealthService.fetchMenstrualData(days: 365);

      if (healthCycles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không tìm thấy dữ liệu chu kỳ trong ứng dụng Sức khỏe',
              ),
            ),
          );
        }
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      // Save to database (idempotent: stable ids + dedupe by start date)
      final added = await DatabaseService.importMenstrualCycles(healthCycles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              added == 0
                  ? 'Dữ liệu chu kỳ đã được cập nhật, không có kỳ kinh mới'
                  : 'Đã đồng bộ $added kỳ kinh mới',
            ),
          ),
        );
      }

      // Reload
      await _loadCycles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể đồng bộ: $e')));
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<bool?> _showHealthSyncRationale() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đồng bộ dữ liệu chu kỳ'),
        content: const Text(
          'MomCare+ chỉ đọc dữ liệu chu kỳ kinh nguyệt từ ứng dụng Sức khỏe để hỗ trợ theo dõi chu kỳ. Dữ liệu được lưu trên thiết bị này và không tự chia sẻ ra bên ngoài. Bạn vẫn có thể nhập tay nếu không muốn cấp quyền.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHealthConnectUnavailableDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chưa có Health Connect'),
        content: const Text(
          'Thiết bị Android cần Health Connect để đọc dữ liệu chu kỳ. Bạn có thể cài Health Connect hoặc nhập chu kỳ thủ công trong MomCare+.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openAddPeriodScreen();
            },
            child: const Text('Nhập tay'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              HealthService.openHealthConnectInstall();
            },
            child: const Text('Cài Health Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHealthPermissionDeniedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể đồng bộ'),
        content: const Text(
          'Bạn chưa cấp quyền đọc dữ liệu chu kỳ. Tính năng theo dõi vẫn hoạt động bình thường khi nhập tay trong MomCare+.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openAddPeriodScreen();
            },
            child: const Text('Nhập tay'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPeriodScreen({MenstrualCycleModel? cycle}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPeriodScreen(cycle: cycle)),
    );
    if (result == true && mounted) {
      _loadCycles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final averageCycleLength = HealthService.calculateAverageCycleLength(
      _cycles,
    );
    final regularity = HealthService.cycleRegularity(_cycles);
    final today = DateTime.now();
    // Rolled-forward dates are not a current estimate: while late or stale
    // the calendar and "Dự đoán" give way to the same message as Hôm nay.
    final computed = CyclePrediction.compute(_cycles, today: today);
    final prediction = computed?.isLateOrStale == true ? null : computed;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Theo dõi chu kỳ'),
              actions: [
                if (HealthService.isAvailable)
                  IconButton(
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    onPressed: _isSyncing ? null : _syncFromHealthKit,
                    tooltip: 'Đồng bộ từ ứng dụng Sức khỏe',
                  ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              key: const ValueKey('cycle-planner-scroll'),
              padding: const EdgeInsets.only(bottom: AppSpacing.fabClearance),
              child: Column(
                children: [
                  // Calendar
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: TableCalendar(
                      locale: AppCalendarStyle.locale,
                      startingDayOfWeek: AppCalendarStyle.startingDayOfWeek,
                      availableCalendarFormats: AppCalendarStyle.formats,
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: AppCalendarStyle.calendar(context),
                      daysOfWeekStyle: AppCalendarStyle.daysOfWeek(context),
                      headerStyle: AppCalendarStyle.header(context),
                      rowHeight: AppCalendarStyle.rowHeight(context),
                      daysOfWeekHeight: AppCalendarStyle.daysOfWeekHeight(
                        context,
                      ),
                      calendarBuilders: CalendarBuilders(
                        headerTitleBuilder: AppCalendarStyle.headerTitleBuilder,
                        dowBuilder: AppCalendarStyle.daysOfWeekBuilder,
                        markerBuilder: (context, date, events) {
                          return _buildDayMarker(date, prediction);
                        },
                      ),
                    ),
                  ),

                  // Stats
                  _buildStatsCard(
                    theme,
                    averageCycleLength,
                    regularity,
                    _cycles.length,
                  ),

                  // Predictions
                  if (prediction != null)
                    _buildPredictionsCard(theme, prediction)
                  else if (computed != null)
                    Card(
                      key: const ValueKey('cycle-late-state'),
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LatePeriodSummary(cycles: _cycles, today: today),
                      ),
                    ),

                  // Recorded periods (edit / delete)
                  if (_cycles.isNotEmpty) _buildRecordedPeriodsCard(theme),

                  // Quick Actions
                  _buildQuickActionsCard(theme),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPeriodScreen,
        icon: const Icon(Icons.add),
        label: const Text('Thêm kỳ kinh'),
      ),
    );
  }

  Widget? _buildDayMarker(DateTime date, CyclePrediction? prediction) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    bool within(DateTime start, DateTime end) =>
        !normalizedDate.isBefore(start) && !normalizedDate.isAfter(end);

    // Check if it's a period day from cycles
    bool isPeriodDay = false;
    for (final cycle in _cycles) {
      final start = DateTime(
        cycle.startDate.year,
        cycle.startDate.month,
        cycle.startDate.day,
      );
      final end = cycle.endDate != null
          ? DateTime(
              cycle.endDate!.year,
              cycle.endDate!.month,
              cycle.endDate!.day,
            )
          : start.add(const Duration(days: 5)); // Default 5 days if no end

      if ((normalizedDate.isAtSameMomentAs(start) ||
              normalizedDate.isAfter(start)) &&
          normalizedDate.isBefore(end.add(const Duration(days: 1)))) {
        isPeriodDay = true;
        break;
      }
    }

    if (isPeriodDay) return _marker(CycleMarkerKind.period);

    if (prediction == null) return null;

    if (within(prediction.earliestOvulation, prediction.latestOvulation)) {
      return _marker(CycleMarkerKind.ovulation);
    }
    if (within(prediction.fertileStart, prediction.fertileEnd)) {
      return _marker(CycleMarkerKind.fertile);
    }
    if (within(prediction.earliestPeriod, prediction.latestPeriod)) {
      return _marker(CycleMarkerKind.predictedPeriod);
    }
    return null;
  }

  Widget _marker(CycleMarkerKind kind) {
    return Positioned(
      bottom: 2,
      child: CycleMarker(
        key: ValueKey('cycle-marker-${kind.name}'),
        kind: kind,
      ),
    );
  }

  Widget _buildStatsCard(
    ThemeData theme,
    int avgLength,
    CycleRegularity regularity,
    int totalCycles,
  ) {
    final avgLengthIsDefault = HealthService.cycleLengths(_cycles).isEmpty;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê chu kỳ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                _buildStatItem(
                  icon: Icons.calendar_month,
                  label: 'TB chu kỳ',
                  value: '$avgLength ngày',
                  color: theme.colorScheme.primary,
                ),
                _buildStatItem(
                  icon: switch (regularity) {
                    CycleRegularity.regular => Icons.check_circle,
                    CycleRegularity.irregular => Icons.warning,
                    CycleRegularity.insufficientData => Icons.hourglass_empty,
                  },
                  label: 'Trạng thái',
                  value: switch (regularity) {
                    CycleRegularity.regular => 'Đều',
                    CycleRegularity.irregular => 'Không đều',
                    CycleRegularity.insufficientData => 'Chưa đủ dữ liệu',
                  },
                  color: switch (regularity) {
                    CycleRegularity.regular => context.semantic.success,
                    CycleRegularity.irregular => context.semantic.warning,
                    CycleRegularity.insufficientData => Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  },
                ),
                _buildStatItem(
                  icon: Icons.history,
                  label: 'Đã ghi',
                  value: '$totalCycles kỳ kinh',
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            if (avgLengthIsDefault) ...[
              const SizedBox(height: 12),
              Text(
                'Cần ít nhất 2 kỳ kinh để tính độ dài chu kỳ. Hiện đang dùng giá trị tham khảo 28 ngày.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Equal columns: long values wrap inside their own column at large fonts.
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(ThemeData theme, CyclePrediction prediction) {
    final guidance = ContentPackService.fertileGuidance;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dự đoán',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const _PredictionMarker(CycleMarkerKind.predictedPeriod),
              title: const Text('Kỳ kinh tiếp theo'),
              subtitle: _PredictionDates(
                prediction.earliestPeriod,
                prediction.latestPeriod,
              ),
            ),
            ListTile(
              leading: const _PredictionMarker(CycleMarkerKind.ovulation),
              title: const Text('Ngày rụng trứng dự kiến'),
              subtitle: _PredictionDates(
                prediction.earliestOvulation,
                prediction.latestOvulation,
              ),
            ),
            ListTile(
              leading: const _PredictionMarker(CycleMarkerKind.fertile),
              title: const Text('Cửa sổ thụ thai'),
              subtitle: Text(
                DateFormatter.formatDateRange(
                  prediction.fertileStart,
                  prediction.fertileEnd,
                ),
              ),
            ),
            if (!guidance.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                guidance.confidenceLine(prediction),
                key: const ValueKey('cycle-confidence'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(guidance.confidenceNote(prediction), style: muted),
              const SizedBox(height: AppSpacing.xs),
              Text(guidance.text('ovulation_note'), style: muted),
              if (prediction.hasCycleOutsideTypicalRange) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(guidance.text('outside_range_note'), style: muted),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(guidance.text('not_contraception'), style: muted),
              if (guidance.isDraft) ...[
                const SizedBox(height: AppSpacing.md),
                const DraftContentNote(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordedPeriodsCard(ThemeData theme) {
    final recent = _cycles.take(6).toList();
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kỳ kinh đã ghi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chạm vào một kỳ kinh để sửa hoặc xóa.',
              style: theme.textTheme.bodySmall,
            ),
            ...recent.map((cycle) {
              final end = cycle.endDate;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  cycle.isFromHealthKit ? Icons.sync : Icons.water_drop,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  end == null
                      ? 'Bắt đầu ${DateFormatter.formatDate(cycle.startDate)}'
                      : DateFormatter.formatDateRange(cycle.startDate, end),
                ),
                subtitle: cycle.cycleLengthDays != null
                    ? Text('Chu kỳ ${cycle.cycleLengthDays} ngày')
                    : null,
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _openAddPeriodScreen(cycle: cycle),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chú giải lịch',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8),
              child: const CycleMarkerLegend(),
            ),
            if (HealthService.isAvailable) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _syncFromHealthKit,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Đồng bộ từ Sức khỏe'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trailing countdown of a "Dự đoán" range, worded as on Hôm nay. Capped so
/// "Đã qua 12 ngày" wraps
/// at large fonts instead of squeezing the row title.
/// Date range of a "Dự đoán" row with its countdown below it. The countdown
/// is not a ListTile `trailing`: that slot has a fixed height and clips the
/// longer labels at large text sizes.
class _PredictionDates extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const _PredictionDates(this.start, this.end);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormatter.formatDateRange(start, end)),
        Text(
          RangeCountdown.of(start, end, DateTime.now()).label(
            ContentPackService.fertileGuidance.text('ovulation_in_range'),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Leading mark of a "Dự đoán" row: the same shape and colour as the calendar
/// and its legend, so one meaning has one look everywhere.
class _PredictionMarker extends StatelessWidget {
  final CycleMarkerKind kind;

  const _PredictionMarker(this.kind);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(child: CycleMarker(kind: kind, size: 16)),
    );
  }
}
