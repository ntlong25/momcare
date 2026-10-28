import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/daily_item_model.dart';
import '../../../core/services/thai_giao_progress_service.dart';
import '../../../core/services/thai_giao_reminder_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../references/widgets/draft_content_note.dart';

/// Today's thai giáo activity with a "Đã làm" toggle, streak and an opt-in
/// daily reminder. Hidden when the pack has no item.
class TodayThaiGiaoCard extends ConsumerStatefulWidget {
  static const Map<String, String> categoryLabels = {
    'talk': 'Trò chuyện',
    'music': 'Âm nhạc',
    'movement': 'Vận động nhẹ',
    'reading': 'Đọc truyện',
    'breathing': 'Hít thở',
    'partner': 'Cùng bố',
    'journal': 'Nhật ký',
  };

  final int day;

  /// Overrides the loaded pack (tests only).
  final DailyPack? pack;

  /// Overrides `DateTime.now` (tests only).
  final DateTime Function()? clock;

  const TodayThaiGiaoCard({
    super.key,
    required this.day,
    this.pack,
    this.clock,
  });

  @override
  ConsumerState<TodayThaiGiaoCard> createState() => _TodayThaiGiaoCardState();
}

class _TodayThaiGiaoCardState extends ConsumerState<TodayThaiGiaoCard> {
  ThaiGiaoReminderSettings _reminder = const ThaiGiaoReminderSettings();
  bool _reminderBusy = false;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final settings = await ThaiGiaoReminderService.load();
    if (!mounted) return;
    setState(() => _reminder = settings);
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack ?? ContentPackService.thaiGiaoPack;
    final item = pack.itemForDay(widget.day);
    if (item == null) return const SizedBox.shrink();

    // Watch so the toggle and streak update immediately.
    ref.watch(thaiGiaoProgressProvider);
    final progress = ref.read(thaiGiaoProgressProvider.notifier);
    final now = _now();
    final done = progress.isDone(now);
    final streak = progress.streakAt(now);
    final theme = Theme.of(context);
    final label = TodayThaiGiaoCard.categoryLabels[item.category];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.child_care, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thai giáo hôm nay',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (label != null)
                  Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                  ),
                if (item.durationMin != null)
                  Text(
                    '~${item.durationMin} phút',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  key: const ValueKey('thai-giao-done'),
                  label: const Text('Đã làm'),
                  selected: done,
                  // Pale tint + onSurface keeps >= 4.5:1 in both themes (the
                  // default secondaryContainer is light-on-light in dark).
                  selectedColor: AppTheme.primaryTint(theme.colorScheme),
                  checkmarkColor: theme.colorScheme.onSurface,
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                  // Read the clock at tap time: the card may have been built
                  // before midnight.
                  onSelected: (value) => progress.setDone(_now(), value),
                ),
                if (streak > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chuỗi $streak ngày',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildReminderRow(context),
            if (pack.isDraft) ...[
              const SizedBox(height: 12),
              const DraftContentNote(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderRow(BuildContext context) {
    final theme = Theme.of(context);
    final time = _formatTime(_reminder.hour, _reminder.minute);
    return Row(
      children: [
        Icon(
          _reminder.enabled
              ? Icons.notifications_active
              : Icons.notifications_none,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: _reminder.enabled && !_reminderBusy ? _changeTime : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhắc thai giáo hằng ngày'),
                Text(
                  _reminder.enabled
                      ? 'Lúc $time · chạm để đổi giờ'
                      : 'Đang tắt',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        Switch(
          key: const ValueKey('thai-giao-reminder-switch'),
          value: _reminder.enabled,
          onChanged: _reminderBusy ? null : _toggleReminder,
        ),
      ],
    );
  }

  static String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _toggleReminder(bool enable) async {
    if (!enable) {
      setState(() => _reminderBusy = true);
      await ThaiGiaoReminderService.disable();
      await _loadReminder();
      if (mounted) setState(() => _reminderBusy = false);
      return;
    }
    await _pickTimeAndEnable();
  }

  Future<void> _changeTime() => _pickTimeAndEnable();

  Future<void> _pickTimeAndEnable() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
      // The vi picker shows a 24h dial; keep keyboard input in 24h too so
      // typing 02:30 is not saved as 14:30 on 12-hour devices.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() => _reminderBusy = true);
    final enabled = await ThaiGiaoReminderService.enable(
      time.hour,
      time.minute,
    );
    await _loadReminder();
    if (!mounted) return;
    setState(() => _reminderBusy = false);
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn chưa cấp quyền thông báo nên chưa thể bật nhắc thai giáo. '
            'Hoạt động hằng ngày vẫn dùng được bình thường.',
          ),
        ),
      );
    }
  }
}
