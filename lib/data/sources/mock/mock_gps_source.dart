// lib/data/sources/mock/mock_gps_source.dart
//
// Mock implementation of GpsRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/gps_point_model.dart';
import 'package:personal_wellness_trainer/data/repositories/gps_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockGpsSource with MockSourceMixin implements GpsRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _staffUserId = 'usr_staff_001';
  static const String _ownerUserId = 'usr_owner_001';

  static final List<GpsPointModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<GpsPointModel>> getLatestPoints(String businessId) async {
    await simulateNetworkDelay();
    // Return only the most recent point per user.
    final allForBiz = _store.where((p) => p.businessId == businessId).toList();
    final Map<String, GpsPointModel> latestByUser = {};
    for (final point in allForBiz) {
      final existing = latestByUser[point.userId];
      if (existing == null ||
          point.recordedAt.isAfter(existing.recordedAt)) {
        latestByUser[point.userId] = point;
      }
    }
    return latestByUser.values.toList();
  }

  @override
  Future<List<GpsPointModel>> getPointsForUser(
    String businessId,
    String userId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((p) => p.businessId == businessId && p.userId == userId)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
  Future<GpsPointModel> recordPoint({
    required String businessId,
    required String userId,
    required double latitude,
    required double longitude,
    String? label,
    double? accuracyMetres,
    String? linkedActivityId,
  }) async {
    await simulateNetworkDelay();
    final point = GpsPointModel(
      id: 'gps_mock_${++_idCounter}',
      businessId: businessId,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      label: label,
      accuracyMetres: accuracyMetres,
      linkedActivityId: linkedActivityId,
      recordedAt: DateTime.now(),
    );
    _store.add(point);
    return point;
  }

  @override
  Future<void> clearPointsForUser(String businessId, String userId) async {
    await simulateNetworkDelay();
    _store.removeWhere(
        (p) => p.businessId == businessId && p.userId == userId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<GpsPointModel> _buildSeedData() {
    final now = DateTime.now();
    return [
      GpsPointModel(
        id: 'gps_mock_001',
        businessId: _businessId,
        userId: _staffUserId,
        latitude: 51.5074,
        longitude: -0.1278,
        label: 'En route',
        accuracyMetres: 10.0,
        recordedAt: now.subtract(const Duration(minutes: 5)),
      ),
      GpsPointModel(
        id: 'gps_mock_002',
        businessId: _businessId,
        userId: _staffUserId,
        latitude: 51.5080,
        longitude: -0.1285,
        label: 'Arrived',
        accuracyMetres: 5.0,
        recordedAt: now.subtract(const Duration(minutes: 2)),
      ),
      GpsPointModel(
        id: 'gps_mock_003',
        businessId: _businessId,
        userId: _ownerUserId,
        latitude: 51.5090,
        longitude: -0.1300,
        label: 'Base',
        recordedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
}
