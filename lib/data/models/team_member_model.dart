// lib/data/models/team_member_model.dart

class TeamMemberModel {
  const TeamMemberModel({
    required this.userId,
    required this.businessId,
    required this.role,
    required this.displayName,
    required this.isActive,
    required this.joinedAt,
    required this.featureToggles,
    this.categoryId,
    this.email,
    this.photoUrl,
    this.inviteToken,
    this.primaryPartnerId, // ◄ Added to track client referrals for partner spin-offs
  });

  final String userId;
  final String businessId;
  final String role;
  final String displayName;
  final bool isActive;
  final DateTime joinedAt;
  final Map<String, bool> featureToggles;
  final String? categoryId;
  final String? email;
  final String? photoUrl;
  final String? inviteToken;
  final String? primaryPartnerId; // ◄ Nullable field for tracking

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      role: json['role'] as String,
      displayName: json['display_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      featureToggles: Map<String, bool>.from(
        json['feature_toggles'] as Map<String, dynamic>? ?? {},
      ),
      categoryId: json['category_id'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photo_url'] as String?,
      inviteToken: json['invite_token'] as String?,
      primaryPartnerId: json['primary_partner_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'business_id': businessId,
      'role': role,
      'display_name': displayName,
      'is_active': isActive,
      'joined_at': joinedAt.toIso8601String(),
      'feature_toggles': featureToggles,
      if (categoryId != null) 'category_id': categoryId,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (inviteToken != null) 'invite_token': inviteToken,
      if (primaryPartnerId != null) 'primary_partner_id': primaryPartnerId,
    };
  }

  TeamMemberModel copyWith({
    String? userId,
    String? businessId,
    String? role,
    String? displayName,
    bool? isActive,
    DateTime? joinedAt,
    Map<String, bool>? featureToggles,
    String? categoryId,
    String? email,
    String? photoUrl,
    String? inviteToken,
    String? primaryPartnerId,
  }) {
    return TeamMemberModel(
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      featureToggles: featureToggles ?? this.featureToggles,
      categoryId: categoryId ?? this.categoryId,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      inviteToken: inviteToken ?? this.inviteToken,
      primaryPartnerId: primaryPartnerId ?? this.primaryPartnerId,
    );
  }
}