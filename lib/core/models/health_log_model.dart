import 'package:hive/hive.dart';

part 'health_log_model.g.dart';

@HiveType(typeId: 1)
class HealthLogModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double? weight;

  @HiveField(3)
  int? systolicBP;

  @HiveField(4)
  int? diastolicBP;

  @HiveField(5)
  String? mood;

  @HiveField(6)
  List<String>? symptoms;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  HealthLogModel({
    required this.id,
    required this.date,
    this.weight,
    this.systolicBP,
    this.diastolicBP,
    this.mood,
    this.symptoms,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  HealthLogModel copyWith({
    String? id,
    DateTime? date,
    double? weight,
    int? systolicBP,
    int? diastolicBP,
    String? mood,
    List<String>? symptoms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthLogModel(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
