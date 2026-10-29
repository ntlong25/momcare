import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/health_log_model.dart';
import '../../../core/models/pregnancy_model.dart';
import '../../../core/utils/date_formatter.dart';

/// Inclusive date-only range for the health diary PDF.
class HealthReportRange {
  final DateTime from;
  final DateTime to;

  HealthReportRange._(this.from, this.to);

  /// Normalises both ends to midnight; swaps them if [from] is after [to].
  factory HealthReportRange(DateTime from, DateTime to) {
    final a = dateOnly(from);
    final b = dateOnly(to);
    return a.isAfter(b) ? HealthReportRange._(b, a) : HealthReportRange._(a, b);
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// The 30 days up to and including today.
  factory HealthReportRange.last30Days(DateTime now) =>
      HealthReportRange(DateTime(now.year, now.month, now.day - 29), now);

  /// From the pregnancy's week 0 to today (just today if it starts later).
  factory HealthReportRange.sincePregnancyStart(
    PregnancyModel pregnancy,
    DateTime now,
  ) {
    final start = pregnancy.pregnancyStartDate;
    return HealthReportRange(start.isAfter(now) ? now : start, now);
  }

  bool contains(DateTime value) {
    final day = dateOnly(value);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  /// `yyyyMMdd_yyyyMMdd`-based PDF file name.
  String get fileName =>
      'momcare_nhat_ky_${_compact(from)}_${_compact(to)}.pdf';

  static String _compact(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  /// "dd/MM/yyyy – dd/MM/yyyy".
  String get label =>
      '${DateFormatter.formatDate(from)} – ${DateFormatter.formatDate(to)}';

  @override
  bool operator ==(Object other) =>
      other is HealthReportRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Numbers only; the report never labels values as normal or abnormal.
class HealthReportSummary {
  final int count;
  final double? firstWeight;
  final DateTime? firstWeightDate;
  final double? lastWeight;
  final DateTime? lastWeightDate;
  final int? minSystolic;
  final int? maxSystolic;
  final int? minDiastolic;
  final int? maxDiastolic;

  const HealthReportSummary({
    required this.count,
    this.firstWeight,
    this.firstWeightDate,
    this.lastWeight,
    this.lastWeightDate,
    this.minSystolic,
    this.maxSystolic,
    this.minDiastolic,
    this.maxDiastolic,
  });

  bool get hasBloodPressure => minSystolic != null;

  /// Summary lines shown in the PDF.
  List<String> get lines => [
    'Số ghi nhận: $count',
    if (firstWeight != null && lastWeight != null)
      firstWeightDate == lastWeightDate
          ? 'Cân nặng: ${HealthReport.formatWeight(lastWeight!)} kg '
                '(${DateFormatter.formatDate(lastWeightDate!)})'
          : 'Cân nặng: ${HealthReport.formatWeight(firstWeight!)} kg '
                '(${DateFormatter.formatDate(firstWeightDate!)}) – '
                '${HealthReport.formatWeight(lastWeight!)} kg '
                '(${DateFormatter.formatDate(lastWeightDate!)})',
    if (hasBloodPressure)
      'Huyết áp tâm thu: $minSystolic – $maxSystolic mmHg · '
          'tâm trương: $minDiastolic – $maxDiastolic mmHg',
  ];
}

/// Pure helpers for the health diary report.
class HealthReport {
  const HealthReport._();

  static const String missing = '—';

  static const List<String> headers = [
    'Ngày',
    'Cân nặng (kg)',
    'Huyết áp (mmHg)',
    'Triệu chứng',
    'Ghi chú',
  ];

  static String formatWeight(double weight) => weight.toStringAsFixed(1);

  /// Logs on a day inside [range], oldest first.
  static List<HealthLogModel> filterLogs(
    List<HealthLogModel> logs,
    HealthReportRange range,
  ) =>
      logs.where((log) => range.contains(log.date)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  static String? bloodPressure(HealthLogModel log) =>
      log.systolicBP != null && log.diastolicBP != null
      ? '${log.systolicBP}/${log.diastolicBP}'
      : null;

  /// One row per log in [headers] order; "—" for missing values.
  static List<List<String>> rowsFor(List<HealthLogModel> logs) => [
    for (final log in logs)
      [
        DateFormatter.formatDate(log.date),
        log.weight != null ? formatWeight(log.weight!) : missing,
        bloodPressure(log) ?? missing,
        _joined(log.symptoms) ?? missing,
        _trimmed(log.notes) ?? missing,
      ],
  ];

  static String? _joined(List<String>? values) {
    final items = [
      for (final value in values ?? const <String>[])
        if (value.trim().isNotEmpty) value.trim(),
    ];
    return items.isEmpty ? null : items.join(', ');
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static HealthReportSummary summary(List<HealthLogModel> logs) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final weighed = sorted.where((log) => log.weight != null).toList();
    final pressures = sorted
        .where((log) => log.systolicBP != null && log.diastolicBP != null)
        .toList();
    int? minOf(Iterable<int> values) =>
        values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b);
    int? maxOf(Iterable<int> values) =>
        values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b);
    final systolic = pressures.map((log) => log.systolicBP!);
    final diastolic = pressures.map((log) => log.diastolicBP!);
    return HealthReportSummary(
      count: logs.length,
      firstWeight: weighed.isEmpty ? null : weighed.first.weight,
      firstWeightDate: weighed.isEmpty ? null : weighed.first.date,
      lastWeight: weighed.isEmpty ? null : weighed.last.weight,
      lastWeightDate: weighed.isEmpty ? null : weighed.last.date,
      minSystolic: minOf(systolic),
      maxSystolic: maxOf(systolic),
      minDiastolic: minOf(diastolic),
      maxDiastolic: maxOf(diastolic),
    );
  }
}

/// Be Vietnam Pro for the PDF (Vietnamese diacritics; the built-in PDF
/// fonts have none).
class HealthReportFonts {
  static const String regularAsset = 'assets/fonts/BeVietnamPro-Regular.ttf';
  static const String boldAsset = 'assets/fonts/BeVietnamPro-Bold.ttf';

  final pw.Font regular;
  final pw.Font bold;

  const HealthReportFonts({required this.regular, required this.bold});

  /// Replaces the asset loader in tests.
  @visibleForTesting
  static Future<HealthReportFonts> Function()? debugLoad;

  static HealthReportFonts? _cache;

  static Future<HealthReportFonts> load([AssetBundle? bundle]) async {
    final override = debugLoad;
    if (override != null) return override();
    final cached = _cache;
    if (cached != null && bundle == null) return cached;
    final source = bundle ?? rootBundle;
    final fonts = HealthReportFonts(
      regular: pw.Font.ttf(await source.load(regularAsset)),
      bold: pw.Font.ttf(await source.load(boldAsset)),
    );
    if (bundle == null) _cache = fonts;
    return fonts;
  }
}

/// Builds the "Nhật ký sức khỏe" PDF for the doctor.
class HealthReportPdf {
  const HealthReportPdf._();

  static const String title = 'Nhật ký sức khỏe – MomCare+';
  static const String disclaimer =
      'Dữ liệu do người dùng tự ghi trong ứng dụng MomCare+, không phải kết quả chẩn đoán.';

  /// Table text size (header and cells).
  static const double tableFontSize = 9;

  /// Horizontal + vertical padding of each table cell (TableHelper default).
  static const double tableCellPadding = 5;

  /// Width of the "Ngày" column, padding included. The widest dd/MM/yyyy in
  /// Be Vietnam Pro Bold at [tableFontSize] is about 61pt (8 x "4" + 2 x
  /// "/") plus 10pt padding, so dates never wrap.
  static const double dateColumnWidth = 76;

  /// [logs] are filtered to [range] and sorted oldest first.
  static pw.Document buildDocument({
    required List<HealthLogModel> logs,
    required HealthReportRange range,
    PregnancyModel? pregnancy,
    required DateTime generatedAt,
    required pw.Font regular,
    required pw.Font bold,
  }) {
    final selected = HealthReport.filterLogs(logs, range);
    final summary = HealthReport.summary(selected);
    final rows = HealthReport.rowsFor(selected);
    final doc = pw.Document(
      title: title,
      creator: 'MomCare+',
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: regular,
        boldItalic: bold,
      ),
    );
    final muted = PdfColor.fromInt(0xFF555555);
    final name = pregnancy?.motherName?.trim();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 32),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  disclaimer,
                  style: pw.TextStyle(fontSize: 8, color: muted),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Trang ${context.pageNumber}/${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Khoảng thời gian: ${range.label}'),
          pw.Text('Ngày tạo: ${DateFormatter.formatDateTime(generatedAt)}'),
          if (pregnancy != null) ...[
            if (name != null && name.isNotEmpty) pw.Text('Họ tên: $name'),
            pw.Text(
              'Ngày dự sinh: ${DateFormatter.formatDate(pregnancy.dueDate)} · '
              'Tuổi thai khi tạo: tuần ${pregnancy.currentWeekAt(generatedAt)}',
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Text(
            'Tóm tắt',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          for (final line in summary.lines) pw.Text(line),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('Không có ghi nhận trong khoảng thời gian này.')
          else
            pw.TableHelper.fromTextArray(
              headers: HealthReport.headers,
              data: rows,
              headerCount: 1,
              headerStyle: pw.TextStyle(
                fontSize: tableFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF6E1E3),
              ),
              cellStyle: const pw.TextStyle(fontSize: tableFontSize),
              cellPadding: const pw.EdgeInsets.all(tableCellPadding),
              cellAlignment: pw.Alignment.topLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                0: pw.FixedColumnWidth(dateColumnWidth),
                1: pw.FixedColumnWidth(54),
                2: pw.FixedColumnWidth(62),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(3),
              },
            ),
        ],
      ),
    );
    return doc;
  }

  static Future<Uint8List> build({
    required List<HealthLogModel> logs,
    required HealthReportRange range,
    PregnancyModel? pregnancy,
    required DateTime generatedAt,
    required pw.Font regular,
    required pw.Font bold,
  }) => buildDocument(
    logs: logs,
    range: range,
    pregnancy: pregnancy,
    generatedAt: generatedAt,
    regular: regular,
    bold: bold,
  ).save();
}
