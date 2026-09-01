// lib/modules/activity/registry/booking_confirmation_card.dart
//
// A shareable card widget showing a just-confirmed activity.
// Registered in WidgetRegistry as 'activity.BookingConfirmationCard'.
// Used by Dashboard (Phase 6) and Notifications (Phase 5).
//
// Data keys (from Map<String, dynamic> data):
//   'title'      → String  — the primary field value (e.g. service type)
//   'status'     → String  — the activity status
//   'date_label' → String  — formatted date/time string
//   'amount'     → String? — formatted amount string, optional

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class BookingConfirmationCard extends StatelessWidget {
  const BookingConfirmationCard({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final title = data?['title'] as String? ?? 'Activity';
    final dateLabel = data?['date_label'] as String? ?? '';
    final amount = data?['amount'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: AppSpacing.iconSizeSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateLabel.isNotEmpty)
                    Text(dateLabel, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (amount != null)
              Text(amount, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }
}
