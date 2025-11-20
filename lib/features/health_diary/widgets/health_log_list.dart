import 'package:flutter/material.dart';
import '../../../core/models/health_log_model.dart';
import '../../../core/utils/date_formatter.dart';

class HealthLogList extends StatelessWidget {
  final List<HealthLogModel> healthLogs;
  final Function(HealthLogModel) onDelete;
  final Function(HealthLogModel) onEdit;

  const HealthLogList({
    super.key,
    required this.healthLogs,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: healthLogs.length,
          itemBuilder: (context, index) {
            final log = healthLogs[index];
            return _buildLogCard(context, log);
          },
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, HealthLogModel log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onEdit(log),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatDate(log.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptionsMenu(context, log),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (log.weight != null)
                    _buildChip(
                      context,
                      Icons.monitor_weight,
                      '${log.weight!.toStringAsFixed(1)} kg',
                      Colors.blue,
                    ),
                  if (log.systolicBP != null && log.diastolicBP != null)
                    _buildChip(
                      context,
                      Icons.favorite,
                      '${log.systolicBP}/${log.diastolicBP}',
                      Colors.red,
                    ),
                  if (log.mood != null)
                    _buildChip(
                      context,
                      Icons.mood,
                      log.mood!,
                      Colors.orange,
                    ),
                ],
              ),
              if (log.symptoms != null && log.symptoms!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: log.symptoms!.map((symptom) {
                    return Chip(
                      label: Text(symptom),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.grey[200],
                    );
                  }).toList(),
                ),
              ],
              if (log.notes != null && log.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  log.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, HealthLogModel log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                onEdit(log);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, log);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, HealthLogModel log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhật ký'),
        content: const Text('Bạn có chắc muốn xóa nhật ký sức khỏe này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete(log);
    }
  }
}
