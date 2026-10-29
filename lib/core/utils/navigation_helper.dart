import 'package:flutter/material.dart';
import '../../features/onboarding/screens/pregnancy_setup_screen.dart';
import '../../features/health_diary/screens/health_diary_screen.dart';
import '../../features/health_diary/screens/add_health_log_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/settings/screens/my_clinic_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/guide/screens/guide_screen.dart';
import '../../features/fertility/screens/fertility_planner_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/medical_disclaimer_screen.dart';
import '../../features/emergency/screens/emergency_warning_screen.dart';
import '../../features/references/screens/references_screen.dart';
import '../../features/tracking/screens/week_detail_screen.dart';
import '../../features/tools/screens/contraction_timer_screen.dart';
import '../../features/tools/screens/kick_counter_screen.dart';
import '../../features/bump_journal/screens/bump_journal_screen.dart';
import '../../features/health_diary/screens/health_report_export_screen.dart';

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

  static Future<T?> toEmergencyWarning<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyWarningScreen()),
    );
  }

  static Future<T?> toWeekDetail<T>(BuildContext context, int week) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => WeekDetailScreen(initialWeek: week)),
    );
  }

  static Future<T?> toMyClinic<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const MyClinicScreen()),
    );
  }

  static Future<T?> toKickCounter<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const KickCounterScreen()),
    );
  }

  static Future<T?> toContractionTimer<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const ContractionTimerScreen()),
    );
  }

  static Future<T?> toBumpJournal<T>(BuildContext context, {int? week}) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => BumpJournalScreen(initialWeek: week)),
    );
  }

  /// [includePregnancy] false (pre-pregnancy mode) hides the "Từ đầu thai kỳ"
  /// range.
  static Future<T?> toHealthReportExport<T>(
    BuildContext context, {
    bool includePregnancy = true,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HealthReportExportScreen(includePregnancy: includePregnancy),
      ),
    );
  }

  static Future<T?> toReferences<T>(BuildContext context) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => const ReferencesScreen()),
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
          'MomCare+ có thể nhắc bạn:\n'
          '- Lịch hẹn: bật "Nhắc hẹn" khi thêm hoặc sửa lịch hẹn.\n'
          '- Thói quen hằng ngày: bật chuông ở thẻ "Chăm sóc hôm nay" trên Trang chủ.\n\n'
          'Nhắc nhở chỉ được bật khi bạn chọn, và lặp lại mỗi ngày với thói quen.',
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
          'Bạn quản lý nhắc nhở ngay tại nơi tạo chúng:\n'
          '- Lịch hẹn: bật/tắt "Nhắc hẹn" và chọn thời gian nhắc trước trong màn sửa lịch hẹn.\n'
          '- Thói quen: bật/tắt chuông và chọn giờ nhắc ở thẻ "Chăm sóc hôm nay".\n\n'
          'Bạn cũng có thể tắt toàn bộ thông báo của MomCare+ trong cài đặt của điện thoại.',
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
