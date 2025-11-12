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
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
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
    return '$weeks weeks${days > 0 ? ' $days days' : ''}';
  }

  static String formatDaysRemaining(int days) {
    if (days < 0) return 'Overdue by ${days.abs()} days';
    if (days == 0) return 'Due today!';
    if (days == 1) return '1 day remaining';
    if (days < 7) return '$days days remaining';

    final weeks = (days / 7).floor();
    final remainingDays = days % 7;

    if (remainingDays == 0) {
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} remaining';
    }
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} $remainingDays ${remainingDays == 1 ? 'day' : 'days'} remaining';
  }
}
