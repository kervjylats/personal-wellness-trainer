// lib/modules/reservations/providers/reservations_notifier.dart
//
// AsyncNotifier managing the slot-based entries for the current business.
// Owner: sees all entries. Staff: sees assigned only. Client: sees their own.
// In Phase 10, replace MockReservationsSource() with SupabaseReservationsSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/reservation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/reservations_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_reservations_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/reservations/providers/reservations_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final reservationsNotifierProvider =
    AsyncNotifierProvider<ReservationsNotifier, List<ReservationModel>>(
  ReservationsNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ReservationsNotifier extends AsyncNotifier<List<ReservationModel>> {
  static const String _tag = 'ReservationsNotifier';
  late ReservationsRepository _repo;

  @override
  Future<List<ReservationModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('reservations')) {
      AppLogger.debug('ReservationsNotifier: module not included', tag: _tag);
      return [];
    }

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
        'ReservationsNotifier: loading for role ${role.value}', tag: _tag);

    if (role.isStaff) {
      return _repo.getReservationsForStaff(
          profile.businessId, profile.userId);
    }
    if (role.isClient) {
      return _repo.getReservationsForClient(
          profile.businessId, profile.userId);
    }
    return _repo.getReservations(profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new entry. Returns the created record or null on error.
  Future<ReservationModel?> create({
    required String clientUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? staffUserId,
    String? notes,
    String? linkedCatalogItemId,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(reservationsActionErrorProvider.notifier).state = null;

    try {
      final created = await _repo.createReservation(
        businessId: authState.profile.businessId,
        clientUserId: clientUserId,
        startTime: startTime,
        endTime: endTime,
        staffUserId: staffUserId,
        notes: notes,
        linkedCatalogItemId: linkedCatalogItemId,
      );
      ref.invalidateSelf();
      AppLogger.info(
          'ReservationsNotifier: created ${created.id}', tag: _tag);
      return created;
    } catch (e, st) {
      AppLogger.error('ReservationsNotifier: create failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(reservationsActionErrorProvider.notifier).state =
          'Could not create entry. Please try again.';
      return null;
    }
  }

  /// Updates the status of an entry. Returns true on success.
  /// Values: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
  Future<bool> updateStatus(
      String entryId, String newStatus) async {
    ref.read(reservationsActionErrorProvider.notifier).state = null;
    try {
      await _repo.updateReservationStatus(entryId, newStatus);
      ref.invalidateSelf();
      AppLogger.info(
          'ReservationsNotifier: status → $newStatus for $entryId',
          tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('ReservationsNotifier: updateStatus failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(reservationsActionErrorProvider.notifier).state =
          'Could not update entry. Please try again.';
      return false;
    }
  }

  /// Deletes an entry. Returns true on success.
  Future<bool> delete(String entryId) async {
    ref.read(reservationsActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteReservation(entryId);
      ref.invalidateSelf();
      AppLogger.info(
          'ReservationsNotifier: deleted $entryId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('ReservationsNotifier: delete failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(reservationsActionErrorProvider.notifier).state =
          'Could not delete entry. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  ReservationsRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockReservationsSource();
    throw UnimplementedError(
        'SupabaseReservationsSource not yet wired (Phase 10 only).');
  }
}

