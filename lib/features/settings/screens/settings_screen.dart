import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../onboarding/screens/pregnancy_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PregnancyModel? _pregnancy;

  @override
  void initState() {
    super.initState();
    _loadPregnancy();
  }

  void _loadPregnancy() {
    _pregnancy = DatabaseService.getActivePregnancy();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final appMode = ref.watch(appModeProvider);
    final effectiveAppMode = _resolveCurrentMode(appMode);
    final isPregnancyMode = effectiveAppMode == AppMode.pregnancy;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSection(context, 'Chế độ ứng dụng', [
            ListTile(
              leading: Icon(
                isPregnancyMode ? Icons.pregnant_woman : Icons.eco,
                color: isPregnancyMode ? Colors.pink : Colors.green,
              ),
              title: const Text('Chế độ hiện tại'),
              subtitle: Text(
                isPregnancyMode ? 'Đang mang thai' : 'Chuẩn bị mang thai',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showModeDialog(context),
            ),
          ]),
          const Divider(),
          _buildSection(context, 'Giao diện', [
            SwitchListTile(
              title: const Text('Chế độ tối'),
              subtitle: const Text('Bật giao diện tối'),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
          ]),
          const Divider(),
          if (isPregnancyMode) ...[
            _buildSection(context, 'Thông tin thai kỳ', [
              if (_pregnancy != null)
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày dự sinh'),
                  subtitle: Text(DateFormatter.formatDate(_pregnancy!.dueDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _changeDueDate(context),
                ),
              if (_pregnancy != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Tên mẹ'),
                  subtitle: Text(_pregnancy!.motherName ?? 'Chưa cài đặt'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _changeMotherName(context),
                ),
              if (_pregnancy != null)
                ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: const Text('Cân nặng trước khi mang thai'),
                  subtitle: Text(
                    _pregnancy!.prePregnancyWeight != null
                        ? '${_pregnancy!.prePregnancyWeight} kg'
                        : 'Chưa cài đặt',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _changeWeight(context),
                ),
            ]),
            const Divider(),
          ],
          _buildSection(context, 'Tài khoản', [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Hồ sơ'),
              subtitle: const Text('Quản lý hồ sơ của bạn'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.showProfileDialog(context),
            ),
          ]),
          const Divider(),
          _buildSection(context, 'Thông báo', [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Cài đặt thông báo'),
              subtitle: const Text('Quản lý thông báo của bạn'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  NavigationHelper.showNotificationSettingsDialog(context),
            ),
          ]),
          const Divider(),
          _buildSection(context, 'Quyền riêng tư & dữ liệu', [
            ListTile(
              leading: const Icon(Icons.phonelink_lock),
              title: const Text('Dữ liệu lưu trên thiết bị này'),
              subtitle: const Text(
                'Bản V1 chưa bật đồng bộ cloud hoặc sao lưu Supabase',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLocalDataExplanation(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Xóa toàn bộ dữ liệu',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Xóa dữ liệu local và đặt lại ứng dụng'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () => _showDeleteAllDataFlow(context),
            ),
          ]),
          const Divider(),
          _buildSection(context, 'Thông tin', [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Hướng dẫn sử dụng'),
              subtitle: const Text('Tìm hiểu cách sử dụng MomCare+'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.toGuide(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Về MomCare+'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAboutDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Chính sách bảo mật'),
              subtitle: const Text('Cách MomCare+ lưu và bảo vệ dữ liệu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.toPrivacyPolicy(context),
            ),
            ListTile(
              leading: const Icon(Icons.medical_information),
              title: const Text('Tuyên bố miễn trừ y tế'),
              subtitle: const Text('MomCare+ không thay thế tư vấn y tế'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.toMedicalDisclaimer(context),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: const Text('Dấu hiệu cần đi khám ngay'),
              subtitle: const Text('Các dấu hiệu bất thường cần chú ý'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.toEmergencyWarning(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _changeDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pregnancy!.dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final updated = _pregnancy!.copyWith(
        dueDate: picked,
        updatedAt: DateTime.now(),
      );
      await DatabaseService.savePregnancy(updated);
      _loadPregnancy();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ngày dự sinh')),
        );
      }
    }
  }

  Future<void> _changeMotherName(BuildContext context) async {
    final controller = TextEditingController(
      text: _pregnancy!.motherName ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên mẹ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên',
            hintText: 'Nhập tên của bạn',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final updated = _pregnancy!.copyWith(
        motherName: result.isEmpty ? null : result,
        updatedAt: DateTime.now(),
      );
      await DatabaseService.savePregnancy(updated);
      _loadPregnancy();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật tên')));
      }
    }

    controller.dispose();
  }

  Future<void> _changeWeight(BuildContext context) async {
    final controller = TextEditingController(
      text: _pregnancy!.prePregnancyWeight?.toString() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi cân nặng trước khi mang thai'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Cân nặng (kg)',
            hintText: 'Nhập cân nặng (kg)',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final weight = double.tryParse(result);
      if (weight != null) {
        final updated = _pregnancy!.copyWith(
          prePregnancyWeight: weight,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.savePregnancy(updated);
        _loadPregnancy();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã cập nhật cân nặng')));
        }
      }
    }

    controller.dispose();
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MomCare+',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.favorite,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: [
        const Text(
          'MomCare+ là ứng dụng đồng hành trong thai kỳ và giai đoạn chuẩn bị mang thai. '
          'Ứng dụng giúp theo dõi hành trình, ghi nhận sức khỏe, xem gợi ý dinh dưỡng '
          'và quản lý lịch hẹn.',
        ),
      ],
    );
  }

  void _showLocalDataExplanation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dữ liệu của bạn được lưu cục bộ'),
        content: const Text(
          'Trong phiên bản V1, MomCare+ lưu dữ liệu thai kỳ, nhật ký sức khỏe, chu kỳ, lịch hẹn và cài đặt trên thiết bị này.\n\n'
          'MomCare+ chưa bật đăng nhập, đồng bộ cloud hoặc sao lưu Supabase. Nếu bạn xóa ứng dụng, đổi thiết bị, hoặc xóa toàn bộ dữ liệu trong app, dữ liệu local có thể không khôi phục được.\n\n'
          'Ứng dụng không gửi dữ liệu sức khỏe của bạn lên máy chủ trong bản V1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAllDataFlow(BuildContext context) async {
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?'),
        content: const Text(
          'Thao tác này sẽ xóa dữ liệu thai kỳ, nhật ký sức khỏe, chu kỳ, lịch hẹn, dữ liệu dinh dưỡng đã lưu, cài đặt trong app và hủy toàn bộ thông báo đã lên lịch.\n\n'
          'Sau khi xóa, MomCare+ sẽ quay về màn hình bắt đầu như lần cài đặt mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (firstConfirmed != true || !mounted) {
      return;
    }

    final deleteTokenController = TextEditingController();
    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lần cuối'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dữ liệu local sẽ bị xóa khỏi thiết bị này và không có bản sao lưu cloud trong V1.\n\n'
              'Nhập XOA để xác nhận.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deleteTokenController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Nhập XOA',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final token = deleteTokenController.text.trim().toUpperCase();
              Navigator.pop(context, token == 'XOA');
            },
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );
    deleteTokenController.dispose();

    if (secondConfirmed != true || !mounted) {
      return;
    }

    await _deleteAllDataAndRestart(context);
  }

  Future<void> _deleteAllDataAndRestart(BuildContext context) async {
    await NotificationService.cancelAllNotifications();
    await DatabaseService.clearAllData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.onboardingKey);
    await prefs.remove(AppConstants.appModeKey);
    await prefs.remove(AppConstants.themeKey);
    await prefs.remove(AppConstants.languageKey);
    await prefs.remove(AppConstants.dueDateKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove('locale');

    await ref.read(appModeProvider.notifier).clearMode();
    await ref.read(themeProvider.notifier).setTheme(ThemeMode.light);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  Future<void> _showModeDialog(BuildContext context) async {
    final currentMode = _resolveCurrentMode(ref.read(appModeProvider));

    final result = await showDialog<AppMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi chế độ ứng dụng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn giai đoạn hiện tại của bạn:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            RadioListTile<AppMode>(
              title: const Row(
                children: [
                  Icon(Icons.eco, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Chuẩn bị mang thai')),
                ],
              ),
              subtitle: const Text(
                'Theo dõi chu kỳ và gợi ý chuẩn bị thụ thai',
                style: TextStyle(fontSize: 12),
              ),
              value: AppMode.prePregnancy,
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<AppMode>(
              title: const Row(
                children: [
                  Icon(Icons.pregnant_woman, color: Colors.pink, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Đang mang thai')),
                ],
              ),
              subtitle: const Text(
                'Theo dõi thai kỳ, sức khỏe và dinh dưỡng theo tuần',
                style: TextStyle(fontSize: 12),
              ),
              value: AppMode.pregnancy,
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (result == null || result == currentMode || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đổi chế độ'),
        content: Text(
          result == AppMode.pregnancy
              ? 'Chuyển sang chế độ Đang mang thai?\n\nBạn sẽ cần thiết lập thông tin thai kỳ nếu chưa có dữ liệu.'
              : 'Chuyển sang chế độ Chuẩn bị mang thai?\n\nDữ liệu thai kỳ sẽ được giữ lại để dùng sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(appModeProvider.notifier).setMode(result);

      if (!mounted) {
        return;
      }

      final activePregnancy =
          _pregnancy ?? DatabaseService.getActivePregnancy();

      if (result == AppMode.pregnancy && activePregnancy == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == AppMode.pregnancy
                ? 'Đã chuyển sang chế độ Đang mang thai'
                : 'Đã chuyển sang chế độ Chuẩn bị mang thai',
          ),
        ),
      );
    }
  }

  AppMode _resolveCurrentMode(AppMode? appMode) {
    if (appMode != null) {
      return appMode;
    }

    return _pregnancy != null ? AppMode.pregnancy : AppMode.prePregnancy;
  }
}
