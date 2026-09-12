// lib/data/sources/supabase/supabase_activity_source.dart
//
// Real Supabase implementation of ActivityRepository. RLS on the
// activities table (schema.sql) is business-wide, not per-role — same as
// MockActivitySource's own getActivities(), which does no role filtering
// itself either. The 3-way split (all / staff's own / client's own) is
// application-level filtering on top of an already business-scoped read,
// mirrored here exactly the same way the mock does it.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/activity_model.dart';
import 'package:personal_wellness_trainer/data/repositories/activity_repository.dart';

class SupabaseActivitySource implements ActivityRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<ActivityModel>> getActivities(String businessId) async {
    final rows = await _db
        .from('activities')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ActivityModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ActivityModel>> getActivitiesForStaff(
    String businessId,
    String staffUserId,
  ) async {
    final rows = await _db
        .from('activities')
        .select()
        .eq('business_id', businessId)
        .eq('assigned_to_user_id', staffUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ActivityModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ActivityModel>> getActivitiesForClient(
    String businessId,
    String clientUserId,
  ) async {
    final rows = await _db
        .from('activities')
        .select()
        .eq('business_id', businessId)
        .eq('client_user_id', clientUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ActivityModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ActivityModel> createActivity({
    required String businessId,
    required String createdByUserId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  }) async {
    final row = await _db.from('activities').insert({
      'business_id': businessId,
      'created_by_user_id': createdByUserId,
      'fields': fields,
      'status': 'pending',
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      if (clientUserId != null) 'client_user_id': clientUserId,
      if (notes != null) 'notes': notes,
    }).select().single();

    return ActivityModel.fromJson(row);
  }

  @override
  Future<ActivityModel> updateActivity({
    required String activityId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  }) async {
    final row = await _db.from('activities').update({
      'fields': fields,
      'updated_at': DateTime.now().toIso8601String(),
      if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
      if (clientUserId != null) 'client_user_id': clientUserId,
      if (notes != null) 'notes': notes,
    }).eq('id', activityId).select().single();

    return ActivityModel.fromJson(row);
  }

  @override
  Future<void> updateActivityStatus(String activityId, String newStatus) async {
    await _db.from('activities').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', activityId);
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await _db.from('activities').delete().eq('id', activityId);
  }
}
