import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/my_clinic.dart';
import '../../../core/services/my_clinic_service.dart';

/// Editor for "Nơi khám của tôi" (B9), stored on this device only.
class MyClinicScreen extends ConsumerStatefulWidget {
  const MyClinicScreen({super.key});

  static const int maxFieldLength = 120;
  static const String invalidPhone = 'Số điện thoại không hợp lệ';

  /// Empty is allowed; otherwise digits, spaces and `+ - . ( )` with at least
  /// 3 digits.
  static String? validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[0-9+\-.() ]+$').hasMatch(text)) return invalidPhone;
    if (text.replaceAll(RegExp(r'[^0-9]'), '').length < 3) {
      return invalidPhone;
    }
    return null;
  }

  @override
  ConsumerState<MyClinicScreen> createState() => _MyClinicScreenState();
}

class _MyClinicScreenState extends ConsumerState<MyClinicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _doctor = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fill(ref.read(myClinicProvider));
    // The profile may still be loading from prefs on first open.
    ref.read(myClinicProvider.notifier).ready.then((_) {
      if (!mounted || !_formIsEmpty) return;
      _fill(ref.read(myClinicProvider));
      setState(() {});
    });
  }

  void _fill(MyClinic clinic) {
    _name.text = clinic.name;
    _doctor.text = clinic.doctor;
    _phone.text = clinic.phone;
    _address.text = clinic.address;
  }

  bool get _formIsEmpty =>
      [_name, _doctor, _phone, _address].every((c) => c.text.isEmpty);

  @override
  void dispose() {
    _name.dispose();
    _doctor.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final clinic = MyClinic.trimmed(
      name: _name.text,
      doctor: _doctor.text,
      phone: _phone.text,
      address: _address.text,
    );
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref.read(myClinicProvider.notifier).save(clinic);
    if (!mounted) return;
    messenger?.showSnackBar(const SnackBar(content: Text('Đã lưu nơi khám')));
    Navigator.of(context).maybePop();
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông tin nơi khám?'),
        content: const Text(
          'Tên, bác sĩ, số điện thoại và địa chỉ đã lưu sẽ bị xóa khỏi thiết bị này.',
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(myClinicProvider.notifier).clear();
    if (!mounted) return;
    _fill(MyClinic.empty);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = ref.watch(myClinicProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nơi khám của tôi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Lưu nơi bạn đang khám thai để gọi hoặc mở bản đồ nhanh khi cần.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('clinic-name'),
              controller: _name,
              maxLength: MyClinicScreen.maxFieldLength,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tên bệnh viện / phòng khám',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('clinic-doctor'),
              controller: _doctor,
              maxLength: MyClinicScreen.maxFieldLength,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Bác sĩ theo dõi',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('clinic-phone'),
              controller: _phone,
              maxLength: MyClinicScreen.maxFieldLength,
              keyboardType: TextInputType.phone,
              validator: MyClinicScreen.validatePhone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.call_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('clinic-address'),
              controller: _address,
              maxLength: MyClinicScreen.maxFieldLength,
              minLines: 1,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phonelink_lock,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Thông tin chỉ lưu trên thiết bị này.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('clinic-save'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu'),
            ),
            if (!saved.isEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('clinic-clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa thông tin'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
