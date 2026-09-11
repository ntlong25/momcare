import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/menstrual_cycle_model.dart';
import '../../../core/services/database_service.dart';

class AddPeriodScreen extends StatefulWidget {
  const AddPeriodScreen({super.key});

  @override
  State<AddPeriodScreen> createState() => _AddPeriodScreenState();
}

class _AddPeriodScreenState extends State<AddPeriodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _flowIntensity = 'medium';
  final List<String> _selectedSymptoms = [];

  final List<String> _availableSymptoms = [
    'Chuột rút',
    'Đau đầu',
    'Thay đổi tâm trạng',
    'Mệt mỏi',
    'Đầy hơi',
    'Căng tức ngực',
    'Đau lưng',
    'Mụn',
    'Buồn nôn',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePeriod() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate cycle length if there's a previous cycle
    final lastCycle = DatabaseService.getLastMenstrualCycle();
    int? cycleLength;
    if (lastCycle != null) {
      cycleLength = _startDate!.difference(lastCycle.startDate).inDays;
    }

    // Calculate period length if end date is selected
    int? periodLength;
    if (_endDate != null) {
      periodLength = _endDate!.difference(_startDate!).inDays + 1;
    }

    final cycle = MenstrualCycleModel(
      id: const Uuid().v4(),
      startDate: _startDate!,
      endDate: _endDate,
      cycleLengthDays: cycleLength,
      periodLengthDays: periodLength,
      flowIntensity: _flowIntensity,
      symptoms: _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      isFromHealthKit: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveMenstrualCycle(cycle);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm kỳ kinh')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin kỳ kinh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Colors.red),
                title: const Text('Ngày bắt đầu *'),
                subtitle: Text(
                  _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Chọn ngày bắt đầu',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      // Reset end date if it's before start date
                      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                        _endDate = null;
                      }
                    });
                  }
                },
              ),
              const Divider(),

              // End Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, color: Colors.red),
                title: const Text('Ngày kết thúc (không bắt buộc)'),
                subtitle: Text(
                  _endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Chọn ngày kết thúc nếu kỳ kinh đã hết',
                ),
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _startDate == null
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _endDate ??
                              _startDate!.add(const Duration(days: 5)),
                          firstDate: _startDate!,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _endDate = picked;
                          });
                        }
                      },
              ),
              const Divider(),

              const SizedBox(height: 24),

              // Flow Intensity
              Text(
                'Lượng kinh',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'light',
                    label: Text('Ít'),
                    icon: Icon(Icons.water_drop_outlined),
                  ),
                  ButtonSegment(
                    value: 'medium',
                    label: Text('Vừa'),
                    icon: Icon(Icons.water_drop),
                  ),
                  ButtonSegment(
                    value: 'heavy',
                    label: Text('Nhiều'),
                    icon: Icon(Icons.water),
                  ),
                ],
                selected: {_flowIntensity},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _flowIntensity = newSelection.first;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Symptoms
              Text(
                'Triệu chứng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSymptoms.map((symptom) {
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
              ),

              const SizedBox(height: 24),

              // Notes
              Text(
                'Ghi chú (không bắt buộc)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Thêm ghi chú nếu cần...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePeriod,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Lưu kỳ kinh'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
