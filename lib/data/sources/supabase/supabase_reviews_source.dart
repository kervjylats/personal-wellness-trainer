// lib/data/sources/supabase/supabase_reviews_source.dart
//
// Real Supabase implementation of ReviewsRepository. setVerified() and
// deleteReview() carry the exact restrictions documented in the
// interface itself ("Owner only" / "Owner or author only") — enforced at
// the RLS layer (schema.sql), not just by convention here.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/review_model.dart';
import 'package:personal_wellness_trainer/data/repositories/reviews_repository.dart';

class SupabaseReviewsSource implements ReviewsRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<ReviewModel>> getReviews(String businessId) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReviewModel>> getReviewsForTarget(
    String businessId,
    String targetUserId,
  ) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('business_id', businessId)
        .eq('target_user_id', targetUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReviewModel>> getReviewsByAuthor(
    String businessId,
    String authorUserId,
  ) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('business_id', businessId)
        .eq('author_user_id', authorUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReviewModel> createReview({
    required String businessId,
    required String authorUserId,
    required String targetUserId,
    required int rating,
    String? comment,
  }) async {
    final row = await _db.from('reviews').insert({
      'business_id': businessId,
      'author_user_id': authorUserId,
      'target_user_id': targetUserId,
      'rating': rating,
      'is_verified': false,
      if (comment != null) 'comment': comment,
    }).select().single();

    return ReviewModel.fromJson(row);
  }

  @override
  Future<ReviewModel> setVerified(
    String reviewId, {
    required bool isVerified,
  }) async {
    final row = await _db
        .from('reviews')
        .update({'is_verified': isVerified})
        .eq('id', reviewId)
        .select()
        .single();
    return ReviewModel.fromJson(row);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _db.from('reviews').delete().eq('id', reviewId);
  }
}
