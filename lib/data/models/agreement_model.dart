// lib/data/models/agreement_model.dart
//
// Data model for a partnership agreement between an owner and a partner.
// An agreement defines the commission split and feature gates for the deal.
//
// Lifecycle status values (lowercase strings, set by agreementsNotifier):
//   'proposed'  → sent by one party, awaiting response
//   'active'    → accepted — both parties' category slot is now locked
//   'declined'  → rejected by recipient
//   'ended'     → terminated by owner after being active
//
// Commission percentages are stored as doubles (0.0–100.0).
// The owner percentage is what the owner earns on every activity.
// The partner percentage is what the partner earns on their activities.
// Both are tracked independently — they do NOT need to sum to 100.
//
// Design rules (Blueprint §14):
//   - Immutable. All fields final.
//   - copyWith() for producing updated copies.
//   - fromJson() / toJson() for mock and Supabase layers.
//   - ZERO business logic. Pure data container.

class AgreementModel {
  const AgreementModel({
    required this.id,
    required this.businessId,
    required this.ownerUserId,
    required this.partnerUserId,
    required this.partnerBusinessId,
    required this.categoryId,
    required this.ownerCommissionPct,
    required this.partnerCommissionPct,
    required this.status,
    required this.proposedAt,
    this.respondedAt,
    this.endedAt,
    this.notes,
  });

  final String id;
  final String businessId;
  final String ownerUserId;
  final String partnerUserId;

  /// The partner's own business_id. For a within-business Partner-role
  /// agreement this equals [businessId] (same tenant); for a marketplace
  /// (cross-tenant) agreement it's the OTHER business's id — needed so a
  /// client can later look up that business's catalog for this category
  /// without needing the original PartnershipRequest around anymore.
  final String partnerBusinessId;

  /// Category this agreement covers. Must match a category id in config.
  final String categoryId;

  /// Percentage the owner earns on activities in this agreement (0.0–100.0).
  final double ownerCommissionPct;

  /// Percentage the partner earns on activities in this agreement (0.0–100.0).
  final double partnerCommissionPct;

  /// Lifecycle status: 'proposed' | 'active' | 'declined' | 'ended'.
  final String status;

  final DateTime proposedAt;
  final DateTime? respondedAt;
  final DateTime? endedAt;
  final String? notes;

  bool get isActive => status == 'active';
  bool get isPending => status == 'proposed';

  // ── Factories ────────────────────────────────────────────────────────────────

  factory AgreementModel.fromJson(Map<String, dynamic> json) {
    return AgreementModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      partnerUserId: json['partner_user_id'] as String,
      partnerBusinessId: json['partner_business_id'] as String,
      categoryId: json['category_id'] as String,
      ownerCommissionPct: (json['owner_commission_pct'] as num).toDouble(),
      partnerCommissionPct: (json['partner_commission_pct'] as num).toDouble(),
      status: json['status'] as String,
      proposedAt: DateTime.parse(json['proposed_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'owner_user_id': ownerUserId,
      'partner_user_id': partnerUserId,
      'partner_business_id': partnerBusinessId,
      'category_id': categoryId,
      'owner_commission_pct': ownerCommissionPct,
      'partner_commission_pct': partnerCommissionPct,
      'status': status,
      'proposed_at': proposedAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  AgreementModel copyWith({
    String? id,
    String? businessId,
    String? ownerUserId,
    String? partnerUserId,
    String? partnerBusinessId,
    String? categoryId,
    double? ownerCommissionPct,
    double? partnerCommissionPct,
    String? status,
    DateTime? proposedAt,
    DateTime? respondedAt,
    DateTime? endedAt,
    String? notes,
  }) {
    return AgreementModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      partnerUserId: partnerUserId ?? this.partnerUserId,
      partnerBusinessId: partnerBusinessId ?? this.partnerBusinessId,
      categoryId: categoryId ?? this.categoryId,
      ownerCommissionPct: ownerCommissionPct ?? this.ownerCommissionPct,
      partnerCommissionPct: partnerCommissionPct ?? this.partnerCommissionPct,
      status: status ?? this.status,
      proposedAt: proposedAt ?? this.proposedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'AgreementModel(id: $id, status: $status, category: $categoryId)';
}
