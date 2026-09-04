// lib/core/extensions/string_extensions.dart
//
// Extension methods on String and String? for common operations.
// No imports from engine/, modules/, or data/.
//
// FIX — added `avatarInitials` getter:
//   Returns initials suitable for CircleAvatar display, falling back to '?'
//   when the name is empty or unknown. This eliminates the _initials(String name)
//   helper that was copy-pasted verbatim into 6+ files across the project:
//     - lib/modules/agreements/screens/marketplace_screen.dart
//     - lib/modules/dashboard/screens/client_dashboard_screen.dart
//     - lib/modules/team/registry/member_card.dart
//     - lib/modules/team/screens/network_screen.dart
//     - lib/modules/team/screens/partner_services_screen.dart
//     - lib/modules/discover/screens/discover_screen.dart (formerly
//       client_network_screen.dart, merged in later)
//
//   Migration: in every file above, delete the private `_initials` function
//   and replace every call `_initials(name)` with `name.avatarInitials`.
//   Then add this import if not already present:
//   import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';

extension StringExtensions on String {
  // ── Case ──────────────────────────────────────────────────────────────────────

  /// Capitalises the first letter, lowercases the rest.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalises the first letter of every word.
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize())
        .join(' ');
  }

  // ── Validation ────────────────────────────────────────────────────────────────

  /// True if this string is a valid email address format.
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// True if this string is a valid URL starting with http:// or https://.
  bool get isValidUrl {
    return RegExp(r'^https?://[^\s/$.?#].[^\s]*$').hasMatch(this);
  }

  /// True if this string matches a basic phone number format.
  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s\-()\u00B7]{7,15}$').hasMatch(this);
  }

  // ── Truncation ────────────────────────────────────────────────────────────────

  /// Truncates to [maxLength] characters, appending [ellipsis] if truncated.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  // ── Initials ──────────────────────────────────────────────────────────────────

  /// Returns initials from a full name string.
  /// 'John Smith' → 'JS', 'Alice' → 'A', '' → ''.
  ///
  /// For avatar display where a visible fallback is needed, use
  /// [avatarInitials] instead (returns '?' rather than '').
  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  /// Initials suitable for a [CircleAvatar] label.
  ///
  /// Same logic as [initials] but returns '?' when the name is empty,
  /// null-ish, or produces no letters — so the avatar always shows something.
  ///
  /// Examples:
  ///   'John Smith'.avatarInitials  → 'JS'
  ///   'Alice'.avatarInitials       → 'A'
  ///   ''.avatarInitials            → '?'
  ///   '   '.avatarInitials         → '?'
  ///
  /// Migration note — replaces this pattern that was copy-pasted in 6+ files:
  ///   String _initials(String name) {
  ///     final parts = name.trim().split(RegExp(r'\s+'));
  ///     if (parts.isEmpty || parts.first.isEmpty) return '?';
  ///     if (parts.length == 1) return parts.first[0].toUpperCase();
  ///     return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  ///   }
  String get avatarInitials {
    final result = initials;
    return result.isEmpty ? '?' : result;
  }

  // ── Whitespace ────────────────────────────────────────────────────────────────

  /// Removes all whitespace characters.
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Converts snake_case or kebab-case to Title Case.
  /// 'hello_world' → 'Hello World', 'foo-bar' → 'Foo Bar'.
  String toReadableLabel() {
    return replaceAll(RegExp(r'[_\-]'), ' ').toTitleCase();
  }
}

extension NullableStringExtensions on String? {
  /// Returns true if this string is null, empty, or whitespace only.
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  /// Returns [fallback] if this string is null or empty, otherwise returns this.
  String orElse(String fallback) =>
      (this == null || this!.isEmpty) ? fallback : this!;

  /// Convenience: avatar initials with null safety.
  /// null.avatarInitialsOrFallback → '?'
  String get avatarInitials => this?.avatarInitials ?? '?';
}
