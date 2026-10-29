import 'package:flutter/material.dart';
import '../../../core/models/health_log_model.dart';
import '../../../core/theme/app_tokens.dart';

class HealthStatsCard extends StatelessWidget {
  final List<HealthLogModel> healthLogs;

  const HealthStatsCard({super.key, required this.healthLogs});

  @override
  Widget build(BuildContext context) {
    final latestLog = healthLogs.firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số liệu mới nhất',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (latestLog != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Cân nặng',
                      latestLog.weight != null
                          ? '${latestLog.weight!.toStringAsFixed(1)} kg'
                          : 'Chưa có',
                      Icons.monitor_weight,
                      AppTone.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Huyết áp',
                      latestLog.systolicBP != null &&
                              latestLog.diastolicBP != null
                          ? '${latestLog.systolicBP}/${latestLog.diastolicBP}'
                          : 'Chưa có',
                      Icons.favorite,
                      AppTone.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Tâm trạng',
                      latestLog.mood ?? 'Chưa theo dõi',
                      Icons.mood,
                      AppTone.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Tổng ghi nhận',
                      '${healthLogs.length}',
                      Icons.list,
                      AppTone.success,
                    ),
                  ),
                ],
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có dữ liệu'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    AppTone tone,
  ) {
    final colors = tone.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.onContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.onContainer),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onContainer,
            ),
          ),
        ],
      ),
    );
  }
}
