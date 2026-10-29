import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../utils/app_logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AppLogger _logger = AppLogger.instance;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'momcare_channel',
        'Thông báo MomCare+',
        channelDescription: 'Thông báo từ ứng dụng MomCare+',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    tz.initializeTimeZones();
    _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // Permission is requested only when the user opts in to a reminder.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// `tz.local` defaults to UTC. Pick the IANA zone that matches the device
  /// offset so daily reminders fire at the chosen local time.
  static void _configureLocalTimeZone() {
    try {
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      if (offsetMs == const Duration(hours: 7).inMilliseconds) {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
        return;
      }
      final nowMs = now.millisecondsSinceEpoch;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.timeZone(nowMs).offset == offsetMs) {
          tz.setLocalLocation(location);
          return;
        }
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Could not resolve local time zone, using UTC',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deterministic 31-bit notification id (FNV-1a) for a string key.
  /// `String.hashCode` is not guaranteed to be stable across runs.
  static int stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  static Future<bool> requestPermissions() async {
    final iosAllowed = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidAllowed = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return iosAllowed ?? androidAllowed ?? true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Tapping a notification brings the app to the foreground; the app opens
    // on its default screen. Payloads are reserved for future deep links.
    _logger.debug('Notification tapped: ${response.payload}');
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(id, title, body, _details, payload: payload);
  }

  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    bool requestPermission = true,
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle,
  }) async {
    if (requestPermission) {
      final allowed = await requestPermissions();
      if (!allowed) return false;
    }

    final when = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        payload: payload,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      return true;
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted' ||
          androidScheduleMode == AndroidScheduleMode.inexactAllowWhileIdle) {
        _logger.warning('Failed to schedule notification $id', error: e);
        return false;
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      return true;
    } catch (e) {
      _logger.warning('Failed to schedule notification $id', error: e);
      return false;
    }
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
    bool requestPermission = true,
  }) async {
    final notificationTime = appointmentTime.subtract(
      Duration(minutes: minutesBefore),
    );

    if (notificationTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: id,
        title: 'Nhắc lịch hẹn',
        body: '$title sau ${_formatLeadTime(minutesBefore)}',
        scheduledDate: notificationTime,
        payload: 'appointment',
        requestPermission: requestPermission,
      );
    }
  }

  static String _formatLeadTime(int minutes) {
    if (minutes >= 1440 && minutes % 1440 == 0) {
      return '${minutes ~/ 1440} ngày';
    }
    if (minutes >= 60 && minutes % 60 == 0) return '${minutes ~/ 60} giờ';
    return '$minutes phút';
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
    await scheduleNotification(
      id: id,
      title: 'Gợi ý hôm nay',
      body: tip,
      scheduledDate: nextInstanceOf(hour, 0),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Next occurrence of [hour]:[minute] in local time (today or tomorrow).
  static DateTime nextInstanceOf(int hour, int minute, {DateTime? now}) {
    final current = now ?? DateTime.now();
    var scheduled = DateTime(
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(current)) {
      scheduled = DateTime(
        current.year,
        current.month,
        current.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  /// Daily repeating habit reminder at [hour]:[minute].
  static Future<bool> scheduleDailyHabitReminder({
    required int id,
    required String title,
    required int hour,
    required int minute,
    bool requestPermission = true,
  }) async {
    return scheduleNotification(
      id: id,
      title: 'Nhắc sức khỏe',
      body: title,
      scheduledDate: nextInstanceOf(hour, minute),
      payload: 'habit:$id',
      matchDateTimeComponents: DateTimeComponents.time,
      requestPermission: requestPermission,
    );
  }
}
