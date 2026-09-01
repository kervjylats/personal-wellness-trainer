// lib/core/utils/formatters.dart
//
// Display formatting utilities for App Engine.
// These are pure functions — no Flutter imports needed, no state.
//
// Currency formatting always requires the currency symbol as a parameter
// since it comes from industry_config.json at runtime.
// Core files cannot import from engine/ — the caller provides the symbol.

abstract final class AppFormatters {
  // ── Currency ──────────────────────────────────────────────────────────────────
  /// Formats a currency amount with thousands separator and 2 decimal places.
  /// Example: currency(1234.5, '\$') → '\$1,234.50'
  /// Example: currency(-50.0, '€') → '-€50.00'
  static String currency(double amount, String currencySymbol) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Add thousands separators.
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    final result = '$currencySymbol$buffer.$decPart';
    return isNegative ? '-$result' : result;
  }

  /// Compact currency format for dashboard cards and summaries.
  /// Example: currencyCompact(1234567, '\$') → '\$1.2M'
  /// Example: currencyCompact(2500, '\$')    → '\$2.5K'
  static String currencyCompact(double amount, String currencySymbol) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    String result;

    if (absAmount >= 1000000) {
      result = '$currencySymbol${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      result = '$currencySymbol${(absAmount / 1000).toStringAsFixed(1)}K';
    } else {
      result = currency(absAmount, currencySymbol);
      return isNegative ? '-$result' : result;
    }

    return isNegative ? '-$result' : result;
  }

  // ── Dates ─────────────────────────────────────────────────────────────────────
  /// Formats as DD/MM/YYYY.
  static String date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formats as H:MM AM/PM.
  static String time(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  /// Formats as 'DD/MM/YYYY H:MM AM/PM'.
  static String dateTime(DateTime dt) => '${date(dt)} ${time(dt)}';

  /// Formats duration in minutes to a readable string.
  /// Examples: 30 → '30min', 90 → '1h 30min', 60 → '1h'
  static String duration(int minutes) {
    if (minutes <= 0) return '0min';
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  // ── Phone ─────────────────────────────────────────────────────────────────────
  /// Formats a 10-digit US phone number into area-code notation.
  /// Example: phone('5551234567') → '(555) 123-4567'
  /// Returns the original string unchanged if it cannot be formatted.
  static String phone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) '
          '${digits.substring(3, 6)}-'
          '${digits.substring(6)}';
    }
    return rawPhone;
  }

  // ── Numbers ───────────────────────────────────────────────────────────────────
  /// Formats a percentage value.
  /// Example: percentage(12.5) → '12.5%'
  static String percentage(double value, {int decimalPlaces = 1}) {
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }

  /// Formats a large count compactly.
  /// Example: count(1234) → '1.2K', count(42) → '42'
  static String count(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  // ── Names ────────────────────────────────────────────────────────────────────
  /// Returns initials from a full name string.
  /// 'John Smith' → 'JS', 'Alice' → 'A', '' → '?'
  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || (words.length == 1 && words[0].isEmpty)) return '?';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
