// lib/data/sources/mock/mock_delivery_fees_source.dart
//
// Mock implementation of DeliveryFeesRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/delivery_fee_model.dart';
import 'package:personal_wellness_trainer/data/repositories/delivery_fees_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockDeliveryFeesSource with MockSourceMixin implements DeliveryFeesRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<DeliveryFeeModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<DeliveryFeeModel>> getDeliveryFees(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((f) => f.businessId == businessId)
        .toList()
      ..sort((a, b) => a.minDistanceKm.compareTo(b.minDistanceKm));
  }

  @override
  Future<List<DeliveryFeeModel>> getActiveDeliveryFees(
      String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((f) => f.businessId == businessId && f.isActive)
        .toList()
      ..sort((a, b) => a.minDistanceKm.compareTo(b.minDistanceKm));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
  Future<DeliveryFeeModel> createDeliveryFee({
    required String businessId,
    required String zoneLabel,
    required double minDistanceKm,
    required double maxDistanceKm,
    required double fee,
    required String currency,
    bool isActive = true,
  }) async {
    await simulateNetworkDelay();
    final model = DeliveryFeeModel(
      id: 'fee_mock_${++_idCounter}',
      businessId: businessId,
      zoneLabel: zoneLabel,
      minDistanceKm: minDistanceKm,
      maxDistanceKm: maxDistanceKm,
      fee: fee,
      currency: currency,
      isActive: isActive,
    );
    _store.add(model);
    return model;
  }

  @override
  Future<DeliveryFeeModel> updateDeliveryFee({
    required String deliveryFeeId,
    String? zoneLabel,
    double? minDistanceKm,
    double? maxDistanceKm,
    double? fee,
    bool? isActive,
  }) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((f) => f.id == deliveryFeeId);
    if (idx == -1) {
      throw StateError('DeliveryFee $deliveryFeeId not found in mock store');
    }
    final updated = _store[idx].copyWith(
      zoneLabel: zoneLabel,
      minDistanceKm: minDistanceKm,
      maxDistanceKm: maxDistanceKm,
      fee: fee,
      isActive: isActive,
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteDeliveryFee(String deliveryFeeId) async {
    await simulateNetworkDelay();
    _store.removeWhere((f) => f.id == deliveryFeeId);
  }

  @override
  Future<double?> calculateFee(String businessId, double distanceKm) async {
    await simulateNetworkDelay();
    final active = _store.where(
      (f) => f.businessId == businessId && f.isActive,
    );
    for (final zone in active) {
      if (zone.containsDistance(distanceKm)) return zone.fee;
    }
    return null;
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<DeliveryFeeModel> _buildSeedData() {
    return [
      const DeliveryFeeModel(
        id: 'fee_mock_001',
        businessId: _businessId,
        zoneLabel: 'Local',
        minDistanceKm: 0.0,
        maxDistanceKm: 5.0,
        fee: 3.00,
        currency: '\$',
        isActive: true,
      ),
      const DeliveryFeeModel(
        id: 'fee_mock_002',
        businessId: _businessId,
        zoneLabel: 'Extended',
        minDistanceKm: 5.01,
        maxDistanceKm: 15.0,
        fee: 7.50,
        currency: '\$',
        isActive: true,
      ),
      const DeliveryFeeModel(
        id: 'fee_mock_003',
        businessId: _businessId,
        zoneLabel: 'Remote',
        minDistanceKm: 15.01,
        maxDistanceKm: 50.0,
        fee: 15.00,
        currency: '\$',
        isActive: false,
      ),
    ];
  }
}
