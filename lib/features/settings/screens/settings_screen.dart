import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/navigation_helper.dart';
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
    // Get active pregnancy (returns null if not found, no exception thrown)
    _pregnancy = DatabaseService.getActivePregnancy();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final appMode = ref.watch(appModeProvider);
    final isPregnancyMode = appMode == AppMode.pregnancy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // App Mode Section
          _buildSection(
            context,
            'Chế độ ứng dụng',
            [
              ListTile(
                leading: Icon(
                  isPregnancyMode ? Icons.pregnant_woman : Icons.eco,
                  color: isPregnancyMode ? Colors.pink : Colors.green,
                ),
                title: const Text('Chế độ hiện tại'),
                subtitle: Text(
                  isPregnancyMode
                      ? 'Chế độ mang thai'
                      : 'Chế độ chuẩn bị mang thai',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showModeDialog(context),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            'Giao diện',
            [
              SwitchListTile(
                title: const Text('Chế độ tối'),
                subtitle: const Text('Bật giao diện tối'),
                value: themeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                secondary: Icon(
                  themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Ngôn ngữ'),
                subtitle: Text(locale.languageCode == 'en' ? 'English' : 'Tiếng Việt'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context),
              ),
            ],
          ),
          const Divider(),
          // Show Pregnancy Info only in pregnancy mode
          if (isPregnancyMode) ...[
            _buildSection(
              context,
              'Thông tin thai kỳ',
              [
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
                    subtitle: Text(_pregnancy!.prePregnancyWeight != null
                        ? '${_pregnancy!.prePregnancyWeight} kg'
                        : 'Chưa cài đặt'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _changeWeight(context),
                  ),
              ],
            ),
            const Divider(),
          ],
          _buildSection(
            context,
            'Tài khoản',
            [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Hồ sơ'),
                subtitle: const Text('Quản lý hồ sơ của bạn'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationHelper.showProfileDialog(context),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            'Thông báo',
            [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Cài đặt thông báo'),
                subtitle: const Text('Quản lý thông báo của bạn'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationHelper.showNotificationSettingsDialog(context),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            'Thông tin',
            [
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
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Chính sách bảo mật'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationHelper.showPrivacyPolicy(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
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
    final controller = TextEditingController(text: _pregnancy!.motherName ?? '');

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tên')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật cân nặng')),
          );
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
          'MomCare+ là ứng dụng đồng hành cùng bạn trong thai kỳ và sau sinh. '
          'Theo dõi hành trình, nhận tư vấn dinh dưỡng và quản lý lịch hẹn.',
        ),
      ],
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final currentLocale = ref.read(localeProvider);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: currentLocale.languageCode,
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

    if (result != null && result != currentLocale.languageCode) {
      await ref.read(localeProvider.notifier).setLocale(Locale(result));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == 'en'
              ? 'Đã chuyển sang tiếng Anh'
              : 'Đã chuyển sang Tiếng Việt'),
          ),
        );
      }
    }
  }

  Future<void> _showModeDialog(BuildContext context) async {
    final currentMode = ref.read(appModeProvider);

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
              title: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Chuẩn bị mang thai'),
                  ),
                ],
              ),
              subtitle: const Text(
                'Theo dõi chu kỳ, tips dinh dưỡng thụ thai',
                style: TextStyle(fontSize: 12),
              ),
              value: AppMode.prePregnancy,
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<AppMode>(
              title: Row(
                children: [
                  Icon(Icons.pregnant_woman, color: Colors.pink, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Đang mang thai'),
                  ),
                ],
              ),
              subtitle: const Text(
                'Theo dõi thai kỳ, sức khỏe, dinh dưỡng theo tuần',
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

    if (result != null && result != currentMode && mounted) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đổi chế độ'),
          content: Text(
            result == AppMode.pregnancy
                ? 'Chuyển sang chế độ mang thai?\n\nBạn sẽ cần thiết lập thông tin thai kỳ.'
                : 'Chuyển sang chế độ chuẩn bị mang thai?\n\nDữ liệu thai kỳ sẽ được giữ lại để sử dụng sau.',
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

        if (mounted) {
          // If switching to pregnancy mode and no pregnancy data, go to setup
          if (result == AppMode.pregnancy && _pregnancy == null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PregnancySetupScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result == AppMode.pregnancy
                      ? 'Đã chuyển sang chế độ mang thai'
                      : 'Đã chuyển sang chế độ chuẩn bị mang thai',
                ),
              ),
            );
          }
        }
      }
    }
  }
}
