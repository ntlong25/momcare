import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momcare/core/theme/app_theme.dart';
import 'package:momcare/core/utils/calendar_style.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  Widget calendar() => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => TableCalendar(
          locale: AppCalendarStyle.locale,
          startingDayOfWeek: AppCalendarStyle.startingDayOfWeek,
          availableCalendarFormats: AppCalendarStyle.formats,
          firstDay: DateTime.utc(2026, 1, 1),
          lastDay: DateTime.utc(2026, 12, 31),
          focusedDay: DateTime.utc(2026, 10, 15),
          headerStyle: AppCalendarStyle.header(context),
          daysOfWeekStyle: AppCalendarStyle.daysOfWeek(context),
          calendarStyle: AppCalendarStyle.calendar(context),
        ),
      ),
    ),
  );

  testWidgets('calendar labels are Vietnamese, week starts on Monday', (
    tester,
  ) async {
    await tester.pumpWidget(calendar());
    await tester.pump();

    expect(find.text('Tháng 10, 2026'), findsOneWidget);
    expect(find.text('Tháng'), findsOneWidget);
    expect(find.text('October 2026'), findsNothing);
    expect(find.text('Month'), findsNothing);
    expect(find.text('Sun'), findsNothing);

    expect(find.text('T2'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('T2')).dx,
      lessThan(tester.getTopLeft(find.text('CN')).dx),
    );
  });

  test('every format has a Vietnamese label', () {
    expect(
      AppCalendarStyle.formats.keys.toSet(),
      CalendarFormat.values.toSet(),
    );
  });
}
