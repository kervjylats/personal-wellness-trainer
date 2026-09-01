// lib/modules/finance/widgets/finance_widgets.dart
//
// Shared widgets used across all finance screens (owner, partner, client).
// Extracted to eliminate identical private widget classes that were duplicated
// in owner_finance_screen.dart, client_payments_screen.dart, and
// partner_finance_screen.dart.
//
// Widgets:
//   FinanceStatusBadge  — coloured status label (pending/completed/paid/etc.)
//   FinanceEmptyState   — centred message for empty list sections

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

/// Coloured text badge for a transaction / commission status value.
/// Replaces the private `_StatusBadge` in owner_finance_screen and
/// `_StatusChip` in client_payments_screen — they were 97% identical.
class FinanceStatusBadge extends StatelessWidget {
  const FinanceStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' || 'paid' => AppColors.success,
      'pending'             => AppColors.warning,
      'refunded'            => AppColors.grey600,
      _                     => AppColors.error,
    };
    return Text(
      status.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(color: color),
    );
  }
}

/// Centred empty-state message for finance screen sections.
/// Replaces the identical private `_EmptyState` in owner_finance_screen
/// and partner_finance_screen.
class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(child: Text(message, style: AppTextStyles.bodyMedium)),
    );
  }
}
