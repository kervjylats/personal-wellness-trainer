// lib/modules/gps/providers/gps_notifier.dart
//
// AsyncNotifier managing GPS location points for the current business.
// Owner: sees latest point for each tracked user.
// Staff: sees only their own history.
// In Phase 10, replace MockGpsSource() with SupabaseGpsSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/gps_point_model.dart';
import 'package:personal_wellness_trainer/data/repositories/gps_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_gps_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/gps/providers/gps_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final gpsNotifierProvider =
    AsyncNotifierProvider<GpsNotifier, List<GpsPointModel>>(
  GpsNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class GpsNotifier extends AsyncNotifier<List<GpsPointModel>> {
  static const String _tag = 'GpsNotifier';
  late GpsRepository _repo;

  @override
  Future<List<GpsPointModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('gps')) {
      AppLogger.debug('GpsNotifier: module not included', tag: _tag);
      return [];
    }

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
        'GpsNotifier: loading for role ${role.value}', tag: _tag);

    if (role.isStaff) {
      return _repo.getPointsForUser(profile.businessId, profile.userId);
    }
    // Owner and partner: latest point per user for overview.
    return _repo.getLatestPoints(profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Records a GPS point for the current user. Returns the point or null.
  Future<GpsPointModel?> recordPoint({
    required double latitude,
    required double longitude,
    String? label,
    double? accuracyMetres,
    String? linkedActivityId,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(gpsActionErrorProvider.notifier).state = null;

    try {
      final point = await _repo.recordPoint(
        businessId: authState.profile.businessId,
        userId: authState.profile.userId,
        latitude: latitude,
        longitude: longitude,
        label: label,
        accuracyMetres: accuracyMetres,
        linkedActivityId: linkedActivityId,
      );
      ref.invalidateSelf();
      AppLogger.info('GpsNotifier: recorded ${point.id}', tag: _tag);
      return point;
    } catch (e, st) {
      AppLogger.error('GpsNotifier: recordPoint failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(gpsActionErrorProvider.notifier).state =
          'Could not record location. Please try again.';
      return null;
    }
  }

  /// Clears GPS history for the current user.
  Future<bool> clearMyPoints() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return false;

    ref.read(gpsActionErrorProvider.notifier).state = null;

    try {
      await _repo.clearPointsForUser(
        authState.profile.businessId,
        authState.profile.userId,
      );
      ref.invalidateSelf();
      AppLogger.info('GpsNotifier: cleared points', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('GpsNotifier: clearMyPoints failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(gpsActionErrorProvider.notifier).state =
          'Could not clear location data. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  GpsRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockGpsSource();
    throw UnimplementedError(
        'SupabaseGpsSource not yet wired (Phase 10 only).');
  }
}

