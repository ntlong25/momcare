import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/health_log_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/date_picker_utils.dart';
import '../../../core/utils/health_validators.dart';

class AddHealthLogScreen extends StatefulWidget {
  final HealthLogModel? log;

  const AddHealthLogScreen({super.key, this.log});

  @override
  State<AddHealthLogScreen> createState() => _AddHealthLogScreenState();
}

class _AddHealthLogScreenState extends State<AddHealthLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedMood;
  List<String> _selectedSymptoms = [];

  final List<String> _moods = [
    'Vui vẻ',
    'Bình tĩnh',
    'Lo lắng',
    'Mệt mỏi',
    'Nhiều năng lượng',
    'Khó chịu',
  ];

  final List<String> _symptoms = [
    'Buồn nôn',
    'Đau đầu',
    'Đau lưng',
    'Sưng phù',
    'Ợ nóng',
    'Mệt mỏi',
    'Cơn co',
    'Chuột rút',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.log != null) {
      _loadExistingLog();
    }
  }

  void _loadExistingLog() {
    final log = widget.log!;
    _selectedDate = log.date;
    _weightController.text = log.weight?.toString() ?? '';
    _systolicController.text = log.systolicBP?.toString() ?? '';
    _diastolicController.text = log.diastolicBP?.toString() ?? '';
    _notesController.text = log.notes ?? '';
    _selectedMood = log.mood;
    _selectedSymptoms = log.symptoms ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.log != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Sửa ghi nhận sức khỏe' : 'Thêm ghi nhận sức khỏe',
        ),
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
              _buildDateSelector(),
              const SizedBox(height: 24),
              Text('Chỉ số', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildWeightField(),
              const SizedBox(height: 16),
              _buildBloodPressureFields(),
              const SizedBox(height: 24),
              Text('Tâm trạng', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildMoodSelector(),
              const SizedBox(height: 24),
              Text(
                'Triệu chứng',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSymptomsSelector(),
              const SizedBox(height: 24),
              Text('Ghi chú', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveLog,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(isEdit ? 'Cập nhật' : 'Lưu'),
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
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Cân nặng (kg)',
        hintText: 'Nhập cân nặng của bạn',
        prefixIcon: const Icon(Icons.monitor_weight),
        helperText:
            'Khoảng: ${HealthValidators.minWeight}-${HealthValidators.maxWeight} kg',
      ),
      validator: HealthValidators.validateWeight,
    );
  }

  Widget _buildBloodPressureFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _systolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tâm thu',
                  hintText: '120',
                  prefixIcon: Icon(Icons.favorite),
                ),
                validator: (value) {
                  // First validate individual value
                  final error = HealthValidators.validateSystolicBP(value);
                  if (error != null) return error;

                  // Then validate pair if both values present
                  return HealthValidators.validateBloodPressurePair(
                    value,
                    _diastolicController.text,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tâm trương',
                  hintText: '80',
                  prefixIcon: Icon(Icons.favorite),
                ),
                validator: HealthValidators.validateDiastolicBP,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Bình thường: <120/<80 mmHg',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _moods.map((mood) {
        final isSelected = _selectedMood == mood;
        return ChoiceChip(
          label: Text(mood),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedMood = selected ? mood : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSymptomsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptoms.map((symptom) {
        final isSelected = _selectedSymptoms.contains(symptom);
        return FilterChip(
          label: Text(symptom),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.remove(symptom);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Ghi chú',
        hintText: 'Hôm nay bạn cảm thấy thế nào?',
        alignLabelWithHint: true,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await DatePickerUtils.pickDate(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      includeInitial: widget.log != null,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = HealthValidators.parseDecimal(_weightController.text);
    final systolic = int.tryParse(_systolicController.text.trim());
    final diastolic = int.tryParse(_diastolicController.text.trim());
    final notes = _notesController.text.trim();

    if (!HealthValidators.hasHealthLogContent(
      weight: weight,
      systolicBP: systolic,
      diastolicBP: diastolic,
      mood: _selectedMood,
      symptoms: _selectedSymptoms,
      notes: notes,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy nhập ít nhất một chỉ số, tâm trạng, triệu chứng hoặc ghi chú',
          ),
        ),
      );
      return;
    }

    final log = HealthLogModel(
      id: widget.log?.id ?? const Uuid().v4(),
      date: _selectedDate,
      weight: weight,
      systolicBP: systolic,
      diastolicBP: diastolic,
      mood: _selectedMood,
      symptoms: _selectedSymptoms.isEmpty ? null : _selectedSymptoms,
      notes: notes.isEmpty ? null : notes,
      createdAt: widget.log?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveHealthLog(log);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi nhận'),
        content: const Text(
          'Bạn có chắc muốn xóa ghi nhận sức khỏe này không?',
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await DatabaseService.deleteHealthLog(widget.log!.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
