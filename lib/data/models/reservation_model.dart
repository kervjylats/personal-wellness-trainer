// lib/data/models/reservation_model.dart
//
// Immutable data record for a time-slot reservation.
// Reservations are calendar-bound commitments. They complement Activity records
// but operate on a different axis: slot ownership vs task tracking.
// No industry-specific words (no 'appointment', 'booking', 'treatment').
// Status values: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'

class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.businessId,
    required this.clientUserId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.staffUserId,
    this.notes,
    this.linkedCatalogItemId,
    this.linkedActivityId,
  });

  final String id;
  final String businessId;

  /// The client who holds this reservation.
  final String clientUserId;

  /// The staff member assigned to this reservation. May be null.
  final String? staffUserId;

  final DateTime startTime;
  final DateTime endTime;

  /// Values: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
  final String status;

  final String? notes;

  /// Optional link to a catalog item (e.g. service type being reserved).
  final String? linkedCatalogItemId;

  /// Optional link to an activity record created from this reservation.
  final String? linkedActivityId;

  final DateTime createdAt;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      clientUserId: json['client_user_id'] as String,
      staffUserId: json['staff_user_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      linkedCatalogItemId: json['linked_catalog_item_id'] as String?,
      linkedActivityId: json['linked_activity_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'client_user_id': clientUserId,
      'staff_user_id': staffUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'linked_catalog_item_id': linkedCatalogItemId,
      'linked_activity_id': linkedActivityId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  ReservationModel copyWith({
    String? id,
    String? businessId,
    String? clientUserId,
    String? staffUserId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? notes,
    String? linkedCatalogItemId,
    String? linkedActivityId,
    DateTime? createdAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      clientUserId: clientUserId ?? this.clientUserId,
      staffUserId: staffUserId ?? this.staffUserId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      linkedCatalogItemId: linkedCatalogItemId ?? this.linkedCatalogItemId,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
