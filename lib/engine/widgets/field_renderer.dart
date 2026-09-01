// lib/engine/widgets/field_renderer.dart
//
// FieldRenderer is the single most important widget in App Engine.
// It reads an ActivityField config object and renders the correct input widget.
//
// If FieldRenderer is wrong, every form in every industry template is wrong.
//
// Supported field types (from Blueprint §3 and ActivityField docs):
//   text          → single-line AppTextField
//   textarea      → multi-line AppTextField (minLines: 3, maxLines: 6)
//   number        → AppTextField with numeric keyboard
//   currency      → AppTextField with currency symbol prefix, decimal keyboard
//   dropdown      → DropdownButtonFormField from ActivityField.options
//   date          → read-only AppTextField, taps open DatePicker
//   time          → read-only AppTextField, taps open TimePicker
//   datetime      → read-only AppTextField, taps open Date then Time picker
//   duration      → hours + minutes row
//   boolean       → SwitchListTile
//   staff_picker  → DropdownButtonFormField from provided staffOptions list
//   client_picker → DropdownButtonFormField from provided clientOptions list
//   location      → AppTextField (map integration in a future phase)
//   image_upload  → disabled placeholder (Phase 6)
//
// Design rules:
//   - FieldRenderer has no state of its own. It is stateless.
//   - All state lives in the parent (Map<String, dynamic> values + onChanged).
//   - For date/time/datetime/duration, the parent passes a TextEditingController
//     via the optional [controller] parameter. If none is passed, the widget
//     manages a controller internally via a StatefulWidget wrapper.
//   - No imports from modules/. FieldRenderer is in engine/ and must be
//     importable by any module without circular dependencies.
//   - staffOptions and clientOptions are passed in — FieldRenderer never
//     fetches data itself.
//
// This file used to hold every field-type widget directly (780 lines).
// The simple single-value widgets (text/textarea/number/currency/dropdown/
// boolean) moved to field_renderer_basic.dart, and the date/time-family
// widgets (date/time/datetime/duration) moved to field_renderer_datetime.dart
// — see those files for the "FIX — mounted checks" history on the latter.
// Only the picker/image/unknown fallback widgets stay here alongside
// FieldRenderer itself, since those three are the smallest and least
// related to either group.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/widgets/field_renderer_basic.dart';
import 'package:personal_wellness_trainer/engine/widgets/field_renderer_datetime.dart';

// ── Public API ────────────────────────────────────────────────────────────────

/// A single selectable option for staff_picker / client_picker dropdowns.
class PickerOption {
  const PickerOption({required this.id, required this.label});
  final String id;
  final String label;
}

// ── FieldRenderer ─────────────────────────────────────────────────────────────

/// Renders the correct form input widget for an [ActivityField] config entry.
///
/// Parameters:
///   [field]         — the config field definition (name, type, label, required)
///   [value]         — current value from the form state Map
///   [onChanged]     — called whenever the value changes
///   [currencySymbol] — required for currency fields; from configProvider
///   [staffOptions]  — required for staff_picker fields
///   [clientOptions] — required for client_picker fields
///   [autovalidateMode] — passed through to inner form fields
class FieldRenderer extends StatelessWidget {
  const FieldRenderer({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.currencySymbol = r'$',
    this.staffOptions = const [],
    this.clientOptions = const [],
    this.autovalidateMode,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String currencySymbol;
  final List<PickerOption> staffOptions;
  final List<PickerOption> clientOptions;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return switch (field.type) {
      'text'          => SingleLineTextField(field: field, value: value, onChanged: onChanged, autovalidateMode: autovalidateMode),
      'textarea'      => TextareaField(field: field, value: value, onChanged: onChanged, autovalidateMode: autovalidateMode),
      'number'        => NumberField(field: field, value: value, onChanged: onChanged, autovalidateMode: autovalidateMode),
      'currency'      => CurrencyField(field: field, value: value, onChanged: onChanged, currencySymbol: currencySymbol, autovalidateMode: autovalidateMode),
      'dropdown'      => DropdownField(field: field, value: value, onChanged: onChanged),
      'date'          => DateField(field: field, value: value, onChanged: onChanged),
      'time'          => TimeField(field: field, value: value, onChanged: onChanged),
      'datetime'      => DateTimeField(field: field, value: value, onChanged: onChanged),
      'duration'      => DurationField(field: field, value: value, onChanged: onChanged),
      'boolean'       => BooleanField(field: field, value: value, onChanged: onChanged),
      'staff_picker'  => _PickerField(field: field, value: value, onChanged: onChanged, options: staffOptions),
      'client_picker' => _PickerField(field: field, value: value, onChanged: onChanged, options: clientOptions),
      'location'      => SingleLineTextField(field: field, value: value, onChanged: onChanged, prefixIcon: Icons.location_on_outlined, autovalidateMode: autovalidateMode),
      'image_upload'  => _ImageUploadPlaceholder(field: field),
      _               => _UnknownField(type: field.type),
    };
  }
}

// ── Internal Field Widgets (picker / image / unknown fallback) ───────────────

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final List<PickerOption> options;

  @override
  Widget build(BuildContext context) {
    final currentId = value as String?;
    final validId = options.any((o) => o.id == currentId) ? currentId : null;

    if (options.isEmpty) {
      return AppTextField(
        hint: 'No options available',
        label: field.label,
        enabled: false,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: validId,
      decoration: InputDecoration(labelText: field.label),
      hint: Text('Select ${field.label}'),
      items: options
          .map((opt) => DropdownMenuItem(
                value: opt.id,
                child: Text(opt.label),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) {
        if (field.required && (v == null || v.isEmpty)) {
          return '${field.label} is required';
        }
        return null;
      },
    );
  }
}

class _ImageUploadPlaceholder extends StatelessWidget {
  const _ImageUploadPlaceholder({required this.field});
  final ActivityField field;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label, style: AppTextStyles.titleSmall),
                const Text(
                  'Image upload available in a future phase.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnknownField extends StatelessWidget {
  const _UnknownField({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      ),
      child: Text(
        'Unknown field type: "$type"',
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

