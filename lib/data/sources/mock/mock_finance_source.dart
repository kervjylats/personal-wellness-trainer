// lib/data/sources/mock/mock_finance_source.dart

import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/data/repositories/finance_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockFinanceSource with MockSourceMixin implements FinanceRepository {
  static const String _tag = 'MockFinanceSource';
  static const String _currency = r'$';

  static final List<TransactionModel> _transactions = _buildSeedTransactions();
  static final List<CommissionModel> _commissions = _buildSeedCommissions();

  // Shared across instances: resolveFinanceRepository() returns a NEW
  // MockFinanceSource() on every notifier rebuild, so instance-level
  // copies silently discarded recorded payments/commissions (Round 6
  // probe: payment recorded -> invalidateSelf -> fresh instance ->
  // seed-only ledger -> "No transactions yet"). Static like every other
  // mock source's store.
  static final List<TransactionModel> _mutableTransactions =
      List.from(_transactions);
  static final List<CommissionModel> _mutableCommissions =
      List.from(_commissions);

  @override
  Future<List<TransactionModel>> getTransactions(String businessId) async {
    await simulateNetworkDelay();
    AppLogger.debug('MockFinanceSource: getTransactions($businessId)', tag: _tag);
    
    final matches = _mutableTransactions.where((t) => t.businessId == businessId).toList();
    if (matches.isEmpty) {
      // Round 6: no more "clone seed transactions onto whatever business
      // asked" fallback — a brand-new business must start at $0 like a
      // real one, not show money it never earned.
      return <TransactionModel>[];
    }
    return matches..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<TransactionModel>> getTransactionsForUser(String userId) async {
    await simulateNetworkDelay();
    // Keyed by user only: a marketplace payout is booked on the payer's
    // business but must still show in the payee's own history.
    final matches = _mutableTransactions
        .where((t) => t.fromUserId == userId || t.toUserId == userId)
        .toList();

    if (matches.isEmpty) {
      // Round 6: never clone seed money onto a user who never earned it.
      return <TransactionModel>[];
    }
    return matches..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<TransactionModel?> getTransaction(String transactionId) async {
    await simulateNetworkDelay();
    try {
      return _mutableTransactions.firstWhere((t) => t.id == transactionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TransactionModel> recordTransaction({
    required String businessId,
    required double amount,
    required String currencySymbol,
    required String type,
    required String description,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? toUserName,
    String? activityId,
    String? agreementId,
    String? notes,
    String? paymentProvider,
    String? externalRef,
  }) async {
    await simulateNetworkDelay();

    final newTxn = TransactionModel(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      amount: amount,
      currencySymbol: currencySymbol,
      type: type,
      status: 'completed',
      createdAt: DateTime.now(),
      description: description,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUserName,
      toUserName: toUserName,
      activityId: activityId,
      agreementId: agreementId,
      paymentProvider: paymentProvider ?? 'manual',
      externalRef: externalRef,
      notes: notes,
    );

    _mutableTransactions.insert(0, newTxn);
    return newTxn;
  }

  @override
  Future<CommissionModel> recordCommission({
    required String businessId,
    required String agreementId,
    required String partnerId,
    required String partnerName,
    required double amount,
    required String currencySymbol,
    required double rate,
    required String description,
    String? activityId,
  }) async {
    await simulateNetworkDelay();

    final commission = CommissionModel(
      id: 'com_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      agreementId: agreementId,
      partnerId: partnerId,
      partnerName: partnerName,
      amount: amount,
      currencySymbol: currencySymbol,
      rate: rate,
      rateType: 'percentage',
      status: 'pending',
      createdAt: DateTime.now(),
      activityId: activityId,
      description: description,
    );
    _mutableCommissions.insert(0, commission);
    return commission;
  }

  @override
  Future<TransactionModel> updateTransactionStatus(
    String transactionId,
    String newStatus,
  ) async {
    await simulateNetworkDelay();

    final index = _mutableTransactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) throw Exception('Transaction $transactionId not found');

    final updated = _mutableTransactions[index].copyWith(status: newStatus);
    _mutableTransactions[index] = updated;
    return updated;
  }

  @override
  Future<List<CommissionModel>> getCommissions(String businessId) async {
    await simulateNetworkDelay();
    final matches = _mutableCommissions
        .where((c) => c.businessId == businessId)
        .toList();

    if (matches.isEmpty) {
      // Round 6: brand-new business has no commissions yet.
      return <CommissionModel>[];
    }
    return matches..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<CommissionModel>> getCommissionsForPartner(
      String partnerId) async {
    await simulateNetworkDelay();
    // Keyed by payee only: on a marketplace collab the debtor's business
    // differs from the partner's, and the partner must still see what's
    // owed to them (Phase 10: Supabase RLS keys the same way).
    final matches =
        _mutableCommissions.where((c) => c.partnerId == partnerId).toList();

    if (matches.isEmpty) {
      // Round 6: no seed commissions mapped onto partners who never
      // earned them — a fresh partner starts at $0.
      return <CommissionModel>[];
    }
    return matches..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<CommissionModel> markCommissionPaid(
    String commissionId, {
    String? payerUserId,
    String? payerName,
  }) async {
    await simulateNetworkDelay();

    final index = _mutableCommissions.indexWhere((c) => c.id == commissionId);
    if (index == -1) throw Exception('Commission $commissionId not found');

    final txnId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    final commission = _mutableCommissions[index];
    final updated = commission.copyWith(
      status: 'paid',
      transactionId: txnId,
      paidAt: DateTime.now(),
    );
    _mutableCommissions[index] = updated;

    _mutableTransactions.insert(
      0,
      TransactionModel(
        id: txnId,
        businessId: commission.businessId,
        amount: commission.amount,
        currencySymbol: commission.currencySymbol,
        type: 'commission',
        status: 'completed',
        createdAt: DateTime.now(),
        description: 'Commission payout to ${commission.partnerName}',
        fromUserId: payerUserId,
        fromUserName: payerName,
        toUserId: commission.partnerId,
        toUserName: commission.partnerName,
        commissionId: commissionId,
        agreementId: commission.agreementId,
        paymentProvider: 'manual',
      ),
    );

    return updated;
  }

  static List<TransactionModel> _buildSeedTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'txn_001',
        businessId: 'biz_mock_001',
        amount: 120.00,
        currencySymbol: _currency,
        type: 'payment',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 1)), 
        description: 'Service payment',
        fromUserId: 'usr_client_001',
        fromUserName: 'Sam Client',
        toUserId: 'usr_owner_001',
        toUserName: 'Alex Owner',
        paymentProvider: 'manual',
      ),
      TransactionModel(
        id: 'txn_002',
        businessId: 'biz_mock_001',
        amount: 80.00,
        currencySymbol: _currency,
        type: 'payment',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 3)),
        description: 'Service payment',
        fromUserId: 'usr_client_001',
        fromUserName: 'Sam Client',
        toUserId: 'usr_owner_001',
        toUserName: 'Alex Owner',
        paymentProvider: 'manual',
      ),
      TransactionModel(
        id: 'txn_003',
        businessId: 'biz_mock_001',
        amount: 18.00,
        currencySymbol: _currency,
        type: 'commission',
        status: 'completed',
        createdAt: now.subtract(const Duration(days: 3)),
        description: 'Commission payout',
        fromUserId: 'usr_owner_001',
        fromUserName: 'Alex Owner',
        toUserId: 'usr_partner_001',
        toUserName: 'Jordan Associate',
        commissionId: 'com_001',
        agreementId: 'agr_mock_001',
        paymentProvider: 'manual',
      ),
    ];
  }

  static List<CommissionModel> _buildSeedCommissions() {
    final now = DateTime.now();
    return [
      CommissionModel(
        id: 'com_001',
        businessId: 'biz_mock_001',
        agreementId: 'agr_mock_001',
        partnerId: 'usr_partner_001',
        partnerName: 'Jordan Associate',
        amount: 18.00,
        currencySymbol: _currency,
        rate: 15.0,
        rateType: 'percentage',
        status: 'paid',
        createdAt: now.subtract(const Duration(days: 3)),
        transactionId: 'txn_003',
        description: 'Commission on service payment txn_002',
        paidAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}