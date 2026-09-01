// lib/data/models/activity_model.dart
//
// The ActivityModel is the core data record for every bookable service,
// session, trip, or appointment in the system.
//
// Design rules:
//   - Immutable. All fields final.
//   - fields: Map<String,dynamic> — stores all activity_field values from config.
//     Never add typed fields here for industry-specific data (e.g. no 'serviceType',
//     no 'scheduledAt' as a named field). Industry fields live in the map only.
//   - Status values: 'pending' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled'
//   - fromJson() / toJson() / copyWith() — same pattern as all other models.
//   - ZERO business logic. Data container only.

class ActivityModel {
  const ActivityModel({
    required this.id,
    required this.businessId,
    required this.createdByUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.fields,
    this.assignedToUserId,
    this.clientUserId,
    this.notes,
  });

  final String id;
  final String businessId;

  /// The userId of the owner or staff member who created this activity.
  final String createdByUserId;

  /// The staff member assigned to deliver this activity. May be null.
  final String? assignedToUserId;

  /// The client this activity is for. May be null for generic activities.
  final String? clientUserId;

  /// Values: 'pending' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled'
  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// All industry-specific field values, keyed by ActivityField.name.
  /// For example: {'service_type': 'Consultation', 'amount': 120.0, ...}
  /// FieldRenderer reads activity_fields from config to display these.
  final Map<String, dynamic> fields;

  /// Optional free-text notes attached to this activity.
  final String? notes;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id:                json['id'] as String,
      businessId:        json['business_id'] as String,
      createdByUserId:   json['created_by_user_id'] as String,
      assignedToUserId:  json['assigned_to_user_id'] as String?,
      clientUserId:      json['client_user_id'] as String?,
      status:            json['status'] as String? ?? 'pending',
      createdAt:         DateTime.parse(json['created_at'] as String),
      updatedAt:         DateTime.parse(json['updated_at'] as String),
      fields:            Map<String, dynamic>.from(
                           json['fields'] as Map<dynamic, dynamic>? ?? {},
                         ),
      notes:             json['notes'] as String?,
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id':                   id,
      'business_id':          businessId,
      'created_by_user_id':   createdByUserId,
      'status':               status,
      'created_at':           createdAt.toIso8601String(),
      'updated_at':           updatedAt.toIso8601String(),
      'fields':               fields,
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      if (clientUserId != null)     'client_user_id': clientUserId,
      if (notes != null)            'notes': notes,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  ActivityModel copyWith({
    String? id,
    String? businessId,
    String? createdByUserId,
    String? assignedToUserId,
    String? clientUserId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? fields,
    String? notes,
  }) {
    return ActivityModel(
      id:                id              ?? this.id,
      businessId:        businessId      ?? this.businessId,
      createdByUserId:   createdByUserId ?? this.createdByUserId,
      assignedToUserId:  assignedToUserId ?? this.assignedToUserId,
      clientUserId:      clientUserId    ?? this.clientUserId,
      status:            status          ?? this.status,
      createdAt:         createdAt       ?? this.createdAt,
      updatedAt:         updatedAt       ?? this.updatedAt,
      fields:            fields          ?? this.fields,
      notes:             notes           ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ActivityModel(id: $id, status: $status, businessId: $businessId)';
}
