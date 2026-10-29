import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../tracking/screens/week_detail_screen.dart';

/// "Việc tuần này": up to [maxItems] todos of the current week, with a link
/// to the full week page. Hidden when the week has no todos.
class WeekTodoCard extends StatelessWidget {
  static const int maxItems = 5;

  final int week;

  const WeekTodoCard({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final todos = ContentPackService.weekDetail(week).todoThisWeek;
    if (todos.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Việc tuần này',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  key: const ValueKey('week-todo-see-all'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WeekDetailScreen(initialWeek: week),
                    ),
                  ),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final todo in todos.take(maxItems))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(todo, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
