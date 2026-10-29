import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/maternal_habit_model.dart';
import 'notification_service.dart';

class MaternalHabitService {
  static const List<MaternalHabitModel> defaultHabits = [
    MaternalHabitModel(
      id: 'water',
      title: 'Uống đủ nước',
      category: 'Nước',
      description: 'Nhắc bạn uống nước đều trong ngày theo nhu cầu cơ thể.',
      reminderHour: 9,
      disclaimer: 'Điều chỉnh lượng nước theo hướng dẫn y tế nếu có bệnh nền.',
    ),
    MaternalHabitModel(
      id: 'iron',
      title: 'Bổ sung sắt',
      category: 'Vi chất',
      description: 'Ghi nhớ dùng sắt nếu bác sĩ đã hướng dẫn hoặc kê đơn.',
      reminderHour: 10,
      disclaimer: 'Không tự ý dùng hoặc đổi liều sắt khi chưa hỏi bác sĩ.',
    ),
    MaternalHabitModel(
      id: 'prenatal-vitamin',
      title: 'Vitamin trước sinh',
      category: 'Vi chất',
      description:
          'Theo dõi việc dùng vitamin trước sinh theo hướng dẫn của bác sĩ.',
      reminderHour: 20,
      disclaimer: 'Không thay thế tư vấn cá nhân từ nhân viên y tế.',
    ),
    MaternalHabitModel(
      id: 'appointment',
      title: 'Kiểm tra lịch khám',
      category: 'Lịch khám',
      description: 'Nhắc bạn xem lại lịch khám thai hoặc việc cần hỏi bác sĩ.',
      reminderHour: 19,
      disclaimer: 'Luôn đi khám sớm nếu có dấu hiệu bất thường.',
    ),
  ];

  static Future<List<MaternalHabitModel>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.maternalHabitsKey);
    final saved = raw == null
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(raw) as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
          );

    return defaultHabits
        .map((habit) => habit.applySavedState(saved[habit.id]))
        .toList();
  }

  static Future<void> saveHabit(MaternalHabitModel habit) async {
    final habits = await loadHabits();
    final updated = habits.map((item) {
      return item.id == habit.id ? habit : item;
    }).toList();
    await _saveHabits(updated);
  }

  static Future<MaternalHabitModel> setCompletedToday(
    MaternalHabitModel habit,
    bool completed,
  ) async {
    final updated = habit.copyWith(
      lastCompletedDate: completed ? DateTime.now() : DateTime(1970),
    );
    await saveHabit(updated);
    return updated;
  }

  static Future<bool> setReminderEnabled(
    MaternalHabitModel habit,
    bool enabled,
  ) async {
    final updated = habit.copyWith(reminderEnabled: enabled);

    if (enabled) {
      final allowed = await NotificationService.scheduleDailyHabitReminder(
        id: notificationIdFor(habit.id),
        title: habit.title,
        hour: habit.reminderHour,
        minute: habit.reminderMinute,
      );
      if (!allowed) return false;
      // Remove a possible legacy (pre-Phase 12) one-shot reminder.
      await NotificationService.cancelNotification(habit.id.hashCode);
    } else {
      await _cancelReminder(habit.id);
    }

    await saveHabit(updated);
    return true;
  }

  static Future<void> updateReminderTime(
    MaternalHabitModel habit,
    int hour,
    int minute,
  ) async {
    final updated = habit.copyWith(reminderHour: hour, reminderMinute: minute);
    await saveHabit(updated);
    if (updated.reminderEnabled) {
      await NotificationService.scheduleDailyHabitReminder(
        id: notificationIdFor(updated.id),
        title: updated.title,
        hour: hour,
        minute: minute,
      );
    }
  }

  /// Stable notification id for a habit reminder.
  static int notificationIdFor(String habitId) =>
      NotificationService.stableId('habit:$habitId');

  /// Re-registers daily reminders for enabled habits on app start (no
  /// permission prompt; reminders are only enabled after the user opted in).
  static Future<void> rescheduleEnabledReminders() async {
    final habits = await loadHabits();
    for (final habit in habits.where((h) => h.reminderEnabled)) {
      await NotificationService.cancelNotification(habit.id.hashCode);
      await NotificationService.scheduleDailyHabitReminder(
        id: notificationIdFor(habit.id),
        title: habit.title,
        hour: habit.reminderHour,
        minute: habit.reminderMinute,
        requestPermission: false,
      );
    }
  }

  static Future<void> _cancelReminder(String habitId) async {
    await NotificationService.cancelNotification(notificationIdFor(habitId));
    await NotificationService.cancelNotification(habitId.hashCode);
  }

  static Future<void> _saveHabits(List<MaternalHabitModel> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.maternalHabitsKey,
      jsonEncode({for (final habit in habits) habit.id: habit.toJson()}),
    );
  }
}
