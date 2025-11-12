import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/health_log_model.dart';
import '../../../core/services/database_service.dart';

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
    'Happy',
    'Calm',
    'Anxious',
    'Tired',
    'Energetic',
    'Uncomfortable',
  ];

  final List<String> _symptoms = [
    'Nausea',
    'Headache',
    'Back pain',
    'Swelling',
    'Heartburn',
    'Fatigue',
    'Contractions',
    'Cramps',
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
        title: Text(isEdit ? 'Edit Health Log' : 'Add Health Log'),
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
              Text(
                'Measurements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildWeightField(),
              const SizedBox(height: 16),
              _buildBloodPressureFields(),
              const SizedBox(height: 24),
              Text(
                'Mood',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildMoodSelector(),
              const SizedBox(height: 24),
              Text(
                'Symptoms',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildSymptomsSelector(),
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveLog,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(isEdit ? 'Update Log' : 'Save Log'),
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
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Weight (kg)',
        hintText: 'Enter your weight',
        prefixIcon: Icon(Icons.monitor_weight),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildBloodPressureFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _systolicController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Systolic BP',
              hintText: '120',
              prefixIcon: Icon(Icons.favorite),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (int.tryParse(value) == null) {
                  return 'Invalid';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _diastolicController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Diastolic BP',
              hintText: '80',
              prefixIcon: Icon(Icons.favorite),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (int.tryParse(value) == null) {
                  return 'Invalid';
                }
              }
              return null;
            },
          ),
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
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Notes',
        hintText: 'How are you feeling today?',
        alignLabelWithHint: true,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final log = HealthLogModel(
      id: widget.log?.id ?? const Uuid().v4(),
      date: _selectedDate,
      weight: _weightController.text.isEmpty
          ? null
          : double.parse(_weightController.text),
      systolicBP: _systolicController.text.isEmpty
          ? null
          : int.parse(_systolicController.text),
      diastolicBP: _diastolicController.text.isEmpty
          ? null
          : int.parse(_diastolicController.text),
      mood: _selectedMood,
      symptoms: _selectedSymptoms.isEmpty ? null : _selectedSymptoms,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
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
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this health log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
