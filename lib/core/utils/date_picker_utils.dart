import 'package:flutter/material.dart';

/// Helpers that keep `showDatePicker` arguments consistent.
///
/// Flutter asserts `firstDate <= initialDate <= lastDate`; editing an old
/// record (e.g. a past appointment) used to violate this and crash.
class DatePickerUtils {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Clamps [initial] into the inclusive range [first]..[last] (date only).
  static DateTime clampInitial(
    DateTime initial,
    DateTime first,
    DateTime last,
  ) {
    final i = dateOnly(initial);
    final f = dateOnly(first);
    final l = dateOnly(last);
    if (i.isBefore(f)) return f;
    if (i.isAfter(l)) return l;
    return i;
  }

  /// Opens a date picker whose range is widened to include [initialDate]
  /// when [includeInitial] is true (useful when editing an existing record),
  /// otherwise the initial date is clamped into the range.
  static Future<DateTime?> pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    bool includeInitial = false,
  }) {
    var first = dateOnly(firstDate);
    var last = dateOnly(lastDate);
    if (last.isBefore(first)) last = first;
    final initial = dateOnly(initialDate);
    if (includeInitial) {
      if (initial.isBefore(first)) first = initial;
      if (initial.isAfter(last)) last = initial;
    }
    return showDatePicker(
      context: context,
      initialDate: clampInitial(initial, first, last),
      firstDate: first,
      lastDate: last,
    );
  }
}
