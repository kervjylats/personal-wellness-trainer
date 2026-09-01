// lib/data/models/gps_point_model.dart
//
// Immutable data record for a single GPS location point.
// Used to track positions of staff, deliveries, or active jobs.
// No industry-specific words.

class GpsPointModel {
  const GpsPointModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.label,
    this.accuracyMetres,
    this.linkedActivityId,
  });

  final String id;
  final String businessId;

  /// The userId of the person being tracked.
  final String userId;

  final double latitude;
  final double longitude;

  /// Optional human-readable label for this point.
  final String? label;

  /// GPS accuracy in metres, if available.
  final double? accuracyMetres;

  /// If this point is associated with a specific activity.
  final String? linkedActivityId;

  final DateTime recordedAt;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory GpsPointModel.fromJson(Map<String, dynamic> json) {
    return GpsPointModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      label: json['label'] as String?,
      accuracyMetres: json['accuracy_metres'] != null
          ? (json['accuracy_metres'] as num).toDouble()
          : null,
      linkedActivityId: json['linked_activity_id'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'accuracy_metres': accuracyMetres,
      'linked_activity_id': linkedActivityId,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  GpsPointModel copyWith({
    String? id,
    String? businessId,
    String? userId,
    double? latitude,
    double? longitude,
    String? label,
    double? accuracyMetres,
    String? linkedActivityId,
    DateTime? recordedAt,
  }) {
    return GpsPointModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      accuracyMetres: accuracyMetres ?? this.accuracyMetres,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}
