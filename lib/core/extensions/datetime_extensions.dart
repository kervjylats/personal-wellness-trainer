// lib/core/extensions/datetime_extensions.dart
//
// Extension methods on DateTime for display formatting and date comparison.
// No imports from engine/, modules/, or data/.

extension DateTimeExtensions on DateTime {
  // ── Comparison Helpers ────────────────────────────────────────────────────────
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek.add(const Duration(seconds: 1)));
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  // ── Display Strings ───────────────────────────────────────────────────────────
  /// Returns a human-friendly string: 'Today', 'Yesterday', 'Tomorrow', or
  /// the formatted date for all other values.
  String toDisplayString() {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return toDateString();
  }

  /// Returns DD/MM/YYYY format.
  String toDateString() {
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }

  /// Returns H:MM AM/PM format.
  String toTimeString() {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  /// Returns 'DD/MM/YYYY H:MM AM/PM'.
  String toDateTimeString() => '${toDateString()} ${toTimeString()}';

  /// Returns a relative human-friendly string:
  /// 'Just now', '5m ago', '2h ago', '3d ago', or the date for older values.
  String toRelativeString() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.isNegative) return toDateString();
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return toDateString();
  }

  /// Returns 'Jan 2026', 'Feb 2026', etc.
  String toMonthYear() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[month - 1]} $year';
  }

  /// Returns the full month name.
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  /// Returns the short day name: 'Mon', 'Tue', etc.
  String get shortDayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Returns a copy of this date with only the date part (time zeroed).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns a copy of this date at the start of the day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns a copy of this date at the end of the day (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}
