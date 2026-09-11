import 'package:flutter/material.dart';
import '../../features/onboarding/screens/pregnancy_setup_screen.dart';
import '../../features/health_diary/screens/health_diary_screen.dart';
import '../../features/health_diary/screens/add_health_log_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/guide/screens/guide_screen.dart';
import '../../features/fertility/screens/fertility_planner_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/medical_disclaimer_screen.dart';

class NavigationHelper {
  static Future<T?> toPregnancySetup<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
    );
  }

  static Future<T?> toHealthDiary<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const HealthDiaryScreen()),
    );
  }

  static Future<T?> toAddHealthLog<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const AddHealthLogScreen()),
    );
  }

  static Future<T?> toAppointments<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
    );
  }

  static Future<T?> toAddAppointment<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
    );
  }

  static Future<T?> toNutrition<T>(BuildContext context, {int initialTab = 0}) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionScreen(initialTab: initialTab),
      ),
    );
  }

  static Future<T?> toRecipes<T>(BuildContext context) {
    return toNutrition(context, initialTab: 1);
  }

  static Future<T?> toSettings<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  static Future<T?> toGuide<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const GuideScreen()),
    );
  }

  static Future<T?> toFertilityPlanner<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const FertilityPlannerScreen()),
    );
  }

  static Future<T?> toPrivacyPolicy<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  static Future<T?> toMedicalDisclaimer<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const MedicalDisclaimerScreen()),
    );
  }

  static Future<T?> showPrivacyPolicy<T>(BuildContext context) {
    return toPrivacyPolicy<T>(context);
  }

  static void showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo'),
        content: const Text(
          'Trung tâm thông báo sẽ được hoàn thiện trong bản cập nhật sau.\n\n'
          'Hiện tại ứng dụng có thể nhắc:\n'
          '- Lịch hẹn sắp tới\n'
          '- Gợi ý sức khỏe hằng ngày\n'
          '- Nhắc uống thuốc hoặc vitamin nếu được cấu hình',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  static void showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hồ sơ'),
        content: const Text(
          'Quản lý hồ sơ đầy đủ sẽ được bổ sung trong bản cập nhật sau.\n\n'
          'Hiện tại bạn có thể cập nhật thông tin thai kỳ trong màn Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  static void showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt thông báo'),
        content: const Text(
          'Cài đặt thông báo chi tiết sẽ được bổ sung trong bản cập nhật sau.\n\n'
          'Hiện tại ứng dụng hỗ trợ:\n'
          '- Nhắc lịch hẹn trước 1 giờ\n'
          '- Gợi ý sức khỏe hằng ngày lúc 9:00',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
