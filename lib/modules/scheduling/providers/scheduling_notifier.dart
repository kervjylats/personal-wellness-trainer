// lib/modules/scheduling/providers/scheduling_notifier.dart
//
// AsyncNotifier managing schedule slots.
// Owner: sees all slots. Staff: sees only their own slots.
// Client: sees only available slots (read-only for booking selection).
// In Phase 10, replace MockSchedulingSource() with SupabaseSchedulingSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/schedule_slot_model.dart';
import 'package:personal_wellness_trainer/data/repositories/scheduling_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_scheduling_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/scheduling/providers/scheduling_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final schedulingNotifierProvider =
    AsyncNotifierProvider<SchedulingNotifier, List<ScheduleSlotModel>>(
  SchedulingNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class SchedulingNotifier extends AsyncNotifier<List<ScheduleSlotModel>> {
  static const String _tag = 'SchedulingNotifier';
  late SchedulingRepository _repo;

  @override
  Future<List<ScheduleSlotModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('scheduling')) {
      AppLogger.debug('SchedulingNotifier: module not included', tag: _tag);
      return [];
    }

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
      'SchedulingNotifier: loading for role ${role.value}',
      tag: _tag,
    );

    if (role.isStaff) {
      return _repo.getSlotsForStaff(profile.businessId, profile.userId);
    }
    if (role.isClient) {
      return _repo.getAvailableSlots(profile.businessId);
    }
    // Owner and partner see all slots.
    return _repo.getSlots(profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new slot. Returns the created slot or null on error.
  Future<ScheduleSlotModel?> createSlot({
    required String staffUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(schedulingActionErrorProvider.notifier).state = null;

    try {
      final slot = await _repo.createSlot(
        businessId: authState.profile.businessId,
        staffUserId: staffUserId,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
      ref.invalidateSelf();
      AppLogger.info('SchedulingNotifier: created ${slot.id}', tag: _tag);
      return slot;
    } catch (e, st) {
      AppLogger.error('SchedulingNotifier: createSlot failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(schedulingActionErrorProvider.notifier).state =
          'Could not create slot. Please try again.';
      return null;
    }
  }

  /// Updates availability of a slot. Returns true on success.
  Future<bool> setAvailability(String slotId,
      {required bool isAvailable}) async {
    ref.read(schedulingActionErrorProvider.notifier).state = null;
    try {
      await _repo.updateSlot(slotId: slotId, isAvailable: isAvailable);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('SchedulingNotifier: setAvailability failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(schedulingActionErrorProvider.notifier).state =
          'Could not update slot. Please try again.';
      return false;
    }
  }

  /// Deletes a slot. Returns true on success.
  Future<bool> deleteSlot(String slotId) async {
    ref.read(schedulingActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteSlot(slotId);
      ref.invalidateSelf();
      AppLogger.info('SchedulingNotifier: deleted $slotId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('SchedulingNotifier: deleteSlot failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(schedulingActionErrorProvider.notifier).state =
          'Could not delete slot. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  SchedulingRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockSchedulingSource();
    throw UnimplementedError(
        'SupabaseSchedulingSource not yet wired (Phase 10 only).');
  }
}

