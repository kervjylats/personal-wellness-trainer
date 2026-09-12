// lib/data/sources/supabase/supabase_reservations_source.dart
//
// Real Supabase implementation of ReservationsRepository. Business-
// membership scoped throughout — matches reservations_notifier.dart's own
// updateStatus() call site, which has no ownership check (not restricted
// to just the holding client or assigned staff).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/reservation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/reservations_repository.dart';

class SupabaseReservationsSource implements ReservationsRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<ReservationModel>> getReservations(String businessId) async {
    final rows = await _db
        .from('reservations')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReservationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReservationModel>> getReservationsForClient(
    String businessId,
    String clientUserId,
  ) async {
    final rows = await _db
        .from('reservations')
        .select()
        .eq('business_id', businessId)
        .eq('client_user_id', clientUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReservationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReservationModel>> getReservationsForStaff(
    String businessId,
    String staffUserId,
  ) async {
    final rows = await _db
        .from('reservations')
        .select()
        .eq('business_id', businessId)
        .eq('staff_user_id', staffUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ReservationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReservationModel> createReservation({
    required String businessId,
    required String clientUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? staffUserId,
    String? notes,
    String? linkedCatalogItemId,
  }) async {
    final row = await _db.from('reservations').insert({
      'business_id': businessId,
      'client_user_id': clientUserId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': 'pending',
      if (staffUserId != null) 'staff_user_id': staffUserId,
      if (notes != null) 'notes': notes,
      if (linkedCatalogItemId != null) 'linked_catalog_item_id': linkedCatalogItemId,
    }).select().single();

    return ReservationModel.fromJson(row);
  }

  @override
  Future<void> updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    await _db
        .from('reservations')
        .update({'status': newStatus})
        .eq('id', reservationId);
  }

  @override
  Future<void> deleteReservation(String reservationId) async {
    await _db.from('reservations').delete().eq('id', reservationId);
  }
}
