// lib/modules/reviews/registry/reviews_summary_card.dart
//
// Registry widget: shows average rating for a business.
// Registered as 'reviews.SummaryCard' in ReviewsRegistry.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/reviews/providers/reviews_notifier.dart';

class ReviewsSummaryCard extends ConsumerWidget {
  const ReviewsSummaryCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsNotifierProvider);
    return reviewsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  avg.toStringAsFixed(1),
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(${reviews.length})',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
