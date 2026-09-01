// lib/engine/widgets/field_renderer_validators.dart
//
// Small shared validator used by several field-renderer widgets (text,
// textarea, date, time, datetime, duration). Split into its own file so
// field_renderer.dart, field_renderer_basic.dart, and
// field_renderer_datetime.dart can each import it directly with no
// circular dependency between the three.

import 'package:personal_wellness_trainer/engine/config/industry_config.dart';

/// Returns the required-field error message if [field] is required and
/// [v] is empty, otherwise null.
String? requiredFieldValidator(ActivityField field, String? v) {
  if (!field.required) return null;
  if (v == null || v.trim().isEmpty) return '${field.label} is required';
  return null;
}
