import 'package:hive/hive.dart';

part 'pregnancy_model.g.dart';

@HiveType(typeId: 0)
class PregnancyModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime dueDate;

  @HiveField(2)
  String? motherName;

  @HiveField(3)
  double? prePregnancyWeight;

  @HiveField(4)
  double? height;

  @HiveField(5)
  DateTime? lastPeriodDate;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  PregnancyModel({
    required this.id,
    required this.dueDate,
    this.motherName,
    this.prePregnancyWeight,
    this.height,
    this.lastPeriodDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Standard pregnancy length used to link LMP and due date (Naegele).
  static const int gestationDays = 280;

  /// Whole calendar days from [from] to [to], ignoring time of day and DST.
  static int calendarDaysBetween(DateTime from, DateTime to) {
    return DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }

  /// Due date estimated from the first day of the last menstrual period.
  static DateTime dueDateFromLastPeriod(DateTime lastPeriodDate) => DateTime(
    lastPeriodDate.year,
    lastPeriodDate.month,
    lastPeriodDate.day + gestationDays,
  );

  /// First day of the last menstrual period implied by a due date.
  static DateTime lastPeriodFromDueDate(DateTime dueDate) =>
      DateTime(dueDate.year, dueDate.month, dueDate.day - gestationDays);

  /// Start of pregnancy (week 0). The due date is the single source of truth
  /// so the current week and the days-left counter always agree.
  DateTime get pregnancyStartDate => lastPeriodFromDueDate(dueDate);

  int currentWeekAt(DateTime now) {
    final difference = calendarDaysBetween(pregnancyStartDate, now);
    final weeks = (difference / 7).floor();
    return weeks.clamp(0, 42);
  }

  int daysUntilDueAt(DateTime now) => calendarDaysBetween(now, dueDate);

  int get currentWeek => currentWeekAt(DateTime.now());

  int get daysUntilDue => daysUntilDueAt(DateTime.now());

  String get trimester {
    final week = currentWeek;
    if (week <= 13) return 'Tam cá nguyệt 1';
    if (week <= 27) return 'Tam cá nguyệt 2';
    return 'Tam cá nguyệt 3';
  }

  double? get bmi {
    if (prePregnancyWeight == null || height == null) return null;
    final heightInMeters = height! / 100;
    return prePregnancyWeight! / (heightInMeters * heightInMeters);
  }

  PregnancyModel copyWith({
    String? id,
    DateTime? dueDate,
    String? motherName,
    double? prePregnancyWeight,
    double? height,
    DateTime? lastPeriodDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PregnancyModel(
      id: id ?? this.id,
      dueDate: dueDate ?? this.dueDate,
      motherName: motherName ?? this.motherName,
      prePregnancyWeight: prePregnancyWeight ?? this.prePregnancyWeight,
      height: height ?? this.height,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
