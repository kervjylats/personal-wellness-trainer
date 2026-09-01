// lib/modules/activity/widgets/activity_status_badge.dart
//
// Shared status badge widget for the activity module.
// Used by ActivityListScreen and ActivityDetailScreen.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class ActivityStatusBadge extends StatelessWidget {
  const ActivityStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed'   => AppColors.success,
      'in_progress' => AppColors.warning,
      'completed'   => AppColors.grey600,
      'cancelled'   => AppColors.error,
      _             => AppColors.grey400,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
