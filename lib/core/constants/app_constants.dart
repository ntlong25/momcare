class AppConstants {
  // App Info
  static const String appName = 'MomCare+';
  static const String appVersion = '1.0.0';

  // Legal pages. Still placeholders: while a URL is empty or on example.com
  // the "Mở ... trên website" button stays hidden (see [isPublishedUrl]).
  // Setting the real URL here brings the button back.
  static const String privacyPolicyUrl =
      'https://example.com/momcare/privacy-policy';
  static const String medicalDisclaimerUrl =
      'https://example.com/momcare/medical-disclaimer';

  /// False for an empty URL or one on the reserved example.com domain.
  static bool isPublishedUrl(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
    return host.isNotEmpty &&
        host != 'example.com' &&
        !host.endsWith('.example.com');
  }

  /// Raise when the disclaimer text changes: everyone is asked to accept the
  /// new version on the next launch.
  static const int disclaimerVersion = 1;

  // Hive Box Names
  static const String pregnancyBox = 'pregnancy_box';
  static const String healthLogBox = 'health_log_box';
  static const String appointmentBox = 'appointment_box';
  static const String nutritionBox = 'nutrition_box';
  static const String recipeBox = 'recipe_box';
  static const String settingsBox = 'settings_box';
  static const String menstrualCycleBox = 'menstrual_cycle_box';
  static const String fertilityLogBox = 'fertility_log_box';
  static const String fertilityPrefsBox = 'fertility_prefs_box';

  // Shared Preferences Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  static const String appModeKey = 'app_mode';
  static const String dueDateKey = 'due_date';
  static const String userNameKey = 'user_name';
  static const String maternalHabitsKey = 'maternal_habits';
  static const String guideChecklistKey = 'guide_checklist_ticks';
  static const String thaiGiaoDoneKey = 'thai_giao_done_dates';
  static const String milestoneDoneKey = 'milestone_done_dates';
  static const String thaiGiaoReminderKey = 'thai_giao_reminder';
  static const String guidePricesKey = 'guide_item_prices';
  static const String myClinicKey = 'my_clinic_profile';
  static const String kickSessionsKey = 'kick_sessions';
  static const String contractionsKey = 'contraction_log';
  static const String bumpPhotosKey = 'bump_photos';
  static const String bumpCameraLensKey = 'bump_camera_lens';
  static const String disclaimerAcceptedVersionKey =
      'disclaimer_accepted_version';
  static const String disclaimerAcceptedAtKey = 'disclaimer_accepted_at';

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
    'Tam cá nguyệt 1',
    'Tam cá nguyệt 2',
    'Tam cá nguyệt 3',
    'Sau sinh',
  ];

  // Health Log Categories
  static const List<String> healthLogCategories = [
    'Cân nặng',
    'Huyết áp',
    'Tâm trạng',
    'Triệu chứng',
    'Ghi chú',
  ];
}
