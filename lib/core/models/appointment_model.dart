import 'package:hive/hive.dart';

part 'appointment_model.g.dart';

@HiveType(typeId: 2)
class AppointmentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  String? location;

  @HiveField(4)
  String? doctorName;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  bool reminderEnabled;

  @HiveField(8)
  int reminderMinutesBefore;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.title,
    required this.dateTime,
    this.location,
    this.doctorName,
    this.notes,
    this.isCompleted = false,
    this.reminderEnabled = true,
    this.reminderMinutesBefore = 60,
    required this.createdAt,
    required this.updatedAt,
  });

  AppointmentModel copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? location,
    String? doctorName,
    String? notes,
    bool? isCompleted,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
