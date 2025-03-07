// utils/date_utils.dart
import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  static DateTime navigateMonth(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  static DateTime navigateDay(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  static String getDateRangeText({
    required String filter,
    DateTime? selectedDate,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    switch (filter) {
      case 'latest':
        return 'Last 7 Records';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(selectedDate!);
      case 'custom':
        return customStartDate != null && customEndDate != null
            ? '${DateFormat('MMM dd').format(customStartDate)} - ${DateFormat('MMM dd').format(customEndDate)}'
            : 'Select Date Range';
      default:
        return '';
    }
  }
}