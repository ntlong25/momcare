import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screens based on payload
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'momcare_channel',
      'Thông báo MomCare+',
      channelDescription: 'Thông báo từ ứng dụng MomCare+',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'momcare_channel',
      'Thông báo MomCare+',
      channelDescription: 'Thông báo từ ứng dụng MomCare+',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      // iOS: không còn uiLocalNotificationDateInterpretation
      // Android (API mới) thay cho androidAllowWhileIdle:
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required DateTime appointmentTime,
    int minutesBefore = 60,
  }) async {
    final notificationTime = appointmentTime.subtract(
      Duration(minutes: minutesBefore),
    );

    if (notificationTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Nhắc lịch hẹn',
        body: '$title sau $minutesBefore phút',
        scheduledDate: notificationTime,
      );
    }
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime reminderTime,
  }) async {
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Nhắc thuốc',
        body: 'Đến giờ dùng $medicationName',
        scheduledDate: reminderTime,
      );
    }
  }

  static Future<void> scheduleDailyTip({
    required int id,
    required String tip,
    required int hour,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: id,
      title: 'Gợi ý hôm nay',
      body: tip,
      scheduledDate: scheduledDate,
    );
  }
}
