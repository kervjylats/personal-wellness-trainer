// lib/data/models/review_model.dart
//
// Immutable data record for a review left by one user about another.
// No industry-specific words. rating is 1–5 inclusive.
// author  = the person who wrote the review (client, partner).
// target  = the person or business being reviewed (owner, staff).

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.businessId,
    required this.authorUserId,
    required this.targetUserId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.isVerified = false,
  });

  final String id;
  final String businessId;

  /// The userId of the person who wrote this review.
  final String authorUserId;

  /// The userId of the person or business being reviewed.
  final String targetUserId;

  /// Integer 1–5 inclusive.
  final int rating;

  /// Optional free-text comment.
  final String? comment;

  /// True when the review has been verified by the owner.
  final bool isVerified;

  final DateTime createdAt;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      authorUserId: json['author_user_id'] as String,
      targetUserId: json['target_user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'author_user_id': authorUserId,
      'target_user_id': targetUserId,
      'rating': rating,
      'comment': comment,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  ReviewModel copyWith({
    String? id,
    String? businessId,
    String? authorUserId,
    String? targetUserId,
    int? rating,
    String? comment,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      authorUserId: authorUserId ?? this.authorUserId,
      targetUserId: targetUserId ?? this.targetUserId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
