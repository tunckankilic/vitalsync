/// VitalSync — Dart Extension Methods.
///
/// DateTime extensions (format, isToday, isSameDay, startOfWeek, etc.)
/// String extensions (capitalize, isValidEmail)
/// Duration extensions (formatWorkoutTime)
/// int/double extensions (formatWeight, formatReps, formatVolume, etc.)
/// Context extensions (showSnackbar, showBottomSheet)
/// List extensions (safeAverage, groupByDate)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// DATETIME EXTENSIONS

/// Extension methods for [DateTime] to provide convenient date operations.
extension DateTimeX on DateTime {
  /// Formats the date using the specified pattern.
  ///
  /// Common patterns:
  /// - 'yyyy-MM-dd' -> 2024-02-12
  /// - 'MMM d, yyyy' -> Feb 12, 2024
  /// - 'EEEE, MMMM d' -> Monday, February 12
  /// - 'HH:mm' -> 14:30
  String format([String pattern = 'yyyy-MM-dd']) {
    return DateFormat(pattern).format(this);
  }

  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns true if this date is tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Returns true if this date is the same day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns the start of the week (Monday at 00:00:00).
  DateTime get startOfWeek {
    final daysFromMonday = weekday - DateTime.monday;
    return subtract(
      Duration(days: daysFromMonday),
    ).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  }

  /// Returns the end of the week (Sunday at 23:59:59).
  DateTime get endOfWeek {
    final daysUntilSunday = DateTime.sunday - weekday;
    return add(
      Duration(days: daysUntilSunday),
    ).copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  }

  /// Returns the start of the month (1st at 00:00:00).
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Returns the end of the month (last day at 23:59:59).
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Returns the start of the day (00:00:00).
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Returns the end of the day (23:59:59).
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Returns the number of days between this date and [other].
  int daysBetween(DateTime other) {
    final from = DateTime(year, month, day);
    final to = DateTime(other.year, other.month, other.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Returns a human-readable relative time string.
  ///
  /// Examples: 'Today', 'Yesterday', 'Tomorrow', 'Feb 12', '2023'
  String toRelativeString() {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';

    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays < 7) {
      return format('EEEE'); // Day name
    } else if (year == now.year) {
      return format('MMM d'); // Month and day
    } else {
      return format('MMM d, yyyy'); // Full date
    }
  }

  /// Returns a short time string (e.g., '14:30', '2:30 PM').
  String toTimeString([bool use24Hour = true]) {
    return format(use24Hour ? 'HH:mm' : 'h:mm a');
  }
}

// STRING EXTENSIONS

/// Extension methods for [String] to provide convenient string operations.
extension StringX on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: 'hello' -> 'Hello'
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of each word.
  ///
  /// Example: 'hello world' -> 'Hello World'
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Returns true if the string is a valid email address.
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Returns true if the string is empty or contains only whitespace.
  bool get isBlank {
    return trim().isEmpty;
  }

  /// Returns true if the string is not empty and not blank.
  bool get isNotBlank {
    return !isBlank;
  }
}

// DURATION EXTENSIONS

/// Extension methods for [Duration] to provide workout time formatting.
extension DurationX on Duration {
  /// Formats the duration as a workout time string.
  ///
  /// Examples:
  /// - 90 minutes -> '1h 30m'
  /// - 45 minutes -> '45m'
  /// - 3665 seconds -> '1h 1m'
  String formatWorkoutTime() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  /// Formats the duration with seconds precision.
  ///
  /// Examples:
  /// - 90 seconds -> '1:30'
  /// - 3665 seconds -> '1:01:05'
  String formatWithSeconds() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

// INT EXTENSIONS

/// Extension methods for [int] to provide fitness-related formatting.
extension IntX on int {
  /// Formats weight value with unit.
  ///
  /// Example: 100 -> '100 kg' or '100 lbs'
  String formatWeight([String unit = 'kg']) {
    return '$this $unit';
  }

  /// Formats rep count.
  ///
  /// Example: 10 -> '10 reps', 1 -> '1 rep'
  String formatReps() {
    return this == 1 ? '1 rep' : '$this reps';
  }

  /// Formats set count.
  ///
  /// Example: 3 -> '3 sets', 1 -> '1 set'
  String formatSets() {
    return this == 1 ? '1 set' : '$this sets';
  }

  /// Formats as a compact number (e.g., 1000 -> '1k', 1500000 -> '1.5M').
  String toCompactString() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}k';
    }
    return toString();
  }
}

// DOUBLE EXTENSIONS

/// Extension methods for [double] to provide fitness-related formatting.
extension DoubleX on double {
  /// Formats volume with unit.
  ///
  /// Example: 1500.5 -> '1,500.5 kg' or '1.5k kg'
  String formatVolume([String unit = 'kg', bool compact = false]) {
    if (compact && this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}k $unit';
    }
    return '${toStringAsFixed(1)} $unit';
  }

  /// Formats weight value with unit.
  ///
  /// Example: 100.5 -> '100.5 kg'
  String formatWeight([String unit = 'kg']) {
    return '${toStringAsFixed(1)} $unit';
  }

  /// Formats as percentage.
  ///
  /// Example: 0.75 -> '75%', 0.8545 -> '85.5%'
  String formatPercentage({int decimals = 1}) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }

  /// Formats as percentage value (already in percentage form).
  ///
  /// Example: 75.5 -> '75.5%'
  String toPercentageString({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Rounds to the specified number of decimal places.
  double roundToDecimals(int decimals) {
    final factor = decimals == 0 ? 1 : (10 * decimals);
    return (this * factor).round() / factor;
  }
}

// BUILDCONTEXT EXTENSIONS

/// Extension methods for [BuildContext] to provide UI helpers.
extension BuildContextX on BuildContext {
  /// Shows a snackbar with the given message.
  void showSnackbar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Shows a success snackbar.
  void showSuccessSnackbar(String message) {
    showSnackbar(message, backgroundColor: Colors.green.shade700);
  }

  /// Shows an error snackbar.
  void showErrorSnackbar(String message) {
    showSnackbar(
      message,
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 5),
    );
  }

  /// Shows a bottom sheet with the given builder.
  Future<T?> showBottomSheet<T>({
    required Widget Function(BuildContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      builder: builder,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
    );
  }

  /// Returns the current theme data.
  ThemeData get theme => Theme.of(this);

  /// Returns the current text theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns the current color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns the screen size.
  Size get screenSize => MediaQuery.of(this).size;

  /// Returns the screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the screen height.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns true if the screen is in portrait mode.
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  /// Returns true if the screen is in landscape mode.
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
}

/// Extension for datetime formatting with context (localization aware).
extension DateTimeContextX on DateTime {
  /// Returns a localized relative time string (e.g., '5 minutes ago', 'Just now').
  String formatRelative(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      // Future time
      final absDifference = -difference.inMinutes;
      if (absDifference < 60) {
        return 'in $absDifference minutes';
      } else {
        return format('MMM d, h:mm a');
      }
    }

    // Past time
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return format('MMM d');
    }
  }
}

// LIST EXTENSIONS

/// Extension methods for [List] to provide convenient list operations.
extension ListX<T> on List<T> {
  /// Returns the average of numeric values, or 0 if empty.
  double safeAverage() {
    if (isEmpty) return 0.0;

    num sum = 0;
    for (final item in this) {
      if (item is num) {
        sum += item;
      }
    }
    return sum / length;
  }

  /// Groups items by date (requires items to have a DateTime getter).
  Map<DateTime, List<T>> groupByDate(DateTime Function(T) dateGetter) {
    final grouped = <DateTime, List<T>>{};

    for (final item in this) {
      final date = dateGetter(item).startOfDay;
      grouped.putIfAbsent(date, () => []).add(item);
    }

    return grouped;
  }

  /// Returns the first element or null if empty.
  T? get firstOrNull => isEmpty ? null : first;

  /// Returns the last element or null if empty.
  T? get lastOrNull => isEmpty ? null : last;

  /// Returns a chunked list of the specified size.
  List<List<T>> chunked(int size) {
    if (size <= 0) throw ArgumentError('Chunk size must be positive');

    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }
}

/// Extension for lists of numeric values.
extension NumericListX on List<num> {
  /// Returns the sum of all values.
  num get sum {
    if (isEmpty) return 0;
    return reduce((a, b) => a + b);
  }

  /// Returns the average of all values.
  double get average {
    if (isEmpty) return 0.0;
    return sum / length;
  }

  /// Returns the maximum value or null if empty.
  num? get maxOrNull {
    if (isEmpty) return null;
    return reduce((a, b) => a > b ? a : b);
  }

  /// Returns the minimum value or null if empty.
  num? get minOrNull {
    if (isEmpty) return null;
    return reduce((a, b) => a < b ? a : b);
  }
}
