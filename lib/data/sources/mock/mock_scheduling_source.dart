// lib/data/sources/mock/mock_scheduling_source.dart
//
// Mock implementation of SchedulingRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/schedule_slot_model.dart';
import 'package:personal_wellness_trainer/data/repositories/scheduling_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockSchedulingSource with MockSourceMixin implements SchedulingRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _staffUserId = 'usr_staff_001';

  static final List<ScheduleSlotModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<ScheduleSlotModel>> getSlots(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((s) => s.businessId == businessId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<ScheduleSlotModel>> getSlotsForStaff(
    String businessId,
    String staffUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((s) =>
            s.businessId == businessId && s.staffUserId == staffUserId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<ScheduleSlotModel>> getAvailableSlots(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((s) => s.businessId == businessId && s.isAvailable)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
  Future<ScheduleSlotModel> createSlot({
    required String businessId,
    required String staffUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    await simulateNetworkDelay();
    final slot = ScheduleSlotModel(
      id: 'slot_mock_${++_idCounter}',
      businessId: businessId,
      staffUserId: staffUserId,
      startTime: startTime,
      endTime: endTime,
      isAvailable: true,
      notes: notes,
    );
    _store.add(slot);
    return slot;
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
    await simulateNetworkDelay();
    final idx = _store.indexWhere((s) => s.id == slotId);
    if (idx == -1) throw StateError('Slot $slotId not found in mock store');
    final updated = _store[idx].copyWith(
      isAvailable: isAvailable,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
      linkedActivityId: linkedActivityId,
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteSlot(String slotId) async {
    await simulateNetworkDelay();
    _store.removeWhere((s) => s.id == slotId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<ScheduleSlotModel> _buildSeedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      ScheduleSlotModel(
        id: 'slot_mock_001',
        businessId: _businessId,
        staffUserId: _staffUserId,
        startTime: today.add(const Duration(hours: 9)),
        endTime: today.add(const Duration(hours: 10)),
        isAvailable: true,
      ),
      ScheduleSlotModel(
        id: 'slot_mock_002',
        businessId: _businessId,
        staffUserId: _staffUserId,
        startTime: today.add(const Duration(hours: 11)),
        endTime: today.add(const Duration(hours: 12)),
        isAvailable: false,
        linkedActivityId: 'act_mock_001',
      ),
      ScheduleSlotModel(
        id: 'slot_mock_003',
        businessId: _businessId,
        staffUserId: _staffUserId,
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 15)),
        isAvailable: true,
      ),
    ];
  }
}
