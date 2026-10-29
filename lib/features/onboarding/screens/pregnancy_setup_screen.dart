import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/date_picker_utils.dart';
import '../../../core/utils/health_validators.dart';
import '../../home/screens/main_navigation.dart';

class PregnancySetupScreen extends ConsumerStatefulWidget {
  /// Opened from the pre-pregnancy "Tôi đã có thai" flow: the app stays in
  /// pre-pregnancy mode unless the pregnancy is saved, so skipping just pops
  /// back, and saving replaces the whole stack with a single MainNavigation.
  final bool fromModeSwitch;

  const PregnancySetupScreen({super.key, this.fromModeSwitch = false});

  @override
  ConsumerState<PregnancySetupScreen> createState() =>
      _PregnancySetupScreenState();
}

class _PregnancySetupScreenState extends ConsumerState<PregnancySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  DateTime? _dueDate;
  DateTime? _lastPeriodDate;

  bool get _hasData {
    return _nameController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _heightController.text.isNotEmpty ||
        _dueDate != null ||
        _lastPeriodDate != null;
  }

  Future<bool> _onWillPop() async {
    if (!_hasData) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text(
          'Bạn có thông tin thai kỳ chưa lưu. Bạn có chắc muốn quay lại và bỏ dữ liệu này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Thiết lập thai kỳ')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt đầu nhé!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cho MomCare+ biết một vài thông tin về bạn và thai kỳ',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên của bạn (không bắt buộc)',
                    hintText: 'Nhập tên của bạn',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cân nặng trước khi mang thai (kg)',
                    hintText: 'Nhập cân nặng của bạn',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    helperText:
                        'Khoảng: ${HealthValidators.minWeight}-${HealthValidators.maxWeight} kg',
                  ),
                  validator: HealthValidators.validateWeight,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Chiều cao (cm)',
                    hintText: 'Nhập chiều cao của bạn',
                    prefixIcon: const Icon(Icons.height),
                    helperText:
                        'Khoảng: ${HealthValidators.minHeight}-${HealthValidators.maxHeight} cm',
                  ),
                  validator: HealthValidators.validateHeight,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày dự sinh'),
                  subtitle: Text(
                    _dueDate == null
                        ? 'Chọn ngày dự sinh'
                        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDueDate(context),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Ngày đầu kỳ kinh cuối (không bắt buộc)'),
                  subtitle: Text(
                    _lastPeriodDate == null
                        ? 'Chọn ngày đầu kỳ kinh cuối'
                        : '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectLastPeriodDate(context),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savePregnancy,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Tiếp tục'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (widget.fromModeSwitch) {
                        Navigator.of(context).pop();
                        return;
                      }
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainNavigation(),
                        ),
                      );
                    },
                    child: const Text('Bỏ qua lúc này'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 200)),
      firstDate: now.subtract(const Duration(days: 14)),
      lastDate: now.add(const Duration(days: PregnancyModel.gestationDays)),
    );

    if (picked != null) {
      setState(() {
        // Due date and LMP are linked (+/- 280 days) so the current week and
        // days-left counter always agree.
        _dueDate = picked;
        _lastPeriodDate = PregnancyModel.lastPeriodFromDueDate(picked);
      });
    }
  }

  Future<void> _selectLastPeriodDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _lastPeriodDate ?? now.subtract(const Duration(days: 90)),
      firstDate: now.subtract(
        const Duration(days: PregnancyModel.gestationDays + 14),
      ),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _lastPeriodDate = picked;
        _dueDate = PregnancyModel.dueDateFromLastPeriod(picked);
      });
    }
  }

  Future<void> _savePregnancy() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày dự sinh')),
      );
      return;
    }

    final pregnancy = PregnancyModel(
      id: const Uuid().v4(),
      dueDate: _dueDate!,
      motherName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      prePregnancyWeight: HealthValidators.parseDecimal(_weightController.text),
      height: HealthValidators.parseDecimal(_heightController.text),
      lastPeriodDate: PregnancyModel.lastPeriodFromDueDate(_dueDate!),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Marks any previously active pregnancy as inactive.
    await DatabaseService.saveNewActivePregnancy(pregnancy);
    await ref.read(appModeProvider.notifier).setMode(AppMode.pregnancy);

    if (!mounted) return;

    if (widget.fromModeSwitch) {
      ref.read(navigationIndexProvider.notifier).state = 0;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (_) => false,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}
