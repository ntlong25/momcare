import 'package:hive/hive.dart';

/// Reading of an LH test as the user saw it.
enum LhResult {
  negative,
  positive,
  peak;

  bool get isPositive => this != LhResult.negative;
}

/// Cervical mucus as the user describes it. History only: it never changes
/// a prediction.
enum CervicalMucus { dry, sticky, creamy, watery, eggWhite }

/// The signals logged for one day (Phase 25). Sensitive: it lives only in an
/// encrypted Hive box, one record per day, and its values are never logged.
///
/// The adapter is written by hand so that a damaged record reads as invalid
/// instead of throwing while the box opens.
class FertilityLogModel {
  /// Readable range of a thermometer reading. A typing guard, not a judgement
  /// of the value.
  static const double minTemperatureC = 35;
  static const double maxTemperatureC = 39;

  /// Marks a record whose date could not be read; see [isValid].
  static final DateTime _invalidDate = DateTime.utc(0);

  /// Local calendar day, no time.
  final DateTime date;
  final LhResult? lh;
  final CervicalMucus? mucus;
  final double? temperatureC;

  /// "Ngày gần gũi". Optional and hidden until the user enables it.
  final bool intimacy;
  final DateTime updatedAt;

  FertilityLogModel({
    required DateTime date,
    this.lh,
    this.mucus,
    this.temperatureC,
    this.intimacy = false,
    required this.updatedAt,
  }) : date = DateTime(date.year, date.month, date.day);

  FertilityLogModel._invalid(this.updatedAt)
    : date = _invalidDate,
      lh = null,
      mucus = null,
      temperatureC = null,
      intimacy = false;

  /// False for a record whose date could not be read.
  bool get isValid => date.year > 0;

  /// Nothing logged: the day has no record at all.
  bool get isEmpty =>
      lh == null && mucus == null && temperatureC == null && !intimacy;

  /// LH, mucus or temperature was logged.
  bool get hasHealthSignal =>
      lh != null || mucus != null || temperatureC != null;

  /// Whether the day shows anywhere; a day that only holds the hidden
  /// intimacy mark must not.
  bool isVisible({required bool showIntimacy}) =>
      hasHealthSignal || (showIntimacy && intimacy);

  /// Box key: at most one record per calendar day.
  static String dayKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year.toString().padLeft(4, '0')}-$month-$date';
  }

  static bool isPlausibleTemperature(double value) =>
      value.isFinite && value >= minTemperatureC && value <= maxTemperatureC;

  /// Reads "36,5" or "36.5"; null when it is not a plausible reading.
  static double? parseTemperature(String input) {
    final value = double.tryParse(input.trim().replaceAll(',', '.'));
    if (value == null || !isPlausibleTemperature(value)) return null;
    return (value * 100).roundToDouble() / 100;
  }

  /// "36,5" with the Vietnamese decimal comma.
  static String formatTemperature(double value) {
    final fixed = value.toStringAsFixed(2);
    final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return trimmed.replaceAll('.', ',');
  }

  /// Days with a positive or peak LH test, oldest first.
  static List<DateTime> positiveLhDays(Iterable<FertilityLogModel> logs) {
    return [
      for (final log in logs)
        if (log.isValid && (log.lh?.isPositive ?? false)) log.date,
    ]..sort();
  }

  /// Builds a record from stored fields. Anything of the wrong type or out of
  /// range becomes empty; a missing date makes the record invalid.
  factory FertilityLogModel.fromFields(Map<int, dynamic> fields) {
    final date = fields[0];
    final updatedAt = fields[5];
    final stamp = updatedAt is DateTime ? updatedAt : _invalidDate;
    if (date is! DateTime) return FertilityLogModel._invalid(stamp);
    final temperature = fields[3];
    return FertilityLogModel(
      date: date,
      lh: LhResult.values.asNameMap()[fields[1]],
      mucus: CervicalMucus.values.asNameMap()[fields[2]],
      temperatureC: temperature is double && isPlausibleTemperature(temperature)
          ? temperature
          : null,
      intimacy: fields[4] == true,
      updatedAt: stamp,
    );
  }
}

/// Hive adapter of [FertilityLogModel]. Enums are stored by name, so adding
/// a value later cannot change the meaning of stored records.
class FertilityLogModelAdapter extends TypeAdapter<FertilityLogModel> {
  @override
  final int typeId = 6;

  @override
  FertilityLogModel read(BinaryReader reader) {
    try {
      final numOfFields = reader.readByte();
      final fields = <int, dynamic>{
        for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
      };
      return FertilityLogModel.fromFields(fields);
    } catch (_) {
      return FertilityLogModel.fromFields(const {});
    }
  }

  @override
  void write(BinaryWriter writer, FertilityLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.lh?.name)
      ..writeByte(2)
      ..write(obj.mucus?.name)
      ..writeByte(3)
      ..write(obj.temperatureC)
      ..writeByte(4)
      ..write(obj.intimacy)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}
