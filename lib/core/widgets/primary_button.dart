// lib/core/widgets/primary_button.dart
//
// The ONE standard button widget for App Engine.
// Every button in every screen uses this widget. No raw ElevatedButton or
// FilledButton calls in screen or module files — always PrimaryButton.
//
// Variants:
//   - Default   → FilledButton  (primary action, e.g. Sign In, Save)
//   - isOutlined → OutlinedButton (secondary action)
//   - isDestructive → red filled  (destructive actions, e.g. Delete)
//
// Features:
//   - isLoading replaces label with spinner, disables onPressed
//   - icon adds a leading icon before the label
//   - fullWidth (default true) stretches to fill available width

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.isDestructive = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;
  final bool isDestructive;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: isOutlined
          ? _buildOutlinedButton(context, effectiveOnPressed)
          : _buildFilledButton(context, effectiveOnPressed),
    );
  }

  Widget _buildFilledButton(
    BuildContext context,
    VoidCallback? effectiveOnPressed,
  ) {
    return FilledButton(
      onPressed: effectiveOnPressed,
      style: isDestructive
          ? FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            )
          : null,
      child: _buildChild(context, isOnDark: true),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context,
    VoidCallback? effectiveOnPressed,
  ) {
    return OutlinedButton(
      onPressed: effectiveOnPressed,
      style: isDestructive
          ? OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            )
          : null,
      child: _buildChild(context, isOnDark: false),
    );
  }

  Widget _buildChild(BuildContext context, {required bool isOnDark}) {
    if (isLoading) {
      return SizedBox(
        width: AppSpacing.buttonLoaderSize,
        height: AppSpacing.buttonLoaderSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          // Filled button: white spinner. Outlined: theme primary.
          color: isOnDark ? AppColors.textOnPrimary : null,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconSize),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.buttonText),
        ],
      );
    }

    return Text(label, style: AppTextStyles.buttonText);
  }
}
