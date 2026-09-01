// lib/engine/widgets/field_renderer_basic.dart
//
// The simple, single-value field widgets used by FieldRenderer: text,
// textarea, number, currency, dropdown, boolean. Split out of
// field_renderer.dart (which had grown to 780 lines) — these six were
// private classes, now public so field_renderer.dart's dispatch switch
// can still reach them from this new file.
//
// See field_renderer.dart for FieldRenderer itself and the full list of
// supported field types.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/widgets/field_renderer_validators.dart';

class SingleLineTextField extends StatelessWidget {
  const SingleLineTextField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.autovalidateMode,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final IconData? prefixIcon;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: field.label,
      label: field.label,
      initialValue: value as String? ?? '',
      onChanged: onChanged,
      prefixIcon: prefixIcon,
      textCapitalization: TextCapitalization.sentences,
      autovalidateMode: autovalidateMode,
      validator: (v) => requiredFieldValidator(field, v),
    );
  }
}

class TextareaField extends StatelessWidget {
  const TextareaField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.autovalidateMode,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: field.label,
      label: field.label,
      initialValue: value as String? ?? '',
      onChanged: onChanged,
      maxLines: 6,
      minLines: 3,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      autovalidateMode: autovalidateMode,
      validator: (v) => requiredFieldValidator(field, v),
    );
  }
}

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.autovalidateMode,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: field.label,
      label: field.label,
      initialValue: value?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) {
        final parsed = num.tryParse(v);
        onChanged(parsed ?? v);
      },
      autovalidateMode: autovalidateMode,
      validator: (v) {
        if (field.required && (v == null || v.trim().isEmpty)) {
          return '${field.label} is required';
        }
        if (v != null && v.isNotEmpty && num.tryParse(v) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }
}

class CurrencyField extends StatelessWidget {
  const CurrencyField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.currencySymbol,
    this.autovalidateMode,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String currencySymbol;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: '0.00',
      label: '${field.label} ($currencySymbol)',
      initialValue: value?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        onChanged(parsed ?? v);
      },
      autovalidateMode: autovalidateMode,
      validator: (v) {
        if (field.required && (v == null || v.trim().isEmpty)) {
          return '${field.label} is required';
        }
        if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
          return 'Enter a valid amount';
        }
        return null;
      },
    );
  }
}

class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = field.options ?? [];
    final currentValue = value as String?;

    return DropdownButtonFormField<String>(
      initialValue: (currentValue != null && options.contains(currentValue))
          ? currentValue
          : null,
      decoration: InputDecoration(labelText: field.label),
      hint: Text(field.label),
      items: options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
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

class BooleanField extends StatelessWidget {
  const BooleanField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final checked = (value as bool?) ?? false;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(field.label, style: AppTextStyles.titleSmall),
      value: checked,
      onChanged: onChanged,
    );
  }
}

