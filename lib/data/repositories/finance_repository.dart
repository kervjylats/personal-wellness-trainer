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

  /// Returns transactions where this user is a party (partner earnings /
  /// client payments). Keyed by user, not business — a cross-tenant
  /// payout still belongs in the payee's own history.
  Future<List<TransactionModel>> getTransactionsForUser(String userId);

  /// Returns the single transaction with the given ID.
  /// Returns null if not found.
  Future<TransactionModel?> getTransaction(String transactionId);

  /// Records a new manual transaction (owner action).
  /// [paymentProvider]/[externalRef] mimic a real payment processor's
  /// receipt ('card' → 'py_...', 'bank' → 'trf_...'); null keeps the
  /// default 'manual' bookkeeping entry.
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
    String? paymentProvider,
    String? externalRef,
  });

  /// Updates the status of an existing transaction.
  Future<TransactionModel> updateTransactionStatus(
    String transactionId,
    String newStatus,
  );

  // ── Commissions ───────────────────────────────────────────────────────────────

  /// Returns all commission records for a business (owner view).
  Future<List<CommissionModel>> getCommissions(String businessId);

  /// Returns commission records where this user is the payee (partner
  /// view). Keyed by [partnerId] only — a marketplace partner belongs to
  /// a different business than the debtor, and money owed to *you* must
  /// be visible to you regardless of whose ledger books it.
  Future<List<CommissionModel>> getCommissionsForPartner(String partnerId);

  /// Marks a commission as paid and creates the corresponding payout
  /// transaction. [payerUserId]/[payerName] identify who sent the money
  /// (falls back to null on older records).
  Future<CommissionModel> markCommissionPaid(
    String commissionId, {
    String? payerUserId,
    String? payerName,
  });

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

  /// Client buys from a partner business via an active agreement. Books the
  /// sale on the SELLER's ledger and the referral commission on the COACH's
  /// as ONE unit of work. Supabase goes through the `purchase_from_partner`
  /// SECURITY DEFINER RPC (triggers.sql) — the sale INSERT is cross-tenant
  /// (partner business ≠ buyer's session) and RLS-blocked for direct
  /// client writes, and the commission amount is computed server-side from
  /// the agreement's actual owner_commission_pct; the real path ignores the
  /// ledger-id/percent params and derives everything from the agreement row.
  /// Mock mode has no cross-source agreement lookup, so it books into the
  /// ledgers the caller passes through.
  Future<void> purchaseFromPartner({
    required String buyerUserId,
    String? buyerName,
    required String buyerCoachBusinessId,
    required String agreementId,
    required String partnerBusinessId,
    required String partnerUserId,
    required String partnerName,
    required String itemTitle,
    required double amount,
    required String currency,
    required double ownerCommissionPct,
  });
}
