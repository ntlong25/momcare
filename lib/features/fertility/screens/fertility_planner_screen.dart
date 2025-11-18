import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/health_service.dart';
import 'add_period_screen.dart';
import 'gender_selection_screen.dart';

class FertilityPlannerScreen extends ConsumerStatefulWidget {
  const FertilityPlannerScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cycles = DatabaseService.getAllMenstrualCycles();
      setState(() {
        _cycles = cycles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFromHealthKit() async {
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
                  'Health data not available on this device'),
              backgroundColor: Colors.orange,
            ),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Permission denied. Please allow access in Settings'),
              backgroundColor: Colors.red,
            ),
          );
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
              content: Text('No menstrual data found in Health app'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      // Save to database
      for (final cycle in healthCycles) {
        await DatabaseService.saveMenstrualCycle(cycle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced ${healthCycles.length} cycles successfully'),
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
            content: Text('Error syncing: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final averageCycleLength = HealthService.calculateAverageCycleLength(_cycles);
    final areCyclesRegular = HealthService.areCyclesRegular(_cycles);
    final nextPeriod = HealthService.predictNextPeriod(_cycles);
    final nextOvulation = HealthService.predictNextOvulation(_cycles);
    final fertileWindow = HealthService.predictFertileWindow(_cycles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertility Planner'),
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
              tooltip: 'Sync from Health App',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                          return _buildDayMarker(date, fertileWindow, nextOvulation, nextPeriod);
                        },
                      ),
                    ),
                  ),

                  // Stats
                  _buildStatsCard(theme, averageCycleLength, areCyclesRegular, _cycles.length),

                  // Predictions
                  if (nextPeriod != null || nextOvulation != null)
                    _buildPredictionsCard(theme, nextPeriod, nextOvulation, fertileWindow),

                  // Quick Actions
                  _buildQuickActionsCard(theme),

                  const SizedBox(height: 16),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPeriodScreen()),
          );
          if (result == true) {
            _loadCycles();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Period'),
      ),
    );
  }

  Widget? _buildDayMarker(
      DateTime date, List<DateTime>? fertileWindow, DateTime? ovulation, DateTime? nextPeriod) {
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
          cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      final end = cycle.endDate != null
          ? DateTime(
              cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day)
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
            fertileDay.year, fertileDay.month, fertileDay.day);
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
      ThemeData theme, int avgLength, bool isRegular, int totalCycles) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Statistics',
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
                  label: 'Avg Cycle',
                  value: '$avgLength days',
                  color: theme.primaryColor,
                ),
                _buildStatItem(
                  icon: isRegular ? Icons.check_circle : Icons.warning,
                  label: 'Status',
                  value: isRegular ? 'Regular' : 'Irregular',
                  color: isRegular ? Colors.green : Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.history,
                  label: 'Tracked',
                  value: '$totalCycles cycles',
                  color: Colors.purple,
                ),
              ],
            ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionsCard(ThemeData theme, DateTime? nextPeriod,
      DateTime? nextOvulation, List<DateTime>? fertileWindow) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predictions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (nextPeriod != null)
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.red),
                title: const Text('Next Period'),
                subtitle: Text(_formatDate(nextPeriod)),
                trailing: Text(
                  '${nextPeriod.difference(DateTime.now()).inDays} days',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (nextOvulation != null)
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.blue),
                title: const Text('Next Ovulation'),
                subtitle: Text(_formatDate(nextOvulation)),
                trailing: Text(
                  '${nextOvulation.difference(DateTime.now()).inDays} days',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (fertileWindow != null && fertileWindow.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: const Text('Fertile Window'),
                subtitle: Text(
                    '${_formatDate(fertileWindow.first)} - ${_formatDate(fertileWindow.last)}'),
              ),
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
              'Learn More',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.wc, color: Colors.purple),
              title: const Text('Gender Selection Tips'),
              subtitle: const Text('Learn about methods to influence gender'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GenderSelectionScreen()),
                );
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildLegendItem(Colors.red, 'Period'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.blue, 'Ovulation'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.green.withValues(alpha: 0.7), 'Fertile'),
                ],
              ),
            ),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
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
