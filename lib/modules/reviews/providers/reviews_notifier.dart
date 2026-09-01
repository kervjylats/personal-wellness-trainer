// lib/modules/reviews/providers/reviews_notifier.dart
//
// AsyncNotifier managing the reviews list for the current business.
// Build returns [] when the reviews module is not included in config.
// In Phase 10, replace MockReviewsSource() with SupabaseReviewsSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/review_model.dart';
import 'package:personal_wellness_trainer/data/repositories/reviews_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_reviews_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/modules/reviews/providers/reviews_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final reviewsNotifierProvider =
    AsyncNotifierProvider<ReviewsNotifier, List<ReviewModel>>(
  ReviewsNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ReviewsNotifier extends AsyncNotifier<List<ReviewModel>> {
  static const String _tag = 'ReviewsNotifier';
  late ReviewsRepository _repo;

  @override
  Future<List<ReviewModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('reviews')) {
      AppLogger.debug('ReviewsNotifier: module not included', tag: _tag);
      return [];
    }

    AppLogger.debug(
      'ReviewsNotifier: loading for business ${authState.profile.businessId}',
      tag: _tag,
    );

    return _repo.getReviews(authState.profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new review. Returns the created ReviewModel or null on error.
  Future<ReviewModel?> create({
    required String targetUserId,
    required int rating,
    String? comment,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(reviewsActionErrorProvider.notifier).state = null;

    try {
      final review = await _repo.createReview(
        businessId: authState.profile.businessId,
        authorUserId: authState.profile.userId,
        targetUserId: targetUserId,
        rating: rating,
        comment: comment,
      );
      ref.invalidateSelf();
      AppLogger.info('ReviewsNotifier: created ${review.id}', tag: _tag);
      return review;
    } catch (e, st) {
      AppLogger.error('ReviewsNotifier: create failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(reviewsActionErrorProvider.notifier).state =
          'Could not save review. Please try again.';
      return null;
    }
  }

  /// Toggles verified status. Owner only.
  Future<bool> setVerified(String reviewId, {required bool isVerified}) async {
    ref.read(reviewsActionErrorProvider.notifier).state = null;
    try {
      await _repo.setVerified(reviewId, isVerified: isVerified);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('ReviewsNotifier: setVerified failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(reviewsActionErrorProvider.notifier).state =
          'Could not update review. Please try again.';
      return false;
    }
  }

  /// Deletes a review. Returns true on success.
  Future<bool> delete(String reviewId) async {
    ref.read(reviewsActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteReview(reviewId);
      ref.invalidateSelf();
      AppLogger.info('ReviewsNotifier: deleted $reviewId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('ReviewsNotifier: delete failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(reviewsActionErrorProvider.notifier).state =
          'Could not delete review. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  ReviewsRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockReviewsSource();
    throw UnimplementedError(
        'SupabaseReviewsSource not yet wired (Phase 10 only).');
  }
}

