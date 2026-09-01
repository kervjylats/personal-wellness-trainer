// lib/core/utils/validators.dart
//
// Form validation functions used across all screens and modules.
// Each function follows Flutter's FormFieldValidator<String> signature:
// returns null on valid, or a user-facing error string on invalid.
//
// All validators handle null safely — use directly as:
//   validator: AppValidators.email

import 'package:personal_wellness_trainer/core/constants/app_constants.dart';

abstract final class AppValidators {
  // ── Authentication ────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    if (value.trim().length > AppConstants.maxEmailLength) {
      return 'Email address is too long';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least '
          '${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  // ── General ───────────────────────────────────────────────────────────────────
  /// Validates that the field is not null or empty.
  static String? Function(String?) required({String fieldName = 'This field'}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  /// Validates optional phone number format. Returns null if empty (field is optional).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^\+?[\d\s\-()\u00B7]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates optional URL format. Returns null if empty (field is optional).
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL (must start with http:// or https://)';
    }
    return null;
  }

  static String? Function(String?) minLength(
    int min, {
    String? fieldName,
  }) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '${fieldName ?? 'This field'} is required';
      }
      if (value.length < min) {
        return '${fieldName ?? 'This field'} must be at least $min characters';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(
    int max, {
    String? fieldName,
  }) {
    return (String? value) {
      if (value != null && value.length > max) {
        return '${fieldName ?? 'This field'} must be $max characters or fewer';
      }
      return null;
    };
  }

  // ── Numeric ───────────────────────────────────────────────────────────────────
  /// Validates that the value is a positive number (> 0).
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }
    if (parsed <= 0) {
      return '${fieldName ?? 'This field'} must be greater than 0';
    }
    return null;
  }

  /// Validates that the value is zero or positive (≥ 0).
  static String? nonNegativeNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }
    if (parsed < 0) {
      return '${fieldName ?? 'This field'} cannot be negative';
    }
    return null;
  }

  /// Validates a percentage value between 0 and 100.
  static String? percentage(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Percentage'} is required';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return '${fieldName ?? 'Percentage'} must be a valid number';
    }
    if (parsed < 0 || parsed > 100) {
      return '${fieldName ?? 'Percentage'} must be between 0 and 100';
    }
    return null;
  }
}
