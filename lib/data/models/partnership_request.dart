// lib/data/models/partnership_request.dart
//
// Data model for a marketplace partnership request — the handshake initiated
// when Owner A taps "Send Request" on Owner B's marketplace profile card.
//
// Lifecycle:
//   'pending'  → sent by sender, awaiting recipient response
//   'accepted' → recipient accepted → routes to Phase 4 agreement creation flow
//   'declined' → recipient declined
//
// IMPORTANT: Accepting a request does NOT create an agreement here.
// It routes to the existing proposeAgreement flow in AgreementsNotifier.
// Blueprint §18: "Accept → routes to existing Phase 4 Agreement creation flow."
// Zero duplication of agreement logic.
//
// Design rules (Blueprint §14):
//   - Immutable. All fields final.
//   - copyWith() for producing updated copies.
//   - fromJson() / toJson() for mock and Supabase layers.
//   - ZERO business logic. Pure data container.

class PartnershipRequest {
  const PartnershipRequest({
    required this.id,
    required this.senderOwnerUserId,
    required this.receiverOwnerUserId,
    required this.senderBusinessId,
    required this.senderBusinessName,
    required this.senderCategoryId,
    required this.receiverCategoryId,
    required this.status,
    required this.createdAt,
    this.message,
    this.respondedAt,
  });

  final String id;
  final String senderOwnerUserId;
  final String receiverOwnerUserId;
  final String senderBusinessId;
  final String senderBusinessName;
  final String senderCategoryId;
  final String receiverCategoryId;
  final String status;
  final DateTime createdAt;
  final String? message;
  final DateTime? respondedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';

  factory PartnershipRequest.fromJson(Map<String, dynamic> json) {
    return PartnershipRequest(
      id: json['id'] as String,
      senderOwnerUserId: json['sender_owner_user_id'] as String,
      receiverOwnerUserId: json['receiver_owner_user_id'] as String,
      senderBusinessId: json['sender_business_id'] as String,
      senderBusinessName: json['sender_business_name'] as String? ?? '',
      senderCategoryId: json['sender_category_id'] as String,
      receiverCategoryId: json['receiver_category_id'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      message: json['message'] as String?,
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_owner_user_id': senderOwnerUserId,
      'receiver_owner_user_id': receiverOwnerUserId,
      'sender_business_id': senderBusinessId,
      'sender_business_name': senderBusinessName,
      'sender_category_id': senderCategoryId,
      'receiver_category_id': receiverCategoryId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (message != null) 'message': message,
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    };
  }

  PartnershipRequest copyWith({
    String? id,
    String? senderOwnerUserId,
    String? receiverOwnerUserId,
    String? senderBusinessId,
    String? senderBusinessName,
    String? senderCategoryId,
    String? receiverCategoryId,
    String? status,
    DateTime? createdAt,
    String? message,
    DateTime? respondedAt,
  }) {
    return PartnershipRequest(
      id: id ?? this.id,
      senderOwnerUserId: senderOwnerUserId ?? this.senderOwnerUserId,
      receiverOwnerUserId: receiverOwnerUserId ?? this.receiverOwnerUserId,
      senderBusinessId: senderBusinessId ?? this.senderBusinessId,
      senderBusinessName: senderBusinessName ?? this.senderBusinessName,
      senderCategoryId: senderCategoryId ?? this.senderCategoryId,
      receiverCategoryId: receiverCategoryId ?? this.receiverCategoryId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      message: message ?? this.message,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  String toString() =>
      'PartnershipRequest(id: $id, from: $senderOwnerUserId, '
      'to: $receiverOwnerUserId, status: $status)';
}