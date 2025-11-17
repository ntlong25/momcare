import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../core/utils/navigation_helper.dart';

class WeightGainChart extends StatelessWidget {
  final PregnancyModel pregnancy;

  const WeightGainChart({super.key, required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final healthLogs = DatabaseService.getAllHealthLogs()
        .where((log) => log.weight != null)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Weight Gain',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => NavigationHelper.toAddHealthLog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (healthLogs.isEmpty)
              _buildEmptyState(context)
            else
              Column(
                children: [
                  _buildWeightStats(context, healthLogs),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _buildChart(context, healthLogs),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 150,
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
            'No weight data yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => NavigationHelper.toAddHealthLog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Weight'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStats(BuildContext context, List healthLogs) {
    final currentWeight = healthLogs.first.weight;
    final preWeight = pregnancy.prePregnancyWeight ?? currentWeight;
    final weightGain = currentWeight - preWeight;

    final recommendedGain = pregnancy.bmi != null
        ? BMICalculator.getRecommendedWeightGain(pregnancy.bmi!)
        : {'min': 11.5, 'max': 16.0};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                'Current',
                '${currentWeight.toStringAsFixed(1)} kg',
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildStatColumn(
                context,
                'Gained',
                '${weightGain >= 0 ? '+' : ''}${weightGain.toStringAsFixed(1)} kg',
                weightGain >= 0 ? Colors.green : Colors.red,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildStatColumn(
                context,
                'Target',
                '${recommendedGain['min']?.toStringAsFixed(1)}-${recommendedGain['max']?.toStringAsFixed(1)} kg',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List healthLogs) {
    final sortedLogs = healthLogs.reversed.toList();
    final spots = sortedLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    return LineChart(
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
                if (value.toInt() >= sortedLogs.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt() + 1}',
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
    );
  }
}
