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

  int get currentWeek {
    final now = DateTime.now();
    final difference = now.difference(lastPeriodDate ?? dueDate.subtract(const Duration(days: 280)));
    final weeks = (difference.inDays / 7).floor();
    return weeks.clamp(0, 42);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }

  String get trimester {
    final week = currentWeek;
    if (week <= 13) return 'Trimester 1';
    if (week <= 27) return 'Trimester 2';
    return 'Trimester 3';
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
