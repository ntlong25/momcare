import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  final AppointmentModel? appointment;

  const AddAppointmentScreen({super.key, this.appointment});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _reminderEnabled = true;
  int _reminderMinutes = 60;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _loadExistingAppointment();
    }
  }

  void _loadExistingAppointment() {
    final apt = widget.appointment!;
    _titleController.text = apt.title;
    _locationController.text = apt.location ?? '';
    _doctorController.text = apt.doctorName ?? '';
    _notesController.text = apt.notes ?? '';
    _selectedDate = apt.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(apt.dateTime);
    _reminderEnabled = apt.reminderEnabled;
    _reminderMinutes = apt.reminderMinutesBefore;
    _isCompleted = apt.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appointment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa lịch hẹn' : 'Thêm lịch hẹn'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  hintText: 'Ví dụ: Khám thai định kỳ',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Ngày và giờ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateSelector()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeSelector()),
                ],
              ),
              const SizedBox(height: 24),
              Text('Chi tiết', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Tên bác sĩ',
                  hintText: 'Nhập tên bác sĩ',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm',
                  hintText: 'Nhập địa điểm/phòng khám',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Ghi chú thêm',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.note),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Nhắc hẹn', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Bật nhắc hẹn'),
                subtitle: const Text('Nhận thông báo trước lịch hẹn'),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _reminderMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Nhắc trước',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 phút')),
                    DropdownMenuItem(value: 30, child: Text('30 phút')),
                    DropdownMenuItem(value: 60, child: Text('1 giờ')),
                    DropdownMenuItem(value: 120, child: Text('2 giờ')),
                    DropdownMenuItem(value: 1440, child: Text('1 ngày')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _reminderMinutes = value;
                      });
                    }
                  },
                ),
              ],
              if (isEdit) ...[
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Đánh dấu đã hoàn tất'),
                  value: _isCompleted,
                  onChanged: (value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAppointment,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(isEdit ? 'Cập nhật lịch hẹn' : 'Lưu lịch hẹn'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Ngày', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Giờ', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTime.format(context),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = AppointmentModel(
      id: widget.appointment?.id ?? const Uuid().v4(),
      title: _titleController.text,
      dateTime: appointmentDateTime,
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      doctorName: _doctorController.text.isEmpty
          ? null
          : _doctorController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      isCompleted: _isCompleted,
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderMinutes,
      createdAt: widget.appointment?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveAppointment(appointment);

    // Schedule notification if reminder is enabled
    if (_reminderEnabled && !_isCompleted) {
      await NotificationService.scheduleAppointmentReminder(
        id: appointment.id.hashCode,
        title: appointment.title,
        appointmentTime: appointmentDateTime,
        minutesBefore: _reminderMinutes,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch hẹn'),
        content: const Text('Bạn có chắc muốn xóa lịch hẹn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await DatabaseService.deleteAppointment(widget.appointment!.id);
      // Cancel notification
      await NotificationService.cancelNotification(
        widget.appointment!.id.hashCode,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
