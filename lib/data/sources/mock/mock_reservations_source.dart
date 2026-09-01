// lib/data/sources/mock/mock_reservations_source.dart
//
// Mock implementation of ReservationsRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/reservation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/reservations_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockReservationsSource with MockSourceMixin implements ReservationsRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _staffUserId = 'usr_staff_001';
  static const String _clientUserId = 'usr_client_001';

  static final List<ReservationModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<ReservationModel>> getReservations(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((r) => r.businessId == businessId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<ReservationModel>> getReservationsForClient(
    String businessId,
    String clientUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((r) =>
            r.businessId == businessId && r.clientUserId == clientUserId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<ReservationModel>> getReservationsForStaff(
    String businessId,
    String staffUserId,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((r) =>
            r.businessId == businessId && r.staffUserId == staffUserId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

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
    await simulateNetworkDelay();
    final reservation = ReservationModel(
      id: 'res_mock_${++_idCounter}',
      businessId: businessId,
      clientUserId: clientUserId,
      staffUserId: staffUserId,
      startTime: startTime,
      endTime: endTime,
      status: 'pending',
      notes: notes,
      linkedCatalogItemId: linkedCatalogItemId,
      createdAt: DateTime.now(),
    );
    _store.add(reservation);
    return reservation;
  }

  @override
  Future<void> updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((r) => r.id == reservationId);
    if (idx == -1) {
      throw StateError('Reservation $reservationId not found in mock store');
    }
    _store[idx] = _store[idx].copyWith(status: newStatus);
  }

  @override
  Future<void> deleteReservation(String reservationId) async {
    await simulateNetworkDelay();
    _store.removeWhere((r) => r.id == reservationId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<ReservationModel> _buildSeedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      ReservationModel(
        id: 'res_mock_001',
        businessId: _businessId,
        clientUserId: _clientUserId,
        staffUserId: _staffUserId,
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 11)),
        status: 'confirmed',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      ReservationModel(
        id: 'res_mock_002',
        businessId: _businessId,
        clientUserId: _clientUserId,
        staffUserId: _staffUserId,
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 15)),
        status: 'pending',
        notes: 'Please confirm.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      ReservationModel(
        id: 'res_mock_003',
        businessId: _businessId,
        clientUserId: _clientUserId,
        startTime: today.add(const Duration(days: 1, hours: 9)),
        endTime: today.add(const Duration(days: 1, hours: 10)),
        status: 'pending',
        createdAt: today,
      ),
    ];
  }
}
