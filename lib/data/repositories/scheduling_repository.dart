// lib/data/repositories/scheduling_repository.dart
//
// Abstract interface for all schedule slot data operations.
// SchedulingNotifier talks ONLY to this interface.
// Mock: MockSchedulingSource (Phases 1–9). Real: SupabaseSchedulingSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/schedule_slot_model.dart';

abstract class SchedulingRepository {
  /// Returns all slots for a business.
  Future<List<ScheduleSlotModel>> getSlots(String businessId);

  /// Returns slots for a specific staff member.
  Future<List<ScheduleSlotModel>> getSlotsForStaff(
    String businessId,
    String staffUserId,
  );

  /// Returns only available slots (isAvailable == true) for a business.
  Future<List<ScheduleSlotModel>> getAvailableSlots(String businessId);

  /// Creates a new slot. Returns the created record.
  Future<ScheduleSlotModel> createSlot({
    required String businessId,
    required String staffUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  });

  /// Updates a slot's availability or timing.
  Future<ScheduleSlotModel> updateSlot({
    required String slotId,
    bool? isAvailable,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? linkedActivityId,
  });

  /// Permanently deletes a slot.
  Future<void> deleteSlot(String slotId);
}
