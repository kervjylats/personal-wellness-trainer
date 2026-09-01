// lib/data/repositories/delivery_fees_repository.dart
//
// Abstract interface for delivery fee zone operations.
// DeliveryFeesNotifier talks ONLY to this interface.
// Mock: MockDeliveryFeesSource (Phases 1–9). Real: SupabaseDeliveryFeesSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/delivery_fee_model.dart';

abstract class DeliveryFeesRepository {
  /// Returns all delivery fee zones for a business.
  Future<List<DeliveryFeeModel>> getDeliveryFees(String businessId);

  /// Returns only active zones.
  Future<List<DeliveryFeeModel>> getActiveDeliveryFees(String businessId);

  /// Creates a new delivery fee zone. Returns the created record.
  Future<DeliveryFeeModel> createDeliveryFee({
    required String businessId,
    required String zoneLabel,
    required double minDistanceKm,
    required double maxDistanceKm,
    required double fee,
    required String currency,
    bool isActive = true,
  });

  /// Updates an existing zone. Returns the updated record.
  Future<DeliveryFeeModel> updateDeliveryFee({
    required String deliveryFeeId,
    String? zoneLabel,
    double? minDistanceKm,
    double? maxDistanceKm,
    double? fee,
    bool? isActive,
  });

  /// Permanently deletes a delivery fee zone.
  Future<void> deleteDeliveryFee(String deliveryFeeId);

  /// Returns the applicable fee for a given distance, or null if no zone matches.
  Future<double?> calculateFee(String businessId, double distanceKm);
}
