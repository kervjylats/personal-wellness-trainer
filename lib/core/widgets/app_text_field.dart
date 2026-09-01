// lib/core/widgets/app_text_field.dart
//
// The ONE standard text input widget for App Engine.
// Every text form field in every screen uses this widget.
// Styling comes from the InputDecorationTheme set in AppTheme.build().
//
// Usage:
//   AppTextField(
//     hint: 'Enter email',
//     label: 'Email',
//     controller: _emailController,
//     validator: AppValidators.email,
//     keyboardType: TextInputType.emailAddress,
//   )

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.controller,
    this.initialValue,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.focusNode,
    this.autofillHints,
    this.onTap,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
  });

  final String hint;
  final String? label;
  final TextEditingController? controller;

  /// Only used when [controller] is null. Ignored if [controller] is set.
  final String? initialValue;

  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  /// Icon displayed at the start of the field.
  final IconData? prefixIcon;

  /// Widget displayed at the end of the field (e.g. clear button, toggle eye).
  final Widget? suffixIcon;

  final bool enabled;
  final bool readOnly;

  /// Number of lines shown. Overridden to 1 when [obscureText] is true.
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final VoidCallback? onTap;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onTap: onTap,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      // Suppress the built-in character counter unless maxLength is set.
      // When maxLength is set, show the counter (useful for notes / bios).
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Icon(prefixIcon, size: AppSpacing.iconSize),
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(
                minWidth: AppSpacing.inputPrefixMinWidth,
              )
            : null,
        suffixIcon: suffixIcon,
        counterText: maxLength != null ? null : '',
      ),
    );
  }
}
