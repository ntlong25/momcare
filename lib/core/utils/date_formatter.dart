import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else {
      return formatDate(date);
    }
  }

  static String formatWeekDay(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatPregnancyWeek(int weeks, int days) {
    return '$weeks tuần${days > 0 ? ' $days ngày' : ''}';
  }

  /// Countdown to a calendar day: "Hôm nay", "5 ngày" or, for a day already
  /// gone, "Đã qua 4 ngày". Counts calendar days, so the time of day of
  /// [date] and [now] does not matter.
  /// "a - b", or one date when the range is a single day.
  static String formatDateRange(DateTime start, DateTime end) {
    final first = formatDate(start);
    return start == end ? first : '$first - ${formatDate(end)}';
  }

  static String formatDayCountdown(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    if (days == 0) return 'Hôm nay';
    return days > 0 ? '$days ngày' : 'Đã qua ${-days} ngày';
  }

  static String formatDaysRemaining(int days) {
    if (days < 0) return 'Quá ngày dự sinh ${days.abs()} ngày';
    if (days == 0) return 'Hôm nay là ngày dự sinh';
    if (days == 1) return 'Còn 1 ngày';
    if (days < 7) return 'Còn $days ngày';

    final weeks = (days / 7).floor();
    final remainingDays = days % 7;

    if (remainingDays == 0) {
      return 'Còn $weeks tuần';
    }
    return 'Còn $weeks tuần $remainingDays ngày';
  }
}
