import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/providers/disclaimer_consent_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/bump_photo_service.dart';
import '../../../core/services/contraction_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/guide_price_service.dart';
import '../../../core/services/guide_progress_service.dart';
import '../../../core/services/kick_counter_service.dart';
import '../../../core/services/my_clinic_service.dart';
import '../../../core/services/milestone_progress_service.dart';
import '../../../core/services/thai_giao_progress_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/date_picker_utils.dart';
import '../../../core/utils/health_validators.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/hive_boxes_listener.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../bump_journal/quick_camera.dart';
import '../../home/screens/main_navigation.dart';
import '../../legal/screens/disclaimer_consent_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../onboarding/screens/pregnancy_setup_screen.dart';
import '../../../core/theme/app_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with HiveRefreshMixin {
  PregnancyModel? _pregnancy;

  @override
  List<String> get watchedBoxes => const [AppConstants.pregnancyBox];

  @override
  void initState() {
    super.initState();
    _loadPregnancy();
  }

  void _loadPregnancy() {
    _pregnancy = DatabaseService.getActivePregnancy();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Re-read on every rebuild (HiveRefreshMixin rebuilds on data changes).
    _pregnancy = DatabaseService.getActivePregnancy();
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        ThemeNotifier.effectiveBrightness(
          ref.watch(themeProvider),
          platformBrightness,
        ) ==
        Brightness.dark;
    final appMode = ref.watch(appModeProvider);
    final effectiveAppMode = _resolveCurrentMode(appMode);
    final isPregnancyMode = effectiveAppMode == AppMode.pregnancy;
    final myClinic = ref.watch(myClinicProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSection(context, 'Chế độ ứng dụng', [
            ListTile(
              leading: Icon(
                isPregnancyMode ? Icons.pregnant_woman : Icons.eco,
                color: isPregnancyMode
                    ? Theme.of(context).colorScheme.primary
                    : context.semantic.success,
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
              value: isDark,
              onChanged: (value) {
                ref
                    .read(themeProvider.notifier)
                    .toggleTheme(platformBrightness);
              },
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            ),
          ]),
          const Divider(),
          if (isPregnancyMode) ...[
            _buildSection(context, 'Thông tin thai kỳ', [
              if (_pregnancy == null)
                ListTile(
                  key: const ValueKey('settings-pregnancy-setup'),
                  leading: const Icon(Icons.edit_calendar),
                  title: const Text('Thiết lập thai kỳ'),
                  subtitle: const Text('Nhập ngày dự sinh để theo dõi thai kỳ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const PregnancySetupScreen(fromModeSwitch: true),
                    ),
                  ),
                ),
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
          _buildSection(context, 'Nơi khám của tôi', [
            ListTile(
              key: const ValueKey('settings-my-clinic'),
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text('Bệnh viện / phòng khám'),
              subtitle: Text(
                myClinic.name.isNotEmpty ? myClinic.name : 'Chưa cài đặt',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.toMyClinic(context),
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
              subtitle: const Text('Dữ liệu chưa được sao lưu trực tuyến'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLocalDataExplanation(context),
            ),
            if (EncryptionService.isFallbackActive)
              ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: context.semantic.warning,
                ),
                title: const Text('Dữ liệu chưa được mã hóa'),
                subtitle: const Text(
                  'Thiết bị chưa cho phép dùng kho khóa bảo mật nên dữ liệu đang được lưu không mã hóa. Hãy bật khóa màn hình để tăng bảo vệ.',
                ),
              ),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Xóa toàn bộ dữ liệu',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text(
                'Xóa dữ liệu trên thiết bị và đặt lại ứng dụng',
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.error,
              ),
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
            ListTile(
              leading: const Icon(Icons.source),
              title: const Text('Nguồn tham khảo'),
              subtitle: const Text('Nguồn nội dung sức khỏe trong app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => NavigationHelper.toReferences(context),
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
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _changeDueDate(BuildContext context) async {
    // A due date already in the past must not crash the picker.
    final picked = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _pregnancy!.dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 300)),
      includeInitial: true,
    );

    if (picked != null && mounted) {
      // Keep LMP consistent with the due date (single source of truth).
      final updated = _pregnancy!.copyWith(
        dueDate: picked,
        lastPeriodDate: PregnancyModel.lastPeriodFromDueDate(picked),
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
      final weight = HealthValidators.parseDecimal(result);
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
        color: Theme.of(context).colorScheme.primary,
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
        title: const Text('Dữ liệu của bạn được lưu trên thiết bị'),
        content: const Text(
          'MomCare+ lưu dữ liệu thai kỳ, nhật ký sức khỏe, chu kỳ, lịch hẹn, lịch sử đếm cử động thai, cơn co, ảnh bụng bầu và cài đặt trên thiết bị này.\n\n'
          'Hiện tại dữ liệu chưa được sao lưu trực tuyến. Nếu bạn xóa ứng dụng, đổi thiết bị hoặc xóa toàn bộ dữ liệu trong app, dữ liệu có thể không khôi phục được.\n\n'
          'MomCare+ không tự chia sẻ dữ liệu sức khỏe của bạn ra bên ngoài. Ảnh, thẻ cột mốc và file PDF chỉ rời khỏi thiết bị khi bạn tự chọn chia sẻ.',
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
          'Thao tác này sẽ xóa dữ liệu thai kỳ, nhật ký sức khỏe, chu kỳ, lịch hẹn, dữ liệu dinh dưỡng đã lưu, nơi khám đã lưu, giá đồ mua sắm, lịch sử đếm cử động thai và cơn co, ảnh bụng bầu, cài đặt trong app và hủy toàn bộ thông báo đã lên lịch.\n\n'
          'Sau khi xóa, MomCare+ sẽ quay về màn hình bắt đầu như lần cài đặt mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (firstConfirmed != true || !mounted) {
      return;
    }

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAllDataConfirmationDialog(),
    );

    if (secondConfirmed != true || !mounted) {
      return;
    }

    QuickCameraListener.suspended = true;
    try {
      await _deleteAllDataAndRestart(context);
    } finally {
      QuickCameraListener.suspended = false;
    }
  }

  Future<void> _deleteAllDataAndRestart(BuildContext context) async {
    // Read up front: these are reset after this screen has been left.
    final navigationIndex = ref.read(navigationIndexProvider.notifier);
    final theme = ref.read(themeProvider.notifier);
    final appMode = ref.read(appModeProvider.notifier);
    final disclaimerConsent = ref.read(disclaimerConsentProvider.notifier);

    await NotificationService.cancelAllNotifications();
    await DatabaseService.clearAllData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.onboardingKey);
    await prefs.remove(AppConstants.appModeKey);
    await prefs.remove(AppConstants.themeKey);
    await prefs.remove(AppConstants.languageKey);
    await prefs.remove(AppConstants.dueDateKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.maternalHabitsKey);
    await prefs.remove(AppConstants.guideChecklistKey);
    ref.read(guideChecklistProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.thaiGiaoDoneKey);
    await prefs.remove(AppConstants.thaiGiaoReminderKey);
    ref.read(thaiGiaoProgressProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.milestoneDoneKey);
    ref.read(milestoneProgressProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.guidePricesKey);
    ref.read(guidePriceProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.myClinicKey);
    ref.read(myClinicProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.kickSessionsKey);
    ref.read(kickCounterProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.contractionsKey);
    ref.read(contractionProvider.notifier).resetLocal();
    // Removes the bump_photos key and folder; never throws.
    await BumpPhotoService.clearAll();
    ref.read(bumpPhotoProvider.notifier).resetLocal();
    await prefs.remove(AppConstants.bumpCameraLensKey);
    // Generated milestone cards and PDFs in the temp folder; never throws.
    await ShareHelper.clearTempFiles();
    await prefs.remove('locale');
    await prefs.remove(AppConstants.disclaimerAcceptedVersionKey);
    await prefs.remove(AppConstants.disclaimerAcceptedAtKey);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DisclaimerGate(child: OnboardingScreen()),
        ),
        (_) => false,
      );
    }

    // After leaving, so the old tabs never rebuild for a mode or tab that no
    // longer applies. A new install starts on Hôm nay with the default theme.
    navigationIndex.state = 0;
    theme.resetLocal();
    disclaimerConsent.resetLocal();
    await appMode.clearMode();
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
            Text(
              'Chọn giai đoạn hiện tại của bạn:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<AppMode>(
              title: Row(
                children: [
                  Icon(Icons.eco, color: context.semantic.success, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Chuẩn bị mang thai')),
                ],
              ),
              subtitle: const Text(
                'Theo dõi chu kỳ và gợi ý chuẩn bị thụ thai',
              ),
              value: AppMode.prePregnancy,
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<AppMode>(
              title: Row(
                children: [
                  Icon(
                    Icons.pregnant_woman,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Đang mang thai')),
                ],
              ),
              subtitle: const Text(
                'Theo dõi thai kỳ, sức khỏe và dinh dưỡng theo tuần',
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

class _DeleteAllDataConfirmationDialog extends StatefulWidget {
  const _DeleteAllDataConfirmationDialog();

  @override
  State<_DeleteAllDataConfirmationDialog> createState() =>
      _DeleteAllDataConfirmationDialogState();
}

class _DeleteAllDataConfirmationDialogState
    extends State<_DeleteAllDataConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận lần cuối'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dữ liệu sẽ bị xóa khỏi thiết bị này và hiện chưa có bản sao lưu trực tuyến.\n\n'
            'Nhập XOA để xác nhận.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
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
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () {
            final token = _controller.text.trim().toUpperCase();
            Navigator.pop(context, token == 'XOA');
          },
          child: const Text('Xóa dữ liệu'),
        ),
      ],
    );
  }
}
