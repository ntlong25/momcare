import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../data/content_pack_service.dart';
import '../models/fertile_guidance.dart';
import '../models/fertility_log_model.dart';
import '../models/menstrual_cycle_model.dart';
import 'cycle_prediction.dart';
import 'database_service.dart';
import 'fertility_log_service.dart';
import 'notification_service.dart';

/// What a fertile-day notification says when the phone is unlocked.
enum FertilityNotificationStyle {
  /// The neutral text everywhere; the default on iOS.
  discreet,

  /// Says what the day is, as an estimate; the default on Android, where the
  /// notification has a neutral public version.
  full,
}

/// Opt-in notifications of the fertile window. Off by default; kept in the
/// encrypted preferences box, because the setting itself is sensitive.
@immutable
class FertilityReminderSettings {
  static const int defaultHour = 9;
  static const int defaultMinute = 0;

  /// On the first day of the predicted window and on peak days.
  final bool windowEnabled;

  /// On the days around the predicted ovulation, until a positive LH test.
  final bool lhEnabled;
  final int hour;
  final int minute;

  /// The user's choice; null until they make one.
  final FertilityNotificationStyle? chosenStyle;

  const FertilityReminderSettings({
    this.windowEnabled = false,
    this.lhEnabled = false,
    this.hour = defaultHour,
    this.minute = defaultMinute,
    this.chosenStyle,
  });

  /// iOS has no per-notification hiding, so only Android defaults to full.
  static FertilityNotificationStyle get defaultStyle =>
      defaultTargetPlatform == TargetPlatform.android
      ? FertilityNotificationStyle.full
      : FertilityNotificationStyle.discreet;

  /// A stored choice wins over the platform default.
  FertilityNotificationStyle get style => chosenStyle ?? defaultStyle;

  bool get anyEnabled => windowEnabled || lhEnabled;

  FertilityReminderSettings copyWith({
    bool? windowEnabled,
    bool? lhEnabled,
    int? hour,
    int? minute,
    FertilityNotificationStyle? style,
  }) {
    return FertilityReminderSettings(
      windowEnabled: windowEnabled ?? this.windowEnabled,
      lhEnabled: lhEnabled ?? this.lhEnabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      chosenStyle: style ?? chosenStyle,
    );
  }

  Map<String, dynamic> toJson() => {
    'window': windowEnabled,
    'lh': lhEnabled,
    'hour': hour,
    'minute': minute,
    'style': chosenStyle?.name,
  };

  factory FertilityReminderSettings.fromJson(Object? json) {
    if (json is! Map) return const FertilityReminderSettings();
    final hour = json['hour'];
    final minute = json['minute'];
    return FertilityReminderSettings(
      windowEnabled: json['window'] == true,
      lhEnabled: json['lh'] == true,
      hour: hour is int && hour >= 0 && hour < 24 ? hour : defaultHour,
      minute: minute is int && minute >= 0 && minute < 60
          ? minute
          : defaultMinute,
      chosenStyle: FertilityNotificationStyle.values.asNameMap()[json['style']],
    );
  }
}

enum ReminderKind { fertileFirstDay, fertilePeak, lhTest, updateData }

/// One planned notification.
@immutable
class PlannedReminder {
  final int id;
  final DateTime when;
  final ReminderKind kind;

  const PlannedReminder(this.id, this.when, this.kind);
}

/// Everything a notification shows. [publicTitle] and [publicBody] are always
/// the neutral text; Android shows them on a lock screen that hides content.
@immutable
class ReminderNotification {
  final int id;
  final DateTime when;
  final String title;
  final String body;
  final String publicTitle;
  final String publicBody;

  const ReminderNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.publicTitle,
    required this.publicBody,
  });

  Map<String, Object> toMap() => {
    'id': id,
    'whenMillis': when.millisecondsSinceEpoch,
    'title': title,
    'body': body,
    'publicTitle': publicTitle,
    'publicBody': publicBody,
  };
}

/// What the reminders need from the platform; replaced in tests.
abstract class ReminderBackend {
  Future<bool> requestPermission();
  Future<void> schedule(ReminderNotification notification);
  Future<void> cancel(int id);
}

/// Android: `CalendarReminders.kt`, which sets VISIBILITY_PRIVATE and the
/// public version; the plugin cannot.
class _AndroidBackend implements ReminderBackend {
  const _AndroidBackend();

  @override
  Future<bool> requestPermission() => NotificationService.requestPermissions();

  @override
  Future<void> schedule(ReminderNotification notification) =>
      FertilityReminderService.channel.invokeMethod<void>(
        'schedule',
        notification.toMap(),
      );

  @override
  Future<void> cancel(int id) =>
      FertilityReminderService.channel.invokeMethod<void>('cancel', {'id': id});
}

/// iOS: the plugin. There is no per-notification hiding, so the style decides
/// the text and the system preview setting decides the lock screen.
class _PluginBackend implements ReminderBackend {
  const _PluginBackend();

  @override
  Future<bool> requestPermission() => NotificationService.requestPermissions();

  @override
  Future<void> schedule(ReminderNotification notification) =>
      NotificationService.scheduleNotification(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: notification.when,
        payload: FertilityReminderService.payload,
        requestPermission: false,
      );

  @override
  Future<void> cancel(int id) => NotificationService.cancelNotification(id);
}

/// Fertile-day notifications pre-scheduled for the next two cycles, so they
/// work without opening the app. Ids and payload never say what they are for,
/// and nothing here is logged.
class FertilityReminderService {
  const FertilityReminderService._();

  /// Neutral text: `MomCare+: Xem lịch hôm nay`, `reminder_text` in the
  /// review packet.
  static const String title = 'MomCare+';
  static const String body = 'Xem lịch hôm nay';
  static const String payload = 'calendar';

  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'com.ntlong25.momcare/reminders',
  );

  static const String _settingsKey = 'reminders';
  static const String _askedKey = 'permission_asked';
  static const String _staleNudgeKey = 'stale_nudge';

  /// How many cycles with a day still ahead are scheduled.
  static const int horizonCycles = 2;

  /// LH test reminders start this many days before the earliest ovulation.
  static const int lhDaysBeforeOvulation = 3;

  /// Most LH test reminders held at once; ids are fixed slots, so they can
  /// be cancelled without knowing the dates.
  static const int maxLhReminders = 8;

  /// A cycle gives at most its first day and three peak days.
  static const int maxFertileReminders = 4 * horizonCycles;

  static int fertileId(int slot) =>
      NotificationService.stableId('calendar:day:$slot');
  static int lhId(int slot) => NotificationService.stableId('calendar:$slot');
  static int get updateDataId =>
      NotificationService.stableId('calendar:update');

  static List<int> get allIds => [
    for (var slot = 0; slot < maxFertileReminders; slot++) fertileId(slot),
    for (var slot = 0; slot < maxLhReminders; slot++) lhId(slot),
    updateDataId,
  ];

  /// Replaced in tests.
  @visibleForTesting
  static ReminderBackend backend =
      defaultTargetPlatform == TargetPlatform.android
      ? const _AndroidBackend()
      : const _PluginBackend();

  static bool get _prefsOpen => Hive.isBoxOpen(AppConstants.fertilityPrefsBox);

  static FertilityReminderSettings load() {
    if (!_prefsOpen) return const FertilityReminderSettings();
    return FertilityReminderSettings.fromJson(
      DatabaseService.fertilityPrefsBox.get(_settingsKey),
    );
  }

  static Future<void> _save(FertilityReminderSettings settings) async {
    if (!_prefsOpen) return;
    await DatabaseService.fertilityPrefsBox.put(
      _settingsKey,
      settings.toJson(),
    );
  }

  /// Pure plan of what is still ahead of [now].
  ///
  /// [current] may include a positive LH test; [calendar] must not, because
  /// later cycles stay calendar based. Late plans nothing: the app is already
  /// asking about the period. Stale plans only [staleNudgeAt].
  static List<PlannedReminder> plan(
    CyclePrediction? current,
    CyclePrediction? calendar,
    FertilityReminderSettings settings,
    DateTime now, {
    DateTime? staleNudgeAt,
  }) {
    if (current == null || calendar == null) return const [];
    if (current.status == CycleStatus.late) return const [];
    if (current.status == CycleStatus.stale) {
      if (!settings.windowEnabled ||
          staleNudgeAt == null ||
          !staleNudgeAt.isAfter(now)) {
        return const [];
      }
      return [
        PlannedReminder(updateDataId, staleNudgeAt, ReminderKind.updateData),
      ];
    }

    DateTime at(DateTime day) =>
        DateTime(day.year, day.month, day.day, settings.hour, settings.minute);

    final planned = <PlannedReminder>[];
    final fertileDays = <DateTime>{};

    if (settings.windowEnabled) {
      List<(DateTime, ReminderKind)> daysOf(CyclePrediction cycle) {
        final days = <(DateTime, ReminderKind)>[];
        for (final day in cycle.fertileDays) {
          final peak = cycle.levelOn(day) == FertilityLevel.peak;
          if (!peak && day != cycle.fertileStart) continue;
          if (!at(day).isAfter(now)) continue;
          days.add((
            day,
            peak ? ReminderKind.fertilePeak : ReminderKind.fertileFirstDay,
          ));
        }
        return days;
      }

      var cyclesUsed = 0;
      var slot = 0;
      CyclePrediction? last;
      for (final cycle in [
        current,
        for (var later = 1; later <= horizonCycles; later++)
          calendar.laterCycle(later),
      ]) {
        if (cyclesUsed == horizonCycles) break;
        final days = daysOf(cycle);
        if (days.isEmpty) continue;
        cyclesUsed++;
        last = cycle;
        for (final (day, kind) in days) {
          if (slot == maxFertileReminders) break;
          planned.add(PlannedReminder(fertileId(slot), at(day), kind));
          fertileDays.add(day);
          slot++;
        }
      }
      if (last != null) {
        // The schedule has run out: ask for fresh data, once.
        planned.add(
          PlannedReminder(
            updateDataId,
            at(CycleStats.addDays(last.latestPeriod, 1)),
            ReminderKind.updateData,
          ),
        );
      }
    }

    // A positive test ends the need to test in this cycle.
    if (settings.lhEnabled && !current.isFromLhTest) {
      var slot = 0;
      for (
        var day = CycleStats.addDays(
          current.earliestOvulation,
          -lhDaysBeforeOvulation,
        );
        !day.isAfter(current.latestOvulation) && slot < maxLhReminders;
        day = CycleStats.addDays(day, 1)
      ) {
        if (!at(day).isAfter(now)) continue;
        // One notification a day, even when both are on.
        if (fertileDays.contains(day)) continue;
        planned.add(PlannedReminder(lhId(slot), at(day), ReminderKind.lhTest));
        slot++;
      }
    }
    return planned;
  }

  /// The text of [reminder]. Only the [FertilityNotificationStyle.full] style
  /// says what the day is; the LH reminder is always neutral.
  static ReminderNotification notificationFor(
    PlannedReminder reminder,
    FertilityNotificationStyle style,
    FertileGuidance guidance,
  ) {
    final id = switch (reminder.kind) {
      ReminderKind.fertileFirstDay => 'notify_window',
      ReminderKind.fertilePeak => 'notify_peak',
      ReminderKind.updateData => 'notify_update',
      ReminderKind.lhTest => null,
    };
    final full = id != null && style == FertilityNotificationStyle.full
        ? guidance.text(id)
        : '';
    return ReminderNotification(
      id: reminder.id,
      when: reminder.when,
      title: title,
      body: full.isEmpty ? body : full,
      publicTitle: title,
      publicBody: body,
    );
  }

  static Future<void> _cancelAll() async {
    for (final id in allIds) {
      try {
        await backend.cancel(id);
      } catch (_) {
        // No platform side (tests) or nothing to cancel.
      }
    }
  }

  static Future<bool> _isPrePregnancy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.appModeKey) == 'prePregnancy';
  }

  /// When the one nudge of stale data fires. Remembered per last period, so
  /// opening the app every day does not repeat it.
  static Future<DateTime> _staleNudgeTime(
    List<MenstrualCycleModel> cycles,
    FertilityReminderSettings settings,
    DateTime now,
  ) async {
    final lastStart = FertilityLogModel.dayKey(
      CycleStats.sortedByStart(cycles).last.startDate,
    );
    // The day is remembered, the time always follows 'Giờ nhắc'.
    final stored = DatabaseService.fertilityPrefsBox.get(_staleNudgeKey);
    if (stored is Map &&
        stored['cycle'] == lastStart &&
        stored['day'] is String) {
      final day = DateTime.tryParse(stored['day'] as String);
      if (day != null) {
        return DateTime(
          day.year,
          day.month,
          day.day,
          settings.hour,
          settings.minute,
        );
      }
    }
    final at = NotificationService.nextInstanceOf(
      settings.hour,
      settings.minute,
      now: now,
    );
    await DatabaseService.fertilityPrefsBox.put(_staleNudgeKey, {
      'cycle': lastStart,
      'day': FertilityLogModel.dayKey(at),
    });
    return at;
  }

  /// Rebuilds everything from the stored data; on app start and after any
  /// change to cycles, logs or settings. Never asks for permission.
  static Future<void> reschedule({DateTime? now}) async {
    await _cancelAll();
    final settings = load();
    if (!settings.anyEnabled || !await _isPrePregnancy()) return;

    final moment = now ?? DateTime.now();
    final List<MenstrualCycleModel> cycles =
        Hive.isBoxOpen(AppConstants.menstrualCycleBox)
        ? DatabaseService.getAllMenstrualCycles()
        : const [];
    final calendar = CyclePrediction.compute(cycles, today: moment);
    final current = CyclePrediction.compute(
      cycles,
      today: moment,
      positiveLhDays: FertilityLogService.positiveLhDays(),
    );
    final staleNudgeAt = current?.status == CycleStatus.stale
        ? await _staleNudgeTime(cycles, settings, moment)
        : null;
    final guidance = ContentPackService.fertileGuidance;
    for (final reminder in plan(
      current,
      calendar,
      settings,
      moment,
      staleNudgeAt: staleNudgeAt,
    )) {
      try {
        await backend.schedule(
          notificationFor(reminder, settings.style, guidance),
        );
      } catch (_) {
        // No platform side: the next rebuild tries again.
      }
    }
  }

  /// Applies [settings] chosen by the user. Returns false, with the reminders
  /// left off, when notification permission is denied.
  static Future<bool> update(
    FertilityReminderSettings settings, {
    DateTime? now,
  }) async {
    var applied = settings;
    var allowed = true;
    if (settings.anyEnabled) {
      allowed = await backend.requestPermission();
      if (!allowed) {
        applied = settings.copyWith(windowEnabled: false, lhEnabled: false);
      }
    }
    await _save(applied);
    await reschedule(now: now);
    return allowed;
  }

  /// On switching to pregnancy: cancels the reminders and turns them off, so
  /// they never return later without the user asking again.
  static Future<void> onLeftPrePregnancy() async {
    // Off means nothing is scheduled: turning off already cancelled it.
    final settings = load();
    if (!settings.anyEnabled) return;
    await _cancelAll();
    await _save(settings.copyWith(windowEnabled: false, lhEnabled: false));
  }

  /// On delete-all. The plugin's cancelAll does not reach the Android alarms.
  static Future<void> onDataDeleted() async {
    await _cancelAll();
  }

  /// Whether the one automatic permission request was made. Kept in the
  /// encrypted box, so delete-all resets it.
  static bool get permissionAsked =>
      _prefsOpen && DatabaseService.fertilityPrefsBox.get(_askedKey) == true;

  static Future<void>? _asking;

  /// The first time pre-pregnancy Hôm nay shows: asks for notification
  /// permission once and, when granted, turns the fertile-day notifications
  /// on with the platform default style. Never asks again by itself; a denial
  /// leaves them off, to be enabled on Chu kỳ.
  static Future<void> askOnce({DateTime? now}) =>
      _asking ??= _askOnce(now).whenComplete(() => _asking = null);

  static Future<void> _askOnce(DateTime? now) async {
    if (!_prefsOpen || permissionAsked) return;
    if (!await _isPrePregnancy()) return;
    // Remembered first, so an interrupted request is not repeated.
    await DatabaseService.fertilityPrefsBox.put(_askedKey, true);
    if (load().anyEnabled) return;
    bool allowed;
    try {
      allowed = await backend.requestPermission();
    } catch (_) {
      allowed = false;
    }
    if (!allowed) return;
    await _save(load().copyWith(windowEnabled: true));
    await reschedule(now: now);
  }

  /// Sends taps on a notification to [onTap], including the tap that launched
  /// the app.
  static Future<void> listenForTaps(VoidCallback onTap) async {
    Future<void> takeTap() async {
      try {
        final tapped = defaultTargetPlatform == TargetPlatform.android
            ? await channel.invokeMethod<bool>('takeTap') ?? false
            : await NotificationService.launchedFromCalendar();
        if (tapped) onTap();
      } catch (_) {
        // No platform side: nothing was tapped.
      }
    }

    NotificationService.onCalendarTap = onTap;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tapped') await takeTap();
    });
    await takeTap();
  }

  static final List<StreamSubscription<BoxEvent>> _watchers = [];
  static Timer? _debounce;

  /// Keeps the schedule current when a period or a test is logged.
  static void startWatching() {
    if (_watchers.isNotEmpty) return;
    void changed(BoxEvent _) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        unawaited(reschedule());
      });
    }

    for (final box in <BoxBase<dynamic>>[
      DatabaseService.menstrualCycleBox,
      DatabaseService.fertilityLogBox,
    ]) {
      _watchers.add(box.watch().listen(changed));
    }
  }

  @visibleForTesting
  static Future<void> stopWatching() async {
    _debounce?.cancel();
    for (final watcher in _watchers) {
      await watcher.cancel();
    }
    _watchers.clear();
  }
}
