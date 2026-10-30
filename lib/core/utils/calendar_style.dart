import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_tokens.dart';

/// `table_calendar` styles from the current [ColorScheme]. The package
/// defaults use fixed greys and indigo, which are unreadable in dark mode.
class AppCalendarStyle {
  const AppCalendarStyle._();

  /// Locale of every `TableCalendar` in the app. Its date symbols are loaded
  /// in `main()`.
  static const String locale = 'vi';

  /// Vietnamese calendars start the week on Monday.
  static const StartingDayOfWeek startingDayOfWeek = StartingDayOfWeek.monday;

  /// The package default labels are English ("Month", "2 weeks", "Week").
  static const Map<CalendarFormat, String> formats = {
    CalendarFormat.month: 'Tháng',
    CalendarFormat.twoWeeks: '2 tuần',
    CalendarFormat.week: 'Tuần',
  };

  /// The package default for `TableCalendar.rowHeight` at text scale 1.
  static const double _baseRowHeight = 52;

  /// "T2".."T7", "CN"; intl's "Th 2" touch each other at large text sizes.
  static String weekdayLabel(DateTime date, dynamic _) =>
      date.weekday == DateTime.sunday ? 'CN' : 'T${date.weekday + 1}';

  /// "Tháng 10, 2026"; `yMMMM` in `vi` would give "tháng 10 2026".
  static String headerTitle(DateTime date, dynamic _) =>
      'Tháng ${date.month}, ${date.year}';

  /// `TableCalendar.rowHeight` for the current text scale. Never below the
  /// package default, so a small font keeps the tap targets.
  static double rowHeight(BuildContext context) {
    final body = _weekdayTextStyle(context).fontSize ?? 14;
    final scale = MediaQuery.textScalerOf(context).scale(body) / body;
    return _baseRowHeight * math.max(1, scale);
  }

  /// `TableCalendar.daysOfWeekHeight`: one full scaled line of the weekday
  /// labels. The package default of 16 is fixed and clips them.
  static double daysOfWeekHeight(BuildContext context) {
    final style = _weekdayTextStyle(context);
    final size = MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14);
    return (size * (style.height ?? 1)).ceilToDouble();
  }

  static TextStyle _weekdayTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return theme.textTheme.bodyMedium?.copyWith(color: color) ??
        TextStyle(color: color);
  }

  static TextStyle _titleTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    return theme.textTheme.titleMedium?.copyWith(color: color) ??
        TextStyle(color: color);
  }

  /// `CalendarBuilders.headerTitleBuilder`: keeps the title on one line by
  /// shrinking it when a large font leaves too little room in the header.
  static Widget headerTitleBuilder(BuildContext context, DateTime day) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          headerTitle(day, null),
          style: _titleTextStyle(context),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }

  /// `CalendarBuilders.dowBuilder`: keeps a weekday label on one line in the
  /// narrow columns of a phone at a large font.
  static Widget daysOfWeekBuilder(BuildContext context, DateTime day) {
    return Center(
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            weekdayLabel(day, null),
            style: _weekdayTextStyle(context),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }

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
    final style = _weekdayTextStyle(context);
    return DaysOfWeekStyle(
      weekdayStyle: style,
      weekendStyle: style,
      dowTextFormatter: weekdayLabel,
    );
  }

  static HeaderStyle header(
    BuildContext context, {
    bool formatButtonVisible = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return HeaderStyle(
      formatButtonVisible: formatButtonVisible,
      titleCentered: true,
      titleTextFormatter: headerTitle,
      formatButtonShowsNext: false,
      formatButtonPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      // 48 dp chevrons without the package's extra 8 dp margin, so the title
      // keeps as much room as possible at large fonts.
      leftChevronMargin: EdgeInsets.zero,
      rightChevronMargin: EdgeInsets.zero,
      titleTextStyle: _titleTextStyle(context),
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
