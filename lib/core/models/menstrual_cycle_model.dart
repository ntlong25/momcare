import 'package:hive/hive.dart';

part 'menstrual_cycle_model.g.dart';

@HiveType(typeId: 2)
class MenstrualCycleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime? endDate;

  @HiveField(3)
  final int? cycleLengthDays; // Length of this cycle

  @HiveField(4)
  final int? periodLengthDays; // Length of period (bleeding days)

  @HiveField(5)
  final String? flowIntensity; // light, medium, heavy

  @HiveField(6)
  final List<String>? symptoms; // List of symptoms

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final bool isFromHealthKit; // Whether data is synced from HealthKit/Google Fit

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  MenstrualCycleModel({
    required this.id,
    required this.startDate,
    this.endDate,
    this.cycleLengthDays,
    this.periodLengthDays,
    this.flowIntensity,
    this.symptoms,
    this.notes,
    this.isFromHealthKit = false,
    required this.createdAt,
    required this.updatedAt,
  });

  MenstrualCycleModel copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLengthDays,
    int? periodLengthDays,
    String? flowIntensity,
    List<String>? symptoms,
    String? notes,
    bool? isFromHealthKit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenstrualCycleModel(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      periodLengthDays: periodLengthDays ?? this.periodLengthDays,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      isFromHealthKit: isFromHealthKit ?? this.isFromHealthKit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate ovulation date (typically 14 days before next period)
  /// This is an estimate based on average cycle
  DateTime? getEstimatedOvulationDate(int averageCycleLength) {
    // Ovulation typically occurs 14 days before the next period
    return startDate.add(Duration(days: averageCycleLength - 14));
  }

  /// Get fertile window (5 days before ovulation + ovulation day + 1 day after)
  List<DateTime>? getFertileWindow(int averageCycleLength) {
    final ovulationDate = getEstimatedOvulationDate(averageCycleLength);
    if (ovulationDate == null) return null;

    final fertileWindow = <DateTime>[];
    // 5 days before ovulation
    for (int i = 5; i >= 0; i--) {
      fertileWindow.add(ovulationDate.subtract(Duration(days: i)));
    }
    // 1 day after ovulation
    fertileWindow.add(ovulationDate.add(const Duration(days: 1)));

    return fertileWindow;
  }

  /// Check if cycle is regular (within 3 days of average)
  bool isRegular(int averageCycleLength) {
    if (cycleLengthDays == null) return false;
    return (cycleLengthDays! - averageCycleLength).abs() <= 3;
  }
}
