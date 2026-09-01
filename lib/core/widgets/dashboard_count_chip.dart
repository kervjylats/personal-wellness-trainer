import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

/// A small "big number + label" stat used across dashboard slot widgets
/// (activity, agreements, team, …) — e.g. "12 / Active".
class DashboardCountChip extends StatelessWidget {
  const DashboardCountChip({
    super.key,
    required this.count,
    required this.label,
    this.color,
  });

  final int count;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: AppTextStyles.titleLarge.copyWith(
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey600),
        ),
      ],
    );
  }
}
