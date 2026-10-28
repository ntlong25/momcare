import '../models/appointment_model.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Keeps scheduled appointment notifications in sync with appointment data.
class AppointmentReminderService {
  static int notificationIdFor(String appointmentId) =>
      NotificationService.stableId('appointment:$appointmentId');

  /// Cancels any reminder for the appointment (current and legacy ids).
  static Future<void> cancel(String appointmentId) async {
    try {
      await NotificationService.cancelNotification(
        notificationIdFor(appointmentId),
      );
      // Ids created before Phase 12 used String.hashCode.
      await NotificationService.cancelNotification(appointmentId.hashCode);
    } catch (_) {
      // Notification plugin unavailable (e.g. tests); nothing to cancel.
    }
  }

  /// Saves the appointment and (re)schedules or cancels its reminder.
  static Future<void> save(AppointmentModel appointment) async {
    await DatabaseService.saveAppointment(appointment);
    await sync(appointment);
  }

  /// Schedules the reminder when enabled, not completed and in the future;
  /// cancels it otherwise.
  static Future<void> sync(
    AppointmentModel appointment, {
    bool requestPermission = true,
  }) async {
    await cancel(appointment.id);
    if (!appointment.reminderEnabled || appointment.isCompleted) return;
    await NotificationService.scheduleAppointmentReminder(
      id: notificationIdFor(appointment.id),
      title: appointment.title,
      appointmentTime: appointment.dateTime,
      minutesBefore: appointment.reminderMinutesBefore,
      requestPermission: requestPermission,
    );
  }

  /// Deletes the appointment and its reminder.
  static Future<void> delete(String appointmentId) async {
    await DatabaseService.deleteAppointment(appointmentId);
    await cancel(appointmentId);
  }

  /// Re-registers reminders for upcoming appointments without prompting for
  /// permission (called on app start).
  static Future<void> rescheduleAll() async {
    for (final appointment in DatabaseService.getUpcomingAppointments()) {
      if (appointment.reminderEnabled) {
        await sync(appointment, requestPermission: false);
      }
    }
  }
}
