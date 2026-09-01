// lib/modules/agreements/registry/commission_card.dart
//
// A card displaying a single commission record.
// Registered into WidgetRegistry as 'agreements.CommissionCard'.
//
// Consumed by:
//   - Finance screen — commission list entries
//   - Partner dashboard (Phase 6) — earnings summary widget
//
// Data keys (all optional — card degrades gracefully if missing):
//   'amount'      double  — commission amount (numeric, pre-formatted)
//   'currency'    String  — currency symbol e.g. '$'
//   'description' String  — human-readable description of what earned this
//   'date'        String  — formatted date string
//   'isPaid'      bool    — whether the commission has been paid out

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class CommissionCard extends StatelessWidget {
  const CommissionCard({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final amount      = data?['amount']      as double? ?? 0.0;
    final currency    = data?['currency']    as String? ?? r'$';
    final description = data?['description'] as String? ?? 'Commission';
    final date        = data?['date']        as String? ?? '';
    final isPaid      = data?['isPaid']      as bool?   ?? false;

    final amountStr = '$currency${amount.toStringAsFixed(2)}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(
                isPaid
                    ? Icons.check_circle_outline
                    : Icons.schedule_outlined,
                size: AppSpacing.iconSize,
                color: isPaid ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description, style: AppTextStyles.bodyMedium),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      date,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.grey600),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountStr, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isPaid ? 'Paid' : 'Pending',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
