import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/health_service.dart';
import 'add_period_screen.dart';

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
              backgroundColor: Colors.orange,
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
              backgroundColor: Colors.orange,
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
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload
      await _loadCycles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đồng bộ: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final nextPeriod = HealthService.predictNextPeriod(_cycles);
    final nextOvulation = HealthService.predictNextOvulation(_cycles);
    final fertileWindow = HealthService.predictFertileWindow(_cycles);

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
              child: Column(
                children: [
                  // Calendar
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: TableCalendar(
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
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          return _buildDayMarker(
                            date,
                            fertileWindow,
                            nextOvulation,
                            nextPeriod,
                          );
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
                  if (nextPeriod != null || nextOvulation != null)
                    _buildPredictionsCard(
                      theme,
                      nextPeriod,
                      nextOvulation,
                      fertileWindow,
                    ),

                  // Recorded periods (edit / delete)
                  if (_cycles.isNotEmpty) _buildRecordedPeriodsCard(theme),

                  // Quick Actions
                  _buildQuickActionsCard(theme),

                  const SizedBox(height: 16),
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

  Widget? _buildDayMarker(
    DateTime date,
    List<DateTime>? fertileWindow,
    DateTime? ovulation,
    DateTime? nextPeriod,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedOvulation = ovulation != null
        ? DateTime(ovulation.year, ovulation.month, ovulation.day)
        : null;
    final normalizedNextPeriod = nextPeriod != null
        ? DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day)
        : null;

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

    if (isPeriodDay) {
      return Positioned(
        bottom: 1,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
      );
    }

    if (normalizedOvulation != null &&
        normalizedDate.isAtSameMomentAs(normalizedOvulation)) {
      return Positioned(
        bottom: 1,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
      );
    }

    if (fertileWindow != null) {
      for (final fertileDay in fertileWindow) {
        final normalized = DateTime(
          fertileDay.year,
          fertileDay.month,
          fertileDay.day,
        );
        if (normalizedDate.isAtSameMomentAs(normalized)) {
          return Positioned(
            bottom: 1,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: 0.7),
              ),
            ),
          );
        }
      }
    }

    if (normalizedNextPeriod != null &&
        normalizedDate.isAtSameMomentAs(normalizedNextPeriod)) {
      return Positioned(
        bottom: 1,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return null;
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.calendar_month,
                  label: 'TB chu kỳ',
                  value: '$avgLength ngày',
                  color: theme.primaryColor,
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
                    CycleRegularity.regular => Colors.green,
                    CycleRegularity.irregular => Colors.orange,
                    CycleRegularity.insufficientData => Colors.grey,
                  },
                ),
                _buildStatItem(
                  icon: Icons.history,
                  label: 'Đã ghi',
                  value: '$totalCycles kỳ kinh',
                  color: Colors.purple,
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
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPredictionsCard(
    ThemeData theme,
    DateTime? nextPeriod,
    DateTime? nextOvulation,
    List<DateTime>? fertileWindow,
  ) {
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
            if (nextPeriod != null)
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.red),
                title: const Text('Kỳ kinh tiếp theo'),
                subtitle: Text(_formatDate(nextPeriod)),
                trailing: Text(
                  '${nextPeriod.difference(DateTime.now()).inDays} ngày',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (nextOvulation != null)
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.blue),
                title: const Text('Ngày rụng trứng dự kiến'),
                subtitle: Text(_formatDate(nextOvulation)),
                trailing: Text(
                  '${nextOvulation.difference(DateTime.now()).inDays} ngày',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (fertileWindow != null && fertileWindow.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: const Text('Cửa sổ thụ thai'),
                subtitle: Text(
                  '${_formatDate(fertileWindow.first)} - ${_formatDate(fertileWindow.last)}',
                ),
              ),
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
                  color: Colors.red,
                ),
                title: Text(
                  end == null
                      ? 'Bắt đầu ${_formatDate(cycle.startDate)}'
                      : '${_formatDate(cycle.startDate)} - ${_formatDate(end)}',
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
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildLegendItem(Colors.red, 'Kỳ kinh'),
                  _buildLegendItem(Colors.blue, 'Rụng trứng'),
                  _buildLegendItem(
                    Colors.green.withValues(alpha: 0.7),
                    'Dễ thụ thai',
                  ),
                ],
              ),
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
