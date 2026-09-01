// lib/modules/dashboard/widgets/dashboard_card.dart
//
// Shared card skeleton used by all dashboard slot widgets.
// Provides consistent padding, title row, and optional action.
// Slot widgets (revenue_summary_slot, etc.) wrap their content in this.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.onTap,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.iconSize,
                        color: AppColors.grey600),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(title, style: AppTextStyles.titleSmall),
                  ),
                  if (trailing != null) trailing!,
                  if (onTap != null && trailing == null)
                    const Icon(Icons.chevron_right,
                        size: AppSpacing.iconSize,
                        color: AppColors.grey400),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
