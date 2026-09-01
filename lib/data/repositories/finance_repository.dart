// lib/data/repositories/finance_repository.dart
//
// Abstract interface for all finance data operations.
// MockFinanceSource implements this for Phases 1-9.
// SupabaseFinanceSource implements this in Phase 10.
//
// The finance providers talk ONLY to this interface — never to a
// concrete source directly. This is the Repository pattern.

import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';

abstract class FinanceRepository {
  // ── Transactions ─────────────────────────────────────────────────────────────

  /// Returns all transactions for a business, newest first.
  Future<List<TransactionModel>> getTransactions(String businessId);

  /// Returns transactions for a specific user (partner earnings / client payments).
  Future<List<TransactionModel>> getTransactionsForUser(
    String businessId,
    String userId,
  );

  /// Returns the single transaction with the given ID.
  /// Returns null if not found.
  Future<TransactionModel?> getTransaction(String transactionId);

  /// Records a new manual transaction (owner action).
  /// Returns the created [TransactionModel].
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
    String? agreementId,   // NEW
    String? notes,
  });

  /// Updates the status of an existing transaction.
  Future<TransactionModel> updateTransactionStatus(
    String transactionId,
    String newStatus,
  );

  // ── Commissions ───────────────────────────────────────────────────────────────

  /// Returns all commission records for a business (owner view).
  Future<List<CommissionModel>> getCommissions(String businessId);

  /// Returns commission records for a specific partner (partner view).
  Future<List<CommissionModel>> getCommissionsForPartner(
    String businessId,
    String partnerId,
  );

  /// Marks a commission as paid and creates the corresponding transaction.
  Future<CommissionModel> markCommissionPaid(String commissionId);

  /// Records a new pending commission — the real calculation (rate ×
  /// amount, using a specific agreement's actual terms) is the caller's
  /// responsibility; this just persists the already-resolved values.
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
  });
}
