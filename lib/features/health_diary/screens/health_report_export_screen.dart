import 'package:flutter/material.dart';

import '../../../core/models/health_log_model.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/share_helper.dart';
import '../export/health_report.dart';

enum HealthReportPreset { last30Days, sincePregnancy, custom }

/// "Xuất PDF cho bác sĩ": pick a range, build the health diary PDF on the
/// device and share it.
class HealthReportExportScreen extends StatefulWidget {
  /// Overrides for tests; by default read from [DatabaseService]. When
  /// [logs] is given, [pregnancy] is used as is (null = no pregnancy).
  final List<HealthLogModel>? logs;
  final PregnancyModel? pregnancy;
  final DateTime Function()? now;

  /// False in pre-pregnancy mode: no "Từ đầu thai kỳ" range.
  final bool includePregnancy;

  const HealthReportExportScreen({
    super.key,
    this.logs,
    this.pregnancy,
    this.now,
    this.includePregnancy = true,
  });

  static const String emptyMessage =
      'Không có ghi nhận trong khoảng thời gian này.';
  static const String errorMessage =
      'Không tạo được file PDF. Vui lòng thử lại.';

  @override
  State<HealthReportExportScreen> createState() =>
      _HealthReportExportScreenState();
}

class _HealthReportExportScreenState extends State<HealthReportExportScreen> {
  late final List<HealthLogModel> _logs;
  PregnancyModel? _pregnancy;
  HealthReportPreset _preset = HealthReportPreset.last30Days;
  late HealthReportRange _range;
  bool _busy = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    if (widget.logs != null) {
      _logs = widget.logs!;
      _pregnancy = widget.pregnancy;
    } else {
      _logs = _loadLogs();
      _pregnancy = widget.pregnancy ?? _loadPregnancy();
    }
    if (!widget.includePregnancy) _pregnancy = null;
    _range = HealthReportRange.last30Days(_now());
  }

  static List<HealthLogModel> _loadLogs() {
    try {
      return DatabaseService.getAllHealthLogs();
    } catch (error) {
      AppLogger.instance.warning('Could not read health logs: $error');
      return const [];
    }
  }

  static PregnancyModel? _loadPregnancy() {
    try {
      return DatabaseService.getActivePregnancy();
    } catch (_) {
      return null;
    }
  }

  void _select(HealthReportPreset preset) {
    final now = _now();
    switch (preset) {
      case HealthReportPreset.last30Days:
        setState(() {
          _preset = preset;
          _range = HealthReportRange.last30Days(now);
        });
      case HealthReportPreset.sincePregnancy:
        final pregnancy = _pregnancy;
        if (pregnancy == null) return;
        setState(() {
          _preset = preset;
          _range = HealthReportRange.sincePregnancyStart(pregnancy, now);
        });
      case HealthReportPreset.custom:
        _pickCustomRange();
    }
  }

  Future<void> _pickCustomRange() async {
    final today = HealthReportRange.dateOnly(_now());
    final first = DateTime(today.year - 5, today.month, today.day);
    var start = _range.from.isBefore(first) ? first : _range.from;
    final end = _range.to.isAfter(today) ? today : _range.to;
    if (start.isAfter(end)) start = end;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: 'Chọn khoảng thời gian',
      saveText: 'Xong',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = HealthReportPreset.custom;
      _range = HealthReportRange(picked.start, picked.end);
    });
  }

  Future<void> _share(BuildContext buttonContext) async {
    if (_busy) return;
    final origin = ShareHelper.originOf(buttonContext);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final fonts = await HealthReportFonts.load();
      final bytes = await HealthReportPdf.build(
        logs: _logs,
        range: _range,
        pregnancy: _pregnancy,
        generatedAt: _now(),
        regular: fonts.regular,
        bold: fonts.bold,
      );
      final file = await ShareHelper.writeTempFile(_range.fileName, bytes);
      await ShareHelper.shareFile(
        file.path,
        mimeType: 'application/pdf',
        text: HealthReportPdf.title,
        origin: origin,
      );
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'Could not export health diary PDF',
        error: error,
        stackTrace: stackTrace,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text(HealthReportExportScreen.errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = HealthReport.filterLogs(_logs, _range);
    final preview = HealthReport.rowsFor(selected.take(3).toList());
    final count = selected.length;

    // Local colours: the stock dark-mode selected chip (pale secondary
    // container with light text) is unreadable. onSurface on the surface /
    // primary tint keeps >= 4.5:1 in both themes.
    final scheme = theme.colorScheme;
    Widget chip(HealthReportPreset preset, String label) {
      final selected = _preset == preset;
      return ChoiceChip(
        key: ValueKey('health-export-${preset.name}'),
        label: Text(label),
        selected: selected,
        onSelected: _busy ? null : (_) => _select(preset),
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTheme.primaryTint(scheme)
              : scheme.surface,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        checkmarkColor: scheme.onSurface,
        side: BorderSide(color: selected ? scheme.primary : scheme.outline),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Xuất PDF cho bác sĩ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Khoảng thời gian', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(HealthReportPreset.last30Days, '30 ngày qua'),
              if (_pregnancy != null)
                chip(HealthReportPreset.sincePregnancy, 'Từ đầu thai kỳ'),
              chip(HealthReportPreset.custom, 'Tùy chọn'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Từ ${DateFormatter.formatDate(_range.from)} đến '
            '${DateFormatter.formatDate(_range.to)} · $count ghi nhận',
            key: const ValueKey('health-export-summary'),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (preview.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xem trước', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final row in preview) _PreviewRow(row: row),
                    if (count > preview.length)
                      Text(
                        'và ${count - preview.length} ghi nhận khác',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (count == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                HealthReportExportScreen.emptyMessage,
                key: const ValueKey('health-export-empty'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
          Builder(
            builder: (buttonContext) => FilledButton.tonalIcon(
              key: const ValueKey('health-export-share'),
              style: AppTheme.tonalButtonStyle(theme.colorScheme),
              onPressed: count == 0 || _busy
                  ? null
                  : () => _share(buttonContext),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Tạo và chia sẻ PDF'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'File PDF được tạo trên máy và chỉ được gửi đi khi bạn chọn ứng dụng để chia sẻ.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            HealthReportPdf.disclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final List<String> row;

  const _PreviewRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (row[1] != HealthReport.missing) '${row[1]} kg',
      if (row[2] != HealthReport.missing) '${row[2]} mmHg',
      if (row[3] != HealthReport.missing) row[3],
    ];
    final note = row[4] != HealthReport.missing ? row[4] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row[0],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            parts.isEmpty ? HealthReport.missing : parts.join(' · '),
            style: theme.textTheme.bodyMedium,
          ),
          if (note != null)
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
