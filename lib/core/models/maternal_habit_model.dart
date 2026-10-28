class MaternalHabitModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final bool enabled;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final String frequency;
  final DateTime? lastCompletedDate;
  final String disclaimer;

  const MaternalHabitModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.enabled = true,
    this.reminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.frequency = 'daily',
    this.lastCompletedDate,
    required this.disclaimer,
  });

  bool get isCompletedToday {
    final completed = lastCompletedDate;
    if (completed == null) return false;
    final now = DateTime.now();
    return completed.year == now.year &&
        completed.month == now.month &&
        completed.day == now.day;
  }

  MaternalHabitModel copyWith({
    bool? enabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? frequency,
    DateTime? lastCompletedDate,
  }) {
    return MaternalHabitModel(
      id: id,
      title: title,
      category: category,
      description: description,
      enabled: enabled ?? this.enabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      frequency: frequency ?? this.frequency,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      disclaimer: disclaimer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enabled': enabled,
      'reminderEnabled': reminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'frequency': frequency,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  MaternalHabitModel applySavedState(Map<String, dynamic>? savedState) {
    if (savedState == null) return this;
    return copyWith(
      enabled: savedState['enabled'] as bool? ?? enabled,
      reminderEnabled:
          savedState['reminderEnabled'] as bool? ?? reminderEnabled,
      reminderHour: savedState['reminderHour'] as int? ?? reminderHour,
      reminderMinute: savedState['reminderMinute'] as int? ?? reminderMinute,
      frequency: savedState['frequency'] as String? ?? frequency,
      lastCompletedDate: savedState['lastCompletedDate'] is String
          ? DateTime.tryParse(savedState['lastCompletedDate'] as String)
          : lastCompletedDate,
    );
  }
}
