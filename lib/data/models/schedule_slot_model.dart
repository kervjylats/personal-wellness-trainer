// lib/data/models/schedule_slot_model.dart
//
// Immutable data record for a single availability slot in the schedule.
// A slot represents a time window when a staff member is available.
// No industry-specific words (no 'appointment', 'class', 'shift').

class ScheduleSlotModel {
  const ScheduleSlotModel({
    required this.id,
    required this.businessId,
    required this.staffUserId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.notes,
    this.linkedActivityId,
  });

  final String id;
  final String businessId;

  /// The staff member (or owner) who owns this slot.
  final String staffUserId;

  final DateTime startTime;
  final DateTime endTime;

  /// When false, this slot is booked or blocked.
  final bool isAvailable;

  /// Optional notes for this slot.
  final String? notes;

  /// If this slot is linked to an existing activity record.
  final String? linkedActivityId;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    return ScheduleSlotModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      staffUserId: json['staff_user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      isAvailable: json['is_available'] as bool? ?? true,
      notes: json['notes'] as String?,
      linkedActivityId: json['linked_activity_id'] as String?,
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'staff_user_id': staffUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_available': isAvailable,
      'notes': notes,
      'linked_activity_id': linkedActivityId,
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  ScheduleSlotModel copyWith({
    String? id,
    String? businessId,
    String? staffUserId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
    String? notes,
    String? linkedActivityId,
  }) {
    return ScheduleSlotModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      staffUserId: staffUserId ?? this.staffUserId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
    );
  }
}
