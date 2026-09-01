// lib/data/repositories/gps_repository.dart
//
// Abstract interface for GPS location tracking operations.
// GpsNotifier talks ONLY to this interface.
// Mock: MockGpsSource (Phases 1–9). Real: SupabaseGpsSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/gps_point_model.dart';

abstract class GpsRepository {
  /// Returns the most recent GPS points for all tracked users in a business.
  /// Typically returns only the latest point per user.
  Future<List<GpsPointModel>> getLatestPoints(String businessId);

  /// Returns the full tracking history for a specific user.
  Future<List<GpsPointModel>> getPointsForUser(
    String businessId,
    String userId,
  );

  /// Records a new GPS point. Returns the created record.
  Future<GpsPointModel> recordPoint({
    required String businessId,
    required String userId,
    required double latitude,
    required double longitude,
    String? label,
    double? accuracyMetres,
    String? linkedActivityId,
  });

  /// Clears all GPS history for a user. Used for privacy/GDPR.
  Future<void> clearPointsForUser(String businessId, String userId);
}
