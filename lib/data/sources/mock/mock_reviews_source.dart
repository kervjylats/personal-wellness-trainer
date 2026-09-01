// lib/data/sources/mock/mock_reviews_source.dart
//
// Mock implementation of ReviewsRepository.
// Returns generic seed data for Phases 1–9.
//
// ⚠️  ZERO industry-specific words in this file.
//     No 'trainer', 'driver', 'therapist', 'coach', 'session', 'class'.
//     Reviewer names and comments use generic placeholder text.

import 'package:personal_wellness_trainer/data/models/review_model.dart';
import 'package:personal_wellness_trainer/data/repositories/reviews_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockReviewsSource with MockSourceMixin implements ReviewsRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _ownerUserId = 'usr_owner_001';
  static const String _staffUserId = 'usr_staff_001';
  static const String _clientUserId = 'usr_client_001';

  static final List<ReviewModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<ReviewModel>> getReviews(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((r) => r.businessId == businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ReviewModel>> getReviewsForTarget(
    String businessId,
    String targetUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((r) =>
            r.businessId == businessId && r.targetUserId == targetUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ReviewModel>> getReviewsByAuthor(
    String businessId,
    String authorUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((r) =>
            r.businessId == businessId && r.authorUserId == authorUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
  Future<ReviewModel> createReview({
    required String businessId,
    required String authorUserId,
    required String targetUserId,
    required int rating,
    String? comment,
  }) async {
    await simulateNetworkDelay();
    final review = ReviewModel(
      id: 'rev_mock_${++_idCounter}',
      businessId: businessId,
      authorUserId: authorUserId,
      targetUserId: targetUserId,
      rating: rating,
      comment: comment,
      isVerified: false,
      createdAt: DateTime.now(),
    );
    _store.add(review);
    return review;
  }

  @override
  Future<ReviewModel> setVerified(
    String reviewId, {
    required bool isVerified,
  }) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((r) => r.id == reviewId);
    if (idx == -1) throw StateError('Review $reviewId not found in mock store');
    final updated = _store[idx].copyWith(isVerified: isVerified);
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await simulateNetworkDelay();
    _store.removeWhere((r) => r.id == reviewId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<ReviewModel> _buildSeedData() {
    final base = DateTime(2025, 6);
    return [
      ReviewModel(
        id: 'rev_mock_001',
        businessId: _businessId,
        authorUserId: _clientUserId,
        targetUserId: _staffUserId,
        rating: 5,
        comment: 'Excellent experience, very professional.',
        isVerified: true,
        createdAt: base.subtract(const Duration(days: 10)),
      ),
      ReviewModel(
        id: 'rev_mock_002',
        businessId: _businessId,
        authorUserId: _clientUserId,
        targetUserId: _ownerUserId,
        rating: 4,
        comment: 'Great overall, would recommend.',
        isVerified: false,
        createdAt: base.subtract(const Duration(days: 5)),
      ),
      ReviewModel(
        id: 'rev_mock_003',
        businessId: _businessId,
        authorUserId: _clientUserId,
        targetUserId: _staffUserId,
        rating: 3,
        comment: 'Good, but could be improved.',
        isVerified: false,
        createdAt: base.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
