// lib/modules/activity/registry/upcoming_session_card.dart
//
// A shareable card widget showing the next upcoming activity.
// Registered in WidgetRegistry as 'activity.UpcomingSessionCard'.
// Used by Dashboard (Phase 6) for all roles.
//
// Data keys (from Map<String, dynamic> data):
//   'title'      → String  — the primary field value (e.g. service type)
//   'date_label' → String  — formatted upcoming date/time string
//   'status'     → String  — the activity status
//   'empty_message' → String? — shown if no upcoming activity exists

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class UpcomingSessionCard extends StatelessWidget {
  const UpcomingSessionCard({super.key, this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final title = data?['title'] as String? ?? '';
    final dateLabel = data?['date_label'] as String? ?? '';
    final emptyMessage =
        data?['empty_message'] as String? ?? 'No upcoming activities.';

    if (title.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: AppColors.grey400,
                size: AppSpacing.iconSize,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(emptyMessage, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              child: Icon(
                Icons.event_outlined,
                color: Theme.of(context).colorScheme.primary,
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
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
