import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/health_log_model.dart';
import '../../../core/theme/app_tokens.dart';

class HealthChartsCard extends StatefulWidget {
  final List<HealthLogModel> healthLogs;

  const HealthChartsCard({super.key, required this.healthLogs});

  @override
  State<HealthChartsCard> createState() => _HealthChartsCardState();
}

class _HealthChartsCardState extends State<HealthChartsCard> {
  String _selectedChart = 'weight';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChartSelector(),
        const SizedBox(height: 16),
        if (_selectedChart == 'weight')
          _buildWeightChart()
        else if (_selectedChart == 'bp')
          _buildBloodPressureChart()
        else
          _buildMoodChart(),
      ],
    );
  }

  Widget _buildChartSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _buildSelectorButton(
                'Cân nặng',
                'weight',
                Icons.monitor_weight,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectorButton('Huyết áp', 'bp', Icons.favorite),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectorButton('Tâm trạng', 'mood', Icons.mood),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorButton(String label, String value, IconData icon) {
    final isSelected = _selectedChart == value;
    return InkWell(
      onTap: () => setState(() => _selectedChart = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    final logsWithWeight = widget.healthLogs
        .where((log) => log.weight != null)
        .toList()
        .reversed
        .toList();

    if (logsWithWeight.isEmpty) {
      return _buildEmptyChart('Chưa có dữ liệu cân nặng');
    }

    final spots = logsWithWeight.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight!);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xu hướng cân nặng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= logsWithWeight.length) {
                            return const Text('');
                          }
                          final date = logsWithWeight[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: _axisStyle(context),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}kg',
                            style: _axisStyle(context),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY:
                      spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5,
                  maxY:
                      spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.surface,
                            strokeWidth: 2,
                            strokeColor: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureChart() {
    final logsWithBP = widget.healthLogs
        .where((log) => log.systolicBP != null && log.diastolicBP != null)
        .toList()
        .reversed
        .toList();

    if (logsWithBP.isEmpty) {
      return _buildEmptyChart('Chưa có dữ liệu huyết áp');
    }

    final systolicSpots = logsWithBP.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.systolicBP!.toDouble());
    }).toList();

    final diastolicSpots = logsWithBP.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.diastolicBP!.toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xu hướng huyết áp',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendItem('Tâm thu', context.semantic.danger),
                const SizedBox(width: 16),
                _buildLegendItem('Tâm trương', context.semantic.info),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= logsWithBP.length) {
                            return const Text('');
                          }
                          final date = logsWithBP[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: _axisStyle(context),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: _axisStyle(context),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: (systolicSpots.length - 1).toDouble(),
                  minY: 40,
                  maxY: 160,
                  lineBarsData: [
                    LineChartBarData(
                      spots: systolicSpots,
                      isCurved: true,
                      color: context.semantic.danger,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.surface,
                            strokeWidth: 2,
                            strokeColor: context.semantic.danger,
                          );
                        },
                      ),
                    ),
                    LineChartBarData(
                      spots: diastolicSpots,
                      isCurved: true,
                      color: context.semantic.info,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.surface,
                            strokeWidth: 2,
                            strokeColor: context.semantic.info,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart() {
    final logsWithMood = widget.healthLogs
        .where((log) => log.mood != null)
        .toList()
        .reversed
        .toList();

    if (logsWithMood.isEmpty) {
      return _buildEmptyChart('Chưa có dữ liệu tâm trạng');
    }

    final moodCounts = <String, int>{};
    for (var log in logsWithMood) {
      moodCounts[log.mood!] = (moodCounts[log.mood!] ?? 0) + 1;
    }

    const moodTones = {
      'Vui vẻ': AppTone.warning,
      'Bình tĩnh': AppTone.info,
      'Lo lắng': AppTone.tertiary,
      'Mệt mỏi': AppTone.secondary,
      'Nhiều năng lượng': AppTone.success,
      'Khó chịu': AppTone.danger,
    };
    AppToneColors moodColors(String mood) =>
        (moodTones[mood] ?? AppTone.primary).of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân bố tâm trạng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: moodCounts.entries.map((entry) {
                          final percentage =
                              entry.value / logsWithMood.length * 100;
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(0)}%',
                            color: moodColors(entry.key).main,
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: moodColors(entry.key).onMain,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: moodCounts.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: moodColors(entry.key).main,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key} (${entry.value})',
                              style: _axisStyle(context),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Axis labels: onSurfaceVariant keeps >= 4.5:1 on the card surface.
  TextStyle? _axisStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall
      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Card(
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
