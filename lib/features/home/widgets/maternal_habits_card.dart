import 'package:flutter/material.dart';

import '../../../core/models/maternal_habit_model.dart';
import '../../../core/services/maternal_habit_service.dart';

class MaternalHabitsCard extends StatefulWidget {
  const MaternalHabitsCard({super.key});

  @override
  State<MaternalHabitsCard> createState() => _MaternalHabitsCardState();
}

class _MaternalHabitsCardState extends State<MaternalHabitsCard> {
  List<MaternalHabitModel> _habits = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await MaternalHabitService.loadHabits();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = _habits.where((habit) => habit.isCompletedToday).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chăm sóc hôm nay',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!_loading)
                  Text(
                    '$completed/${_habits.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Theo dõi các thói quen cơ bản. Nhắc nhở tắt mặc định và chỉ bật khi bạn chọn.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ..._habits.map(_buildHabitTile),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitTile(MaternalHabitModel habit) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CheckboxListTile(
          value: habit.isCompletedToday,
          onChanged: (value) => _toggleCompleted(habit, value ?? false),
          title: Text(habit.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.description),
              const SizedBox(height: 4),
              Text(
                habit.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          secondary: IconButton(
            tooltip: habit.reminderEnabled ? 'Tắt nhắc nhở' : 'Bật nhắc nhở',
            icon: Icon(
              habit.reminderEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_none,
            ),
            onPressed: () => _toggleReminder(habit),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Future<void> _toggleCompleted(
    MaternalHabitModel habit,
    bool completed,
  ) async {
    await MaternalHabitService.setCompletedToday(habit, completed);
    await _loadHabits();
  }

  Future<void> _toggleReminder(MaternalHabitModel habit) async {
    if (habit.reminderEnabled) {
      await MaternalHabitService.setReminderEnabled(habit, false);
      await _loadHabits();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bật nhắc nhở sức khỏe'),
        content: Text(
          'MomCare+ sẽ chỉ dùng thông báo trên thiết bị để nhắc "${habit.title}". Bạn có thể tắt bất cứ lúc nào. Nội dung này không thay thế hướng dẫn của bác sĩ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chọn giờ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: habit.reminderHour,
        minute: habit.reminderMinute,
      ),
    );
    if (time == null || !mounted) return;

    await MaternalHabitService.updateReminderTime(
      habit,
      time.hour,
      time.minute,
    );
    final enabled = await MaternalHabitService.setReminderEnabled(
      habit.copyWith(reminderHour: time.hour, reminderMinute: time.minute),
      true,
    );

    if (!enabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn chưa cấp quyền thông báo. Checklist vẫn dùng được bình thường.',
          ),
        ),
      );
    }
    await _loadHabits();
  }
}
