// lib/data/models/challenge_model.dart
//
// Represents a challenge created by the owner.
// Clients can join and mark daily completion.

class ChallengeModel {
  final String id;
  final String businessId;
  final String createdByUserId;
  final String title;
  final String description;
  final int durationDays;
  final DateTime createdAt;
  final bool isActive;

  const ChallengeModel({
    required this.id,
    required this.businessId,
    required this.createdByUserId,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.createdAt,
    this.isActive = true,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      createdByUserId: json['created_by_user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      durationDays: json['duration_days'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'created_by_user_id': createdByUserId,
    'title': title,
    'description': description,
    'duration_days': durationDays,
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive,
  };

  ChallengeModel copyWith({
    String? id,
    String? businessId,
    String? createdByUserId,
    String? title,
    String? description,
    int? durationDays,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}