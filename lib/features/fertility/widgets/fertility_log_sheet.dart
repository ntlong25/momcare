import 'package:flutter/material.dart';

import '../../../core/data/content_pack_service.dart';
import '../../../core/models/fertile_guidance.dart';
import '../../../core/models/fertility_log_model.dart';
import '../../../core/services/fertility_log_service.dart';
import '../../../core/services/fertility_reminder_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';

/// Opens the quick log of [day]. Every choice saves at once, so one tap on
/// the sheet is enough.
Future<void> showFertilityLogSheet(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FertilityLogSheet(day: day),
  );
}

/// Opens the settings of the signals: "Ngày gần gũi" and the reminders.
Future<void> showFertilitySettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const FertilitySettingsSheet(),
  );
}

class FertilityLogSheet extends StatefulWidget {
  final DateTime day;

  const FertilityLogSheet({super.key, required this.day});

  @override
  State<FertilityLogSheet> createState() => _FertilityLogSheetState();
}

class _FertilityLogSheetState extends State<FertilityLogSheet> {
  final _temperature = TextEditingController();
  final _temperatureBox = GlobalKey();
  final bool _showIntimacy = FertilityLogService.showIntimacy;

  LhResult? _lh;
  CervicalMucus? _mucus;
  double? _temperatureC;
  bool _intimacy = false;
  bool _temperatureInvalid = false;
  bool _hasRecord = false;

  FertileGuidance get _guidance => ContentPackService.fertileGuidance;

  @override
  void initState() {
    super.initState();
    final log = FertilityLogService.forDay(widget.day);
    if (log == null) return;
    _hasRecord = true;
    _lh = log.lh;
    _mucus = log.mucus;
    _temperatureC = log.temperatureC;
    _intimacy = log.intimacy;
    final temperature = log.temperatureC;
    if (temperature != null) {
      _temperature.text = FertilityLogModel.formatTemperature(temperature);
    }
  }

  @override
  void dispose() {
    _temperature.dispose();
    super.dispose();
  }

  /// Saves what is on the sheet; an emptied sheet removes the day.
  Future<void> _save() async {
    final log = FertilityLogModel(
      date: widget.day,
      lh: _lh,
      mucus: _mucus,
      temperatureC: _temperatureC,
      intimacy: _intimacy,
      updatedAt: DateTime.now(),
    );
    setState(() => _hasRecord = !log.isEmpty);
    await FertilityLogService.save(log);
  }

  void _onTemperature(String input) {
    final empty = input.trim().isEmpty;
    final value = FertilityLogModel.parseTemperature(input);
    final invalid = !empty && value == null;
    if (invalid != _temperatureInvalid) {
      setState(() => _temperatureInvalid = invalid);
      // The error line changes the field's height: keep all of it in view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = _temperatureBox.currentContext;
        if (box == null || !box.mounted) return;
        Scrollable.ensureVisible(
          box,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    }
    if (invalid) return;
    _temperatureC = value;
    _save();
  }

  Future<void> _delete() async {
    final guidance = _guidance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(guidance.text('log_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(guidance.text('log_delete_cancel')),
          ),
          FilledButton(
            key: const ValueKey('fertility-log-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(guidance.text('log_delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop();
    await FertilityLogService.deleteDay(widget.day);
  }

  Widget _heading(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    child: Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _chips<T>({
    required String prefix,
    required List<T> values,
    required String Function(T) label,
    required T? selected,
    required ValueChanged<T?> onChanged,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final value in values)
          ChoiceChip(
            key: ValueKey('$prefix-${(value as Enum).name}'),
            label: Text(label(value)),
            selected: selected == value,
            onSelected: (isSelected) {
              onChanged(isSelected ? value : null);
              _save();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guidance = _guidance;
    // The keyboard inset is outside the scroll view, so its viewport ends at
    // the keyboard and a focused field scrolls fully above it (P25-F-05).
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        key: const ValueKey('fertility-log-sheet'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${guidance.text('signals_log_day')} '
              '${DateFormatter.formatDate(widget.day)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            _heading(theme, guidance.text('lh_label')),
            _chips<LhResult>(
              prefix: 'fertility-lh',
              values: LhResult.values,
              label: guidance.lhLabel,
              selected: _lh,
              onChanged: (value) => _lh = value,
            ),
            _heading(theme, guidance.text('mucus_label')),
            _chips<CervicalMucus>(
              prefix: 'fertility-mucus',
              values: CervicalMucus.values,
              label: guidance.mucusLabel,
              selected: _mucus,
              onChanged: (value) => _mucus = value,
            ),
            _heading(theme, guidance.text('temperature_label')),
            KeyedSubtree(
              key: _temperatureBox,
              child: TextField(
                key: const ValueKey('fertility-temperature'),
                controller: _temperature,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: guidance.text('temperature_hint'),
                  suffixText: '°C',
                  errorText: _temperatureInvalid
                      ? guidance.text('temperature_invalid')
                      : null,
                  errorMaxLines: 3,
                ),
                onChanged: _onTemperature,
                // Room for the error line below the field.
                scrollPadding: const EdgeInsets.all(AppSpacing.xxl * 2),
              ),
            ),
            if (_showIntimacy) ...[
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                key: const ValueKey('fertility-intimacy'),
                contentPadding: EdgeInsets.zero,
                title: Text(guidance.text('intimacy_label')),
                value: _intimacy,
                onChanged: (value) {
                  _intimacy = value;
                  _save();
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('fertility-log-done'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(guidance.text('log_done')),
              ),
            ),
            if (_hasRecord)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const ValueKey('fertility-log-delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: _delete,
                  child: Text(guidance.text('log_delete')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FertilitySettingsSheet extends StatefulWidget {
  const FertilitySettingsSheet({super.key});

  @override
  State<FertilitySettingsSheet> createState() => _FertilitySettingsSheetState();
}

class _FertilitySettingsSheetState extends State<FertilitySettingsSheet> {
  bool _showIntimacy = FertilityLogService.showIntimacy;
  FertilityReminderSettings _reminders = FertilityReminderService.load();
  bool _denied = false;

  FertileGuidance get _guidance => ContentPackService.fertileGuidance;

  Future<void> _apply(FertilityReminderSettings settings) async {
    setState(() {
      _reminders = settings;
      _denied = false;
    });
    final allowed = await FertilityReminderService.update(settings);
    if (!mounted) return;
    setState(() {
      _denied = !allowed;
      _reminders = FertilityReminderService.load();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminders.hour, minute: _reminders.minute),
      // Keyboard input in 24h too: typing 08 must not be saved as 20:00 on
      // a 12-hour device (P25-R1-01).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _apply(_reminders.copyWith(hour: picked.hour, minute: picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guidance = _guidance;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final time = TimeOfDay(hour: _reminders.hour, minute: _reminders.minute);
    return SingleChildScrollView(
      key: const ValueKey('fertility-settings-sheet'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            guidance.text('signals_settings'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: const ValueKey('fertility-setting-intimacy'),
            contentPadding: EdgeInsets.zero,
            title: Text(guidance.text('intimacy_setting')),
            subtitle: Text(guidance.text('intimacy_setting_note')),
            value: _showIntimacy,
            onChanged: (value) {
              setState(() => _showIntimacy = value);
              FertilityLogService.setShowIntimacy(value);
            },
          ),
          const Divider(),
          Text(
            guidance.text('reminder_title'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SwitchListTile(
            key: const ValueKey('fertility-setting-reminder-window'),
            contentPadding: EdgeInsets.zero,
            title: Text(guidance.text('reminder_window')),
            value: _reminders.windowEnabled,
            onChanged: (value) =>
                _apply(_reminders.copyWith(windowEnabled: value)),
          ),
          SwitchListTile(
            key: const ValueKey('fertility-setting-reminder-lh'),
            contentPadding: EdgeInsets.zero,
            title: Text(guidance.text('reminder_lh')),
            value: _reminders.lhEnabled,
            onChanged: (value) => _apply(_reminders.copyWith(lhEnabled: value)),
          ),
          if (_reminders.windowEnabled) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              guidance.text('style_label'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final style in FertilityNotificationStyle.values)
                  ChoiceChip(
                    key: ValueKey('fertility-style-${style.name}'),
                    label: Text(
                      guidance.text(switch (style) {
                        FertilityNotificationStyle.discreet => 'style_discreet',
                        FertilityNotificationStyle.full => 'style_full',
                      }),
                    ),
                    selected: _reminders.style == style,
                    onSelected: (selected) {
                      if (selected) _apply(_reminders.copyWith(style: style));
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(guidance.text('style_note'), style: muted),
          ],
          if (_reminders.anyEnabled)
            ListTile(
              key: const ValueKey('fertility-setting-reminder-time'),
              contentPadding: EdgeInsets.zero,
              title: Text(guidance.text('reminder_time')),
              trailing: Text(
                MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(time, alwaysUse24HourFormat: true),
              ),
              onTap: _pickTime,
            ),
          if (_denied)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                guidance.text('reminder_denied'),
                key: const ValueKey('fertility-reminder-denied'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Text(guidance.text('reminder_note'), style: muted),
        ],
      ),
    );
  }
}
