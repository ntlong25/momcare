import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/health_log_model.dart';

class HealthChartsCard extends StatefulWidget {
  final List<HealthLogModel> healthLogs;

  const HealthChartsCard({super.key, required this.healthLogs});

  @override
  State<HealthChartsCard> createState() => _HealthChartsCardState();
}

class _HealthChartsCardState extends State<HealthChartsCard> {
  String _selectedChart = 'weight'; // 'weight', 'bp', 'mood'

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
                'Weight',
                'weight',
                Icons.monitor_weight,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectorButton(
                'Blood Pressure',
                'bp',
                Icons.favorite,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSelectorButton(
                'Mood',
                'mood',
                Icons.mood,
              ),
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
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
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
              'Weight Trend',
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
                        color: Colors.grey[300]!,
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
                              style: Theme.of(context).textTheme.bodySmall,
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
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5,
                  maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.blue,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
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
              'Blood Pressure Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendItem('Systolic', Colors.red),
                const SizedBox(width: 16),
                _buildLegendItem('Diastolic', Colors.orange),
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
                        color: Colors.grey[300]!,
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
                              style: Theme.of(context).textTheme.bodySmall,
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
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
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
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.red,
                          );
                        },
                      ),
                    ),
                    LineChartBarData(
                      spots: diastolicSpots,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.orange,
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

    final moodColors = {
      'Happy': Colors.yellow[700]!,
      'Calm': Colors.blue[300]!,
      'Anxious': Colors.purple[300]!,
      'Tired': Colors.grey[400]!,
      'Energetic': Colors.green[400]!,
      'Uncomfortable': Colors.red[300]!,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
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
                          final percentage = (entry.value / logsWithMood.length * 100);
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${percentage.toStringAsFixed(0)}%',
                            color: moodColors[entry.key] ?? Colors.grey,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                color: moodColors[entry.key],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.key} (${entry.value})',
                              style: Theme.of(context).textTheme.bodySmall,
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
