import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/theme/app_tokens.dart';

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
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tăng cân',
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu cân nặng',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => NavigationHelper.toAddHealthLog(context),
            icon: const Icon(Icons.add),
            label: const Text('Thêm cân nặng'),
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
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                'Hiện tại',
                '${currentWeight.toStringAsFixed(1)} kg',
                context.semantic.info,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              _buildStatColumn(
                context,
                'Đã tăng',
                '${weightGain >= 0 ? '+' : ''}${weightGain.toStringAsFixed(1)} kg',
                weightGain >= 0
                    ? context.semantic.success
                    : context.semantic.danger,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              _buildStatColumn(
                context,
                'Mục tiêu',
                '${recommendedGain['min']?.toStringAsFixed(1)}-${recommendedGain['max']?.toStringAsFixed(1)} kg',
                context.semantic.warning,
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List healthLogs) {
    final sortedLogs = healthLogs.reversed.toList();
    final scheme = Theme.of(context).colorScheme;
    final axisStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
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
                if (value.toInt() >= sortedLogs.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${value.toInt() + 1}', style: axisStyle),
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
                return Text(value.toInt().toString(), style: axisStyle);
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: scheme.outline),
            bottom: BorderSide(color: scheme.outline),
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
            color: scheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: scheme.surface,
                  strokeWidth: 2,
                  strokeColor: scheme.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
