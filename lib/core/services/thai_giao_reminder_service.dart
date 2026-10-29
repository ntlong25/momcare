import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'notification_service.dart';

/// Opt-in daily thai giáo reminder setting (off by default, 20:00).
class ThaiGiaoReminderSettings {
  static const int defaultHour = 20;
  static const int defaultMinute = 0;

  final bool enabled;
  final int hour;
  final int minute;

  const ThaiGiaoReminderSettings({
    this.enabled = false,
    this.hour = defaultHour,
    this.minute = defaultMinute,
  });

  ThaiGiaoReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ThaiGiaoReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
  };

  factory ThaiGiaoReminderSettings.fromJson(Object? json) {
    if (json is! Map) return const ThaiGiaoReminderSettings();
    final hour = json['hour'];
    final minute = json['minute'];
    return ThaiGiaoReminderSettings(
      enabled: json['enabled'] == true,
      hour: hour is int && hour >= 0 && hour < 24 ? hour : defaultHour,
      minute: minute is int && minute >= 0 && minute < 60
          ? minute
          : defaultMinute,
    );
  }
}

class ThaiGiaoReminderService {
  static const String title = 'Thai giáo hôm nay';

  /// A repeating notification carries fixed text, so the body is generic.
  static const String body =
      'Dành vài phút cho hoạt động thai giáo hôm nay cùng bé.';

  static int get notificationId =>
      NotificationService.stableId('thai_giao:daily');

  static Future<ThaiGiaoReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.thaiGiaoReminderKey);
    if (raw == null) return const ThaiGiaoReminderSettings();
    try {
      return ThaiGiaoReminderSettings.fromJson(jsonDecode(raw));
    } catch (_) {
      return const ThaiGiaoReminderSettings();
    }
  }

  static Future<void> save(ThaiGiaoReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.thaiGiaoReminderKey,
      jsonEncode(settings.toJson()),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.thaiGiaoReminderKey);
  }

  /// Enables the daily reminder at [hour]:[minute]. Returns false (and keeps
  /// the reminder off) when notification permission is denied.
  static Future<bool> enable(int hour, int minute) async {
    final allowed = await _schedule(hour, minute, requestPermission: true);
    if (!allowed) {
      await NotificationService.cancelNotification(notificationId);
      await save(
        ThaiGiaoReminderSettings(enabled: false, hour: hour, minute: minute),
      );
      return false;
    }
    await save(
      ThaiGiaoReminderSettings(enabled: true, hour: hour, minute: minute),
    );
    return true;
  }

  static Future<void> disable() async {
    final current = await load();
    await NotificationService.cancelNotification(notificationId);
    await save(current.copyWith(enabled: false));
  }

  /// Re-registers the reminder on app start when the user enabled it.
  static Future<void> rescheduleIfEnabled() async {
    final settings = await load();
    if (!settings.enabled) return;
    await _schedule(settings.hour, settings.minute, requestPermission: false);
  }

  static Future<bool> _schedule(
    int hour,
    int minute, {
    required bool requestPermission,
  }) {
    return NotificationService.scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: NotificationService.nextInstanceOf(hour, minute),
      payload: 'thai_giao:daily',
      matchDateTimeComponents: DateTimeComponents.time,
      requestPermission: requestPermission,
    );
  }
}
