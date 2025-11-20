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
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // App Mode Section
          _buildSection(
            context,
            'App Mode',
            [
              ListTile(
                leading: Icon(
                  isPregnancyMode ? Icons.pregnant_woman : Icons.eco,
                  color: isPregnancyMode ? Colors.pink : Colors.green,
                ),
                title: const Text('Current Mode'),
                subtitle: Text(
                  isPregnancyMode
                      ? 'Pregnancy Mode'
                      : 'Pre-Pregnancy Planning Mode',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showModeDialog(context),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            'Appearance',
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable dark theme'),
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
                title: const Text('Language'),
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
              'Pregnancy Info',
              [
                if (_pregnancy != null)
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormatter.formatDate(_pregnancy!.dueDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _changeDueDate(context),
                  ),
                if (_pregnancy != null)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Mother Name'),
                    subtitle: Text(_pregnancy!.motherName ?? 'Not set'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _changeMotherName(context),
                  ),
                if (_pregnancy != null)
                  ListTile(
                    leading: const Icon(Icons.monitor_weight),
                    title: const Text('Pre-Pregnancy Weight'),
                    subtitle: Text(_pregnancy!.prePregnancyWeight != null
                        ? '${_pregnancy!.prePregnancyWeight} kg'
                        : 'Not set'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _changeWeight(context),
                  ),
              ],
            ),
            const Divider(),
          ],
          _buildSection(
            context,
            'Account',
            [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                subtitle: const Text('Manage your profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationHelper.showProfileDialog(context),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            'Notifications',
            [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notification Settings'),
                subtitle: const Text('Manage your notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationHelper.showNotificationSettingsDialog(context),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            context,
            'About',
            [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('App Guide'),
                subtitle: const Text('Learn how to use MomCare+'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NavigationHelper.toGuide(context),
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About MomCare+'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
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
          const SnackBar(content: Text('Due date updated successfully')),
        );
      }
    }
  }

  Future<void> _changeMotherName(BuildContext context) async {
    final controller = TextEditingController(text: _pregnancy!.motherName ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Mother Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
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
          const SnackBar(content: Text('Name updated successfully')),
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
        title: const Text('Change Pre-Pregnancy Weight'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'Enter weight in kg',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
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
            const SnackBar(content: Text('Weight updated successfully')),
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
          'MomCare+ is your companion app for pregnancy and postpartum health. '
          'Track your journey, get nutrition advice, and stay organized with appointments.',
        ),
      ],
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final currentLocale = ref.read(localeProvider);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
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
            child: const Text('Cancel'),
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
              ? 'Language changed to English'
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
        title: const Text('Change App Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select your current stage:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            RadioListTile<AppMode>(
              title: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Pre-Pregnancy Planning'),
                  ),
                ],
              ),
              subtitle: const Text(
                'Track cycles, nutrition tips for conception',
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
                    child: Text('Pregnancy'),
                  ),
                ],
              ),
              subtitle: const Text(
                'Track pregnancy, health, weekly nutrition',
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && result != currentMode && mounted) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Mode Change'),
          content: Text(
            result == AppMode.pregnancy
                ? 'Switch to Pregnancy Mode?\n\nYou will need to set up your pregnancy information.'
                : 'Switch to Pre-Pregnancy Planning Mode?\n\nYour pregnancy data will be kept for future use.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
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
                      ? 'Switched to Pregnancy Mode'
                      : 'Switched to Pre-Pregnancy Planning Mode',
                ),
              ),
            );
          }
        }
      }
    }
  }
}
