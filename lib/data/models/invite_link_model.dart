
class InviteLinkModel {
  const InviteLinkModel({
    required this.id,
    required this.token,
    required this.businessId,
    required this.invitedByUserId,
    required this.invitedByRole,
    required this.targetRole,
    required this.createdAt,
    required this.useCount,
    required this.maxUses,
    this.categoryId,
    this.expiresAt,
    this.label,
  });

  final String id;
  final String token;
  final String businessId;
  final String invitedByUserId;
  final String invitedByRole;
  final String targetRole;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int useCount;
  final int maxUses;
  final String? label;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isExhausted => maxUses > 0 && useCount >= maxUses;

  bool get isValid => !isExpired && !isExhausted;

  factory InviteLinkModel.fromJson(Map<String, dynamic> json) {
    return InviteLinkModel(
      id: json['id'] as String,
      token: json['token'] as String,
      businessId: json['business_id'] as String,
      invitedByUserId: json['invited_by_user_id'] as String,
      invitedByRole: json['invited_by_role'] as String,
      targetRole: json['target_role'] as String,
      categoryId: json['category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      useCount: json['use_count'] as int? ?? 0,
      maxUses: json['max_uses'] as int? ?? 0,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'business_id': businessId,
      'invited_by_user_id': invitedByUserId,
      'invited_by_role': invitedByRole,
      'target_role': targetRole,
      'created_at': createdAt.toIso8601String(),
      'use_count': useCount,
      'max_uses': maxUses,
      if (categoryId != null) 'category_id': categoryId,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (label != null) 'label': label,
    };
  }

  InviteLinkModel copyWith({
    String? id,
    String? token,
    String? businessId,
    String? invitedByUserId,
    String? invitedByRole,
    String? targetRole,
    String? categoryId,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? useCount,
    int? maxUses,
    String? label,
  }) {
    return InviteLinkModel(
      id: id ?? this.id,
      token: token ?? this.token,
      businessId: businessId ?? this.businessId,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      invitedByRole: invitedByRole ?? this.invitedByRole,
      targetRole: targetRole ?? this.targetRole,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      useCount: useCount ?? this.useCount,
      maxUses: maxUses ?? this.maxUses,
      label: label ?? this.label,
    );
  }
}
