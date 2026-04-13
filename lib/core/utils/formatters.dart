// ============================================================
// lib/core/utils/date_utils.dart
// ============================================================
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';


class AppDateUtils {
  AppDateUtils._();

  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime get weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  static DateTime get monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static DateTime startOfWeek(DateTime date) {
    final d = startOfDay(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) =>
      startOfWeek(date).add(const Duration(days: 6, hours: 23, minutes: 59));

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 1)
          .subtract(const Duration(seconds: 1));

  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatDateShort(DateTime date) =>
      DateFormat('dd MMM').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('HH:mm').format(date);

  static String formatDayOfWeek(DateTime date) =>
      DateFormat('EEE').format(date);

  static String formatDayNum(DateTime date) =>
      DateFormat('d').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMM yyyy').format(date);

  static String formatMonth(DateTime date) =>
      DateFormat('MMMM').format(date);

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes < 1) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDateShort(date);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static List<DateTime> daysInRange(DateTime from, DateTime to) {
    final days = <DateTime>[];
    var current = startOfDay(from);
    while (!current.isAfter(startOfDay(to))) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}

// ============================================================
// lib/core/utils/currency_formatter.dart
// ============================================================

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _fullFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _compactFormatter = NumberFormat.compact(locale: 'en_IN');

  static String format(double amount) => _fullFormatter.format(amount);

  static String formatCompact(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String formatWithDecimal(double amount) =>
      NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(amount);

  static String formatDelta(double percent) {
    final sign = percent >= 0 ? '▲' : '▼';
    return '$sign ${percent.abs().toStringAsFixed(1)}%';
  }
}
