// lib/data/repositories/reservations_repository.dart
//
// Abstract interface for reservation data operations.
// ReservationsNotifier talks ONLY to this interface.
// Mock: MockReservationsSource (Phases 1–9). Real: SupabaseReservationsSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/reservation_model.dart';

abstract class ReservationsRepository {
  /// Returns all reservations for a business, newest first.
  Future<List<ReservationModel>> getReservations(String businessId);

  /// Returns reservations for a specific client.
  Future<List<ReservationModel>> getReservationsForClient(
    String businessId,
    String clientUserId,
  );

  /// Returns reservations assigned to a specific staff member.
  Future<List<ReservationModel>> getReservationsForStaff(
    String businessId,
    String staffUserId,
  );

  /// Creates a new reservation. Returns the created record.
  Future<ReservationModel> createReservation({
    required String businessId,
    required String clientUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? staffUserId,
    String? notes,
    String? linkedCatalogItemId,
  });

  /// Updates only the status of a reservation.
  /// Values: 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'no_show'
  Future<void> updateReservationStatus(
    String reservationId,
    String newStatus,
  );

  /// Permanently deletes a reservation.
  Future<void> deleteReservation(String reservationId);
}
