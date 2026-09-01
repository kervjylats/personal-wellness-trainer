// lib/data/repositories/activity_repository.dart
//
// Abstract interface for all activity data operations.
// The ActivityNotifier (P3-05) talks ONLY to this interface — never directly
// to MockActivitySource or SupabaseActivitySource.
//
// Mock implementation: MockActivitySource (P3-04). Active in Phase 1–9.
// Real implementation: SupabaseActivitySource. Wired in Phase 10.
//
// Swap rule: to go live, replace MockActivitySource() with
// SupabaseActivitySource() inside ActivityNotifier._resolveRepository().
// Nothing else changes.

import 'package:personal_wellness_trainer/data/models/activity_model.dart';

abstract class ActivityRepository {
  /// Returns all activities for a business.
  /// Owner sees everything. Filtered further by the notifier for staff/client.
  Future<List<ActivityModel>> getActivities(String businessId);

  /// Returns activities assigned to a specific staff member.
  Future<List<ActivityModel>> getActivitiesForStaff(
    String businessId,
    String staffUserId,
  );

  /// Returns activities belonging to a specific client.
  Future<List<ActivityModel>> getActivitiesForClient(
    String businessId,
    String clientUserId,
  );

  /// Creates a new activity. Returns the created record.
  Future<ActivityModel> createActivity({
    required String businessId,
    required String createdByUserId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  });

  /// Updates the field values of an existing activity.
  Future<ActivityModel> updateActivity({
    required String activityId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  });

  /// Updates only the status of an activity.
  /// Values: 'pending' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled'
  Future<void> updateActivityStatus(String activityId, String newStatus);

  /// Permanently deletes an activity.
  Future<void> deleteActivity(String activityId);
}
