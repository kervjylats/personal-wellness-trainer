// lib/data/repositories/reviews_repository.dart
//
// Abstract interface for all review data operations.
// ReviewsNotifier talks ONLY to this interface.
// Mock: MockReviewsSource (Phases 1–9). Real: SupabaseReviewsSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/review_model.dart';

abstract class ReviewsRepository {
  /// Returns all reviews for a business, newest first.
  Future<List<ReviewModel>> getReviews(String businessId);

  /// Returns reviews where targetUserId matches — for a staff member's profile.
  Future<List<ReviewModel>> getReviewsForTarget(
    String businessId,
    String targetUserId,
  );

  /// Returns reviews authored by a specific user.
  Future<List<ReviewModel>> getReviewsByAuthor(
    String businessId,
    String authorUserId,
  );

  /// Creates a new review. Returns the created record.
  Future<ReviewModel> createReview({
    required String businessId,
    required String authorUserId,
    required String targetUserId,
    required int rating,
    String? comment,
  });

  /// Toggles the verified status of a review. Owner only.
  Future<ReviewModel> setVerified(String reviewId, {required bool isVerified});

  /// Permanently deletes a review. Owner or author only.
  Future<void> deleteReview(String reviewId);
}
