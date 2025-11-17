import 'package:flutter/material.dart';
import '../../features/onboarding/screens/pregnancy_setup_screen.dart';
import '../../features/health_diary/screens/health_diary_screen.dart';
import '../../features/health_diary/screens/add_health_log_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Navigation helper for consistent navigation throughout the app
class NavigationHelper {
  /// Navigate to pregnancy setup screen
  static Future<T?> toPregnancySetup<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
    );
  }

  /// Navigate to health diary screen
  static Future<T?> toHealthDiary<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const HealthDiaryScreen()),
    );
  }

  /// Navigate to add health log screen
  static Future<T?> toAddHealthLog<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const AddHealthLogScreen()),
    );
  }

  /// Navigate to appointments screen
  static Future<T?> toAppointments<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
    );
  }

  /// Navigate to add appointment screen
  static Future<T?> toAddAppointment<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
    );
  }

  /// Navigate to nutrition screen (with optional tab index)
  static Future<T?> toNutrition<T>(BuildContext context, {int initialTab = 0}) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionScreen(initialTab: initialTab),
      ),
    );
  }

  /// Navigate to recipes screen
  static Future<T?> toRecipes<T>(BuildContext context) {
    return toNutrition(context, initialTab: 1);
  }

  /// Navigate to settings screen
  static Future<T?> toSettings<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  /// Show notification placeholder dialog
  static void showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text(
          'Notification center will be available in a future update.\n\n'
          'You will receive reminders for:\n'
          '• Upcoming appointments\n'
          '• Daily health tips\n'
          '• Medication reminders',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show privacy policy dialog
  static void showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'MomCare+ Privacy Policy\n\n'
            '1. Data Storage\n'
            'All your health data is stored locally on your device using encrypted storage. '
            'We do not collect or transmit your personal health information to any servers.\n\n'
            '2. Data Security\n'
            'Your pregnancy and health data is encrypted using AES-256 encryption. '
            'Encryption keys are stored securely in your device\'s platform keychain.\n\n'
            '3. Permissions\n'
            'We only request permissions necessary for app functionality:\n'
            '• Storage: To save your health data locally\n'
            '• Notifications: To send you appointment reminders\n'
            '• Camera: Optional, for profile pictures\n\n'
            '4. Data Retention\n'
            'Your data remains on your device until you choose to delete it. '
            'You can clear all data from the Settings screen.\n\n'
            '5. Third-Party Services\n'
            'This app does not use any third-party analytics or tracking services.\n\n'
            'Last updated: November 2025',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show profile placeholder dialog
  static void showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: const Text(
          'Full profile management will be available in a future update.\n\n'
          'For now, you can update your pregnancy information from the Settings screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show notification settings placeholder dialog
  static void showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Text(
          'Detailed notification settings will be available in a future update.\n\n'
          'Currently, notifications are enabled by default for:\n'
          '• Appointment reminders (1 hour before)\n'
          '• Daily health tips (9:00 AM)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
