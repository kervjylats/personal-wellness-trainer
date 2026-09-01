// lib/modules/delivery_fees/providers/delivery_fees_notifier.dart
//
// AsyncNotifier managing delivery fee zones for the current business.
// Owner: sees and manages all zones. Staff/client: sees active zones only.
// In Phase 10, replace MockDeliveryFeesSource() with SupabaseDeliveryFeesSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/delivery_fee_model.dart';
import 'package:personal_wellness_trainer/data/repositories/delivery_fees_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_delivery_fees_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/providers/delivery_fees_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final deliveryFeesNotifierProvider =
    AsyncNotifierProvider<DeliveryFeesNotifier, List<DeliveryFeeModel>>(
  DeliveryFeesNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class DeliveryFeesNotifier extends AsyncNotifier<List<DeliveryFeeModel>> {
  static const String _tag = 'DeliveryFeesNotifier';
  late DeliveryFeesRepository _repo;

  @override
  Future<List<DeliveryFeeModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('delivery_fees')) {
      AppLogger.debug('DeliveryFeesNotifier: module not included', tag: _tag);
      return [];
    }

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
        'DeliveryFeesNotifier: loading for role ${role.value}', tag: _tag);

    if (role.isOwner) {
      return _repo.getDeliveryFees(profile.businessId);
    }
    return _repo.getActiveDeliveryFees(profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new delivery fee zone. Returns the zone or null on error.
  Future<DeliveryFeeModel?> create({
    required String zoneLabel,
    required double minDistanceKm,
    required double maxDistanceKm,
    required double fee,
    required String currency,
    bool isActive = true,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(deliveryFeesActionErrorProvider.notifier).state = null;

    try {
      final zone = await _repo.createDeliveryFee(
        businessId: authState.profile.businessId,
        zoneLabel: zoneLabel,
        minDistanceKm: minDistanceKm,
        maxDistanceKm: maxDistanceKm,
        fee: fee,
        currency: currency,
        isActive: isActive,
      );
      ref.invalidateSelf();
      AppLogger.info('DeliveryFeesNotifier: created ${zone.id}', tag: _tag);
      return zone;
    } catch (e, st) {
      AppLogger.error('DeliveryFeesNotifier: create failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(deliveryFeesActionErrorProvider.notifier).state =
          'Could not add delivery zone. Please try again.';
      return null;
    }
  }

  /// Updates an existing zone. Returns updated zone or null on error.
  Future<DeliveryFeeModel?> edit({
    required String deliveryFeeId,
    String? zoneLabel,
    double? minDistanceKm,
    double? maxDistanceKm,
    double? fee,
    bool? isActive,
  }) async {
    ref.read(deliveryFeesActionErrorProvider.notifier).state = null;
    try {
      final zone = await _repo.updateDeliveryFee(
        deliveryFeeId: deliveryFeeId,
        zoneLabel: zoneLabel,
        minDistanceKm: minDistanceKm,
        maxDistanceKm: maxDistanceKm,
        fee: fee,
        isActive: isActive,
      );
      ref.invalidateSelf();
      return zone;
    } catch (e, st) {
      AppLogger.error('DeliveryFeesNotifier: update failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(deliveryFeesActionErrorProvider.notifier).state =
          'Could not update zone. Please try again.';
      return null;
    }
  }

  /// Deletes a delivery fee zone. Returns true on success.
  Future<bool> delete(String deliveryFeeId) async {
    ref.read(deliveryFeesActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteDeliveryFee(deliveryFeeId);
      ref.invalidateSelf();
      AppLogger.info(
          'DeliveryFeesNotifier: deleted $deliveryFeeId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('DeliveryFeesNotifier: delete failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(deliveryFeesActionErrorProvider.notifier).state =
          'Could not delete zone. Please try again.';
      return false;
    }
  }

  /// Calculates the fee for a given distance. Returns null if no zone applies.
  Future<double?> calculateFee(double distanceKm) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;
    return _repo.calculateFee(authState.profile.businessId, distanceKm);
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  DeliveryFeesRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockDeliveryFeesSource();
    throw UnimplementedError(
        'SupabaseDeliveryFeesSource not yet wired (Phase 10 only).');
  }
}

