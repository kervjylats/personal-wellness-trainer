// lib/data/sources/supabase/supabase_scheduling_source.dart
//
// Real Supabase implementation of SchedulingRepository. Business-membership
// scoped throughout — matches scheduling_notifier.dart's own createSlot()
// call site, which has no role restriction (any authenticated business
// member can create a slot for any staff member).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/schedule_slot_model.dart';
import 'package:personal_wellness_trainer/data/repositories/scheduling_repository.dart';

class SupabaseSchedulingSource implements SchedulingRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<ScheduleSlotModel>> getSlots(String businessId) async {
    final rows = await _db
        .from('schedule_slots')
        .select()
        .eq('business_id', businessId)
        .order('start_time', ascending: true);
    return (rows as List)
        .map((r) => ScheduleSlotModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduleSlotModel>> getSlotsForStaff(
    String businessId,
    String staffUserId,
  ) async {
    final rows = await _db
        .from('schedule_slots')
        .select()
        .eq('business_id', businessId)
        .eq('staff_user_id', staffUserId)
        .order('start_time', ascending: true);
    return (rows as List)
        .map((r) => ScheduleSlotModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduleSlotModel>> getAvailableSlots(String businessId) async {
    final rows = await _db
        .from('schedule_slots')
        .select()
        .eq('business_id', businessId)
        .eq('is_available', true)
        .order('start_time', ascending: true);
    return (rows as List)
        .map((r) => ScheduleSlotModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ScheduleSlotModel> createSlot({
    required String businessId,
    required String staffUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final row = await _db.from('schedule_slots').insert({
      'business_id': businessId,
      'staff_user_id': staffUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_available': true,
      if (notes != null) 'notes': notes,
    }).select().single();

    return ScheduleSlotModel.fromJson(row);
  }

  @override
  Future<ScheduleSlotModel> updateSlot({
    required String slotId,
    bool? isAvailable,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? linkedActivityId,
  }) async {
    final updates = <String, dynamic>{};
    if (isAvailable != null) updates['is_available'] = isAvailable;
    if (startTime != null) updates['start_time'] = startTime.toIso8601String();
    if (endTime != null) updates['end_time'] = endTime.toIso8601String();
    if (notes != null) updates['notes'] = notes;
    if (linkedActivityId != null) updates['linked_activity_id'] = linkedActivityId;

    final row = await _db
        .from('schedule_slots')
        .update(updates)
        .eq('id', slotId)
        .select()
        .single();

    return ScheduleSlotModel.fromJson(row);
  }

  @override
  Future<void> deleteSlot(String slotId) async {
    await _db.from('schedule_slots').delete().eq('id', slotId);
  }
}
