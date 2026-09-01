// lib/modules/reviews/screens/review_list_screen.dart
//
// Role-aware reviews list screen.
// Owner: sees all reviews, can verify/delete. Staff: sees reviews about them.
// Client: sees their own reviews.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/review_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/reviews/providers/reviews_notifier.dart';

class ReviewListScreen extends ConsumerWidget {
  const ReviewListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsNotifierProvider);
    final authState    = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('reviews');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reviewsNotifierProvider),
        child: reviewsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $moduleLabel.',
            onRetry: () => ref.invalidate(reviewsNotifierProvider),
          ),
          data: (reviews) => reviews.isEmpty
              ? AppEmptyState(
                  icon: Icons.star_outline,
                  headline: 'No $moduleLabel yet',
                  subtext: '$moduleLabel will appear here.',
                )
              : _ReviewList(reviews: reviews, role: role, ref: ref),
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.reviews,
    required this.role,
    required this.ref,
  });
  final List<ReviewModel> reviews;
  final AppRole           role;
  final WidgetRef         ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<ReviewModel>(
      items: reviews,
      itemBuilder: (context, index, review) =>
          _ReviewCard(review: review, role: role, ref: ref),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.role,
    required this.ref,
  });
  final ReviewModel review;
  final AppRole     role;
  final WidgetRef   ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StarRow(rating: review.rating),
                const SizedBox(width: AppSpacing.sm),
                if (review.isVerified)
                  const Icon(Icons.verified, size: 16, color: AppColors.success),
                const Spacer(),
                if (role.isOwner)
                  _OwnerActions(review: review, ref: ref),
              ],
            ),
            if (review.comment != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(review.comment!, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              review.createdAt.toLocal().toString().split(' ').first,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: i < rating ? AppColors.warning : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({required this.review, required this.ref});
  final ReviewModel review;
  final WidgetRef   ref;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (action) {
        if (action == 'verify') {
          ref.read(reviewsNotifierProvider.notifier).setVerified(review.id, isVerified: true);
        } else if (action == 'delete') {
          ref.read(reviewsNotifierProvider.notifier).delete(review.id);
        }
      },
      itemBuilder: (_) => [
        if (!review.isVerified)
          const PopupMenuItem(
            value: 'verify',
            child: Text('Verify'),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
        ),
      ],
    );
  }
}
