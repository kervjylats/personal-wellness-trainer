// lib/data/sources/supabase/supabase_delivery_fees_source.dart
//
// Real Supabase implementation of DeliveryFeesRepository.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/delivery_fee_model.dart';
import 'package:personal_wellness_trainer/data/repositories/delivery_fees_repository.dart';

class SupabaseDeliveryFeesSource implements DeliveryFeesRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<DeliveryFeeModel>> getDeliveryFees(String businessId) async {
    final rows = await _db
        .from('delivery_fees')
        .select()
        .eq('business_id', businessId);
    return (rows as List)
        .map((r) => DeliveryFeeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DeliveryFeeModel>> getActiveDeliveryFees(
    String businessId,
  ) async {
    final rows = await _db
        .from('delivery_fees')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true);
    return (rows as List)
        .map((r) => DeliveryFeeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

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
    final row = await _db.from('delivery_fees').insert({
      'business_id': businessId,
      'zone_label': zoneLabel,
      'min_distance_km': minDistanceKm,
      'max_distance_km': maxDistanceKm,
      'fee': fee,
      'currency': currency,
      'is_active': isActive,
    }).select().single();

    return DeliveryFeeModel.fromJson(row);
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
    final updates = <String, dynamic>{};
    if (zoneLabel != null) updates['zone_label'] = zoneLabel;
    if (minDistanceKm != null) updates['min_distance_km'] = minDistanceKm;
    if (maxDistanceKm != null) updates['max_distance_km'] = maxDistanceKm;
    if (fee != null) updates['fee'] = fee;
    if (isActive != null) updates['is_active'] = isActive;

    final row = await _db
        .from('delivery_fees')
        .update(updates)
        .eq('id', deliveryFeeId)
        .select()
        .single();

    return DeliveryFeeModel.fromJson(row);
  }

  @override
  Future<void> deleteDeliveryFee(String deliveryFeeId) async {
    await _db.from('delivery_fees').delete().eq('id', deliveryFeeId);
  }

  @override
  Future<double?> calculateFee(String businessId, double distanceKm) async {
    final active = await getActiveDeliveryFees(businessId);
    for (final zone in active) {
      if (distanceKm >= zone.minDistanceKm && distanceKm <= zone.maxDistanceKm) {
        return zone.fee;
      }
    }
    return null;
  }
}
