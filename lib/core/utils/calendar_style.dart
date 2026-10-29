import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// `table_calendar` styles from the current [ColorScheme]. The package
/// defaults use fixed greys and indigo, which are unreadable in dark mode.
class AppCalendarStyle {
  const AppCalendarStyle._();

  static CalendarStyle calendar(
    BuildContext context, {
    int markersMaxCount = 4,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final body = TextStyle(color: scheme.onSurface);
    return CalendarStyle(
      markersMaxCount: markersMaxCount,
      markerDecoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
      ),
      defaultTextStyle: body,
      weekendTextStyle: body,
      holidayTextStyle: body,
      outsideTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      disabledTextStyle: TextStyle(
        color: scheme.onSurface.withValues(alpha: 0.38),
      ),
      todayDecoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      ),
      selectedDecoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
      ),
      selectedTextStyle: TextStyle(
        color: scheme.onPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static DaysOfWeekStyle daysOfWeek(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(color: scheme.onSurfaceVariant);
    return DaysOfWeekStyle(weekdayStyle: style, weekendStyle: style);
  }

  static HeaderStyle header(
    BuildContext context, {
    bool formatButtonVisible = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return HeaderStyle(
      formatButtonVisible: formatButtonVisible,
      titleCentered: true,
      formatButtonShowsNext: false,
      titleTextStyle:
          Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurface) ??
          TextStyle(color: scheme.onSurface),
      leftChevronIcon: Icon(Icons.chevron_left, color: scheme.onSurface),
      rightChevronIcon: Icon(Icons.chevron_right, color: scheme.onSurface),
      formatButtonDecoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      formatButtonTextStyle: TextStyle(color: scheme.primary),
    );
  }
}
