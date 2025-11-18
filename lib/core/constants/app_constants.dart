class AppConstants {
  // App Info
  static const String appName = 'MomCare+';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String pregnancyBox = 'pregnancy_box';
  static const String healthLogBox = 'health_log_box';
  static const String appointmentBox = 'appointment_box';
  static const String nutritionBox = 'nutrition_box';
  static const String recipeBox = 'recipe_box';
  static const String settingsBox = 'settings_box';
  static const String menstrualCycleBox = 'menstrual_cycle_box';

  // Shared Preferences Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  static const String dueDateKey = 'due_date';
  static const String userNameKey = 'user_name';

  // Pregnancy Weeks
  static const int pregnancyTotalWeeks = 42;
  static const int trimesterWeeks = 14;

  // BMI Categories
  static const double bmiUnderweight = 18.5;
  static const double bmiNormal = 24.9;
  static const double bmiOverweight = 29.9;

  // Notification IDs
  static const int appointmentNotificationId = 1;
  static const int medicationNotificationId = 2;
  static const int dailyTipNotificationId = 3;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Nutrition Categories
  static const List<String> nutritionCategories = [
    'Trimester 1',
    'Trimester 2',
    'Trimester 3',
    'Postpartum',
    'Baby Food',
  ];

  // Health Log Categories
  static const List<String> healthLogCategories = [
    'Weight',
    'Blood Pressure',
    'Mood',
    'Symptoms',
    'Notes',
  ];
}
