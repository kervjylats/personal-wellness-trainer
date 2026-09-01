// lib/data/sources/mock/mock_agreements_source.dart
//
// Mock implementation of AgreementsRepository.
// Seeds one active agreement so the Finance → Deals section has data
// from the first run. Supports full CRUD within a session.
//
// ⚠️ ZERO industry-specific words.
// Compatibility checking is NOT done here — it is done in AgreementsNotifier
// before calling this source, keeping data sources dumb.

import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/repositories/agreements_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockAgreementsSource with MockSourceMixin implements AgreementsRepository {
  static const String _businessId = 'biz_mock_001';

  // Simulated in-memory store.
  static final List<AgreementModel> _store = _buildSeedData();
  static int _idCounter = 10;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<AgreementModel>> getAgreements(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((a) => a.businessId == businessId)
        .toList()
      ..sort((a, b) => b.proposedAt.compareTo(a.proposedAt));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
  Future<AgreementModel> proposeAgreement({
    required String businessId,
    required String ownerUserId,
    required String partnerUserId,
    required String partnerBusinessId,
    required String categoryId,
    required double ownerCommissionPct,
    required double partnerCommissionPct,
    String? notes,
  }) async {
    await simulateNetworkDelay();
    _idCounter++;
    final agreement = AgreementModel(
      id: 'agr_mock_${_idCounter.toString().padLeft(3, '0')}',
      businessId: businessId,
      ownerUserId: ownerUserId,
      partnerUserId: partnerUserId,
      partnerBusinessId: partnerBusinessId,
      categoryId: categoryId,
      ownerCommissionPct: ownerCommissionPct,
      partnerCommissionPct: partnerCommissionPct,
      status: 'proposed',
      proposedAt: DateTime.now(),
      notes: notes,
    );
    _store.add(agreement);
    return agreement;
  }

  @override
  Future<AgreementModel> approveAgreement({
    required String agreementId,
    required String businessId,
  }) async {
    await simulateNetworkDelay();
    return _updateStatus(
      agreementId: agreementId,
      businessId: businessId,
      status: 'active',
      setRespondedAt: true,
    );
  }

  @override
  Future<AgreementModel> declineAgreement({
    required String agreementId,
    required String businessId,
  }) async {
    await simulateNetworkDelay();
    return _updateStatus(
      agreementId: agreementId,
      businessId: businessId,
      status: 'declined',
      setRespondedAt: true,
    );
  }

  @override
  Future<AgreementModel> endAgreement({
    required String agreementId,
    required String businessId,
  }) async {
    await simulateNetworkDelay();
    return _updateStatus(
      agreementId: agreementId,
      businessId: businessId,
      status: 'ended',
      setEndedAt: true,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  AgreementModel _updateStatus({
    required String agreementId,
    required String businessId,
    required String status,
    bool setRespondedAt = false,
    bool setEndedAt = false,
  }) {
    final index = _store.indexWhere(
        (a) => a.id == agreementId && a.businessId == businessId);
    if (index == -1) throw Exception('Agreement $agreementId not found');
    final now = DateTime.now();
    final updated = _store[index].copyWith(
      status: status,
      respondedAt: setRespondedAt ? now : _store[index].respondedAt,
      endedAt: setEndedAt ? now : _store[index].endedAt,
    );
    _store[index] = updated;
    return updated;
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<AgreementModel> _buildSeedData() {
    final base = DateTime(2025, 2, 1);
    return [
      // One active agreement — provides data for Finance → Deals from day one.
      AgreementModel(
        id: 'agr_mock_001',
        businessId: _businessId,
        ownerUserId: 'usr_owner_001',
        partnerUserId: 'usr_partner_001',
        partnerBusinessId: _businessId,
        categoryId: 'cat_2',
        ownerCommissionPct: 20.0,
        partnerCommissionPct: 80.0,
        status: 'active',
        proposedAt: base,
        respondedAt: base.add(const Duration(days: 1)),
        notes: 'Standard revenue split agreement.',
      ),
      // One proposed agreement — shows pending state in the agreements list.
      AgreementModel(
        id: 'agr_mock_002',
        businessId: _businessId,
        ownerUserId: 'usr_owner_001',
        partnerUserId: 'usr_partner_002',
        partnerBusinessId: _businessId,
        categoryId: 'cat_3',
        ownerCommissionPct: 15.0,
        partnerCommissionPct: 85.0,
        status: 'proposed',
        proposedAt: base.add(const Duration(days: 10)),
        notes: 'Awaiting partner confirmation.',
      ),
    ];
  }
}
