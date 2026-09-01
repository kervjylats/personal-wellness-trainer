// lib/modules/activity/providers/activity_notifier.dart
//
// AsyncNotifier managing the activity list for the current user.
// Role-aware: owner sees all, staff sees assigned only, client sees own only.
//
// Follows Blueprint R-09 error handling pattern:
//   Clear actionError → try → repo call → invalidateSelf → return.
//   Catch → set activityActionErrorProvider → return null / false.
//
// In Phase 10, replace MockActivitySource() with SupabaseActivitySource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/activity_model.dart';
import 'package:personal_wellness_trainer/data/repositories/activity_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_activity_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final activityNotifierProvider =
    AsyncNotifierProvider<ActivityNotifier, List<ActivityModel>>(
  ActivityNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ActivityNotifier extends AsyncNotifier<List<ActivityModel>> {
  static const String _tag = 'ActivityNotifier';
  late ActivityRepository _repo;

  @override
  Future<List<ActivityModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];
    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
      'ActivityNotifier: loading for role ${role.value}',
      tag: _tag,
    );

    // Role-aware data loading — same repo, different query.
    if (role.isOwner) {
      return _repo.getActivities(profile.businessId);
    }
    if (role.isStaff) {
      return _repo.getActivitiesForStaff(
        profile.businessId,
        profile.userId,
      );
    }
    if (role.isClient) {
      return _repo.getActivitiesForClient(
        profile.businessId,
        profile.userId,
      );
    }
    // Partners do not have an activity tab — return empty list as safety net.
    return [];
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new activity from the form field values.
  /// Returns the created ActivityModel or null on error.
  Future<ActivityModel?> create({
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(activityActionErrorProvider.notifier).state = null;

    try {
      final activity = await _repo.createActivity(
        businessId: authState.profile.businessId,
        createdByUserId: authState.profile.userId,
        fields: fields,
        assignedToUserId: assignedToUserId,
        clientUserId: clientUserId,
        notes: notes,
      );
      ref.invalidateSelf();
      AppLogger.info(
        'ActivityNotifier: created ${activity.id}',
        tag: _tag,
      );
      return activity;
    } catch (e, st) {
      AppLogger.error(
        'ActivityNotifier: create failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      ref.read(activityActionErrorProvider.notifier).state =
          'Failed to create activity. Please try again.';
      return null;
    }
  }

  /// Updates the field values of an existing activity.
  /// Renamed from 'update' to avoid clashing with AsyncNotifierBase.update.
  Future<ActivityModel?> updateActivity({
    required String activityId,
    required Map<String, dynamic> fields,
    String? assignedToUserId,
    String? clientUserId,
    String? notes,
  }) async {
    ref.read(activityActionErrorProvider.notifier).state = null;

    try {
      final updated = await _repo.updateActivity(
        activityId: activityId,
        fields: fields,
        assignedToUserId: assignedToUserId,
        clientUserId: clientUserId,
        notes: notes,
      );
      ref.invalidateSelf();
      AppLogger.info(
        'ActivityNotifier: updated $activityId',
        tag: _tag,
      );
      return updated;
    } catch (e, st) {
      AppLogger.error(
        'ActivityNotifier: updateActivity failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      ref.read(activityActionErrorProvider.notifier).state =
          'Failed to update activity. Please try again.';
      return null;
    }
  }

  /// Updates only the status of an activity.
  Future<bool> updateStatus(String activityId, String newStatus) async {
    ref.read(activityActionErrorProvider.notifier).state = null;

    try {
      await _repo.updateActivityStatus(activityId, newStatus);
      ref.invalidateSelf();
      AppLogger.info(
        'ActivityNotifier: status → $newStatus for $activityId',
        tag: _tag,
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'ActivityNotifier: updateStatus failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      ref.read(activityActionErrorProvider.notifier).state =
          'Failed to update status. Please try again.';
      return false;
    }
  }

  /// Permanently deletes an activity.
  Future<bool> delete(String activityId) async {
    ref.read(activityActionErrorProvider.notifier).state = null;

    try {
      await _repo.deleteActivity(activityId);
      ref.invalidateSelf();
      AppLogger.info(
        'ActivityNotifier: deleted $activityId',
        tag: _tag,
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'ActivityNotifier: delete failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      ref.read(activityActionErrorProvider.notifier).state =
          'Failed to delete activity. Please try again.';
      return false;
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────────

  ActivityRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockActivitySource();
    throw UnimplementedError(
      'Real activity source not available until Phase 10.',
    );
  }
}

