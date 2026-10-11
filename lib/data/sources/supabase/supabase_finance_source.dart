// lib/data/sources/supabase/supabase_finance_source.dart
//
// Real Supabase implementation of FinanceRepository. markCommissionPaid()
// wraps the mark_commission_paid() Postgres function (triggers.sql)
// rather than doing the commission-update + transaction-insert as two
// separate client calls — see that function's own comment for why this
// has to be atomic.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/data/repositories/finance_repository.dart';

class SupabaseFinanceSource implements FinanceRepository {
  final SupabaseClient _db = Supabase.instance.client;

  // ── Transactions ─────────────────────────────────────────────────────────

  @override
  Future<List<TransactionModel>> getTransactions(String businessId) async {
    final rows = await _db
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => TransactionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForUser(
    String userId,
  ) async {
    // Keyed by user only — a cross-tenant payout still belongs in the
    // payee's own history (row-level access is enforced by RLS).
    final rows = await _db
        .from('transactions')
        .select()
        .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => TransactionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TransactionModel?> getTransaction(String transactionId) async {
    final rows = await _db
        .from('transactions')
        .select()
        .eq('id', transactionId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return TransactionModel.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<void> recordTransaction({
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
    // M8: NO `.select().single()` here. transactions' INSERT policy
    // (any member of business_id) is wider than its SELECT policy
    // (from/to/owner) — Postgres applies SELECT policies to RETURNING,
    // so a partner/staff-side insert would commit but return zero rows
    // and .single() would throw PGRST116. Write-only; callers refresh
    // through their notifier.
    await _db.from('transactions').insert({
      'business_id': businessId,
      'amount': amount,
      'currency_symbol': currencySymbol,
      'type': type,
      'status': 'completed',
      'description': description,
      if (fromUserId != null) 'from_user_id': fromUserId,
      if (toUserId != null) 'to_user_id': toUserId,
      if (fromUserName != null) 'from_user_name': fromUserName,
      if (toUserName != null) 'to_user_name': toUserName,
      if (activityId != null) 'activity_id': activityId,
      if (agreementId != null) 'agreement_id': agreementId,
      if (notes != null) 'notes': notes,
      if (paymentProvider != null) 'payment_provider': paymentProvider,
      if (externalRef != null) 'external_ref': externalRef,
    });
  }

  @override
  Future<void> updateTransactionStatus(
    String transactionId,
    String newStatus,
  ) async {
    // M8: same RETURNING asymmetry as recordTransaction — update without
    // asking for the row back (a caller outside the row's SELECT policy
    // would get PGRST116 after the update already committed).
    await _db
        .from('transactions')
        .update({'status': newStatus})
        .eq('id', transactionId);
  }

  // ── Commissions ──────────────────────────────────────────────────────────

  @override
  Future<List<CommissionModel>> getCommissions(String businessId) async {
    final rows = await _db
        .from('commissions')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => CommissionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CommissionModel>> getCommissionsForPartner(
      String partnerId) async {
    // Keyed by payee only (marketplace collabs span businesses; RLS
    // still scopes rows to the caller).
    final rows = await _db
        .from('commissions')
        .select()
        .eq('partner_id', partnerId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => CommissionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CommissionModel> markCommissionPaid(
    String commissionId, {
    String? payerUserId,
    String? payerName,
  }) async {
    // The atomic SQL function owns the payout row (including its payer
    // columns) — Phase 10: extend mark_commission_paid() to accept
    // p_payer_user_id/p_payer_name so these named params can flow
    // through; until then the RPC keeps its own bookkeeping.
    final row = await _db.rpc('mark_commission_paid', params: {
      'p_commission_id': commissionId,
    });
    return CommissionModel.fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<void> recordCommission({
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
    // M8: no `.select().single()` — commissions' SELECT policy (owner of
    // business_id, or the commission's partner_id) is narrower than its
    // INSERT policy (any member of business_id), so a partner-side
    // insert's RETURNING would come back empty and .single() would throw
    // after the write already committed.
    await _db.from('commissions').insert({
      'business_id': businessId,
      'agreement_id': agreementId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'amount': amount,
      'currency_symbol': currencySymbol,
      'rate': rate,
      'rate_type': 'percentage',
      'status': 'pending',
      'description': description,
      if (activityId != null) 'activity_id': activityId,
    });
  }

  @override
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
  }) async {
    // One atomic SECURITY DEFINER transaction: sale on the SELLER's
    // ledger + referral commission on the coach's. The RPC derives the
    // buyer's display name, both ledgers, and the commission rate from
    // the agreement row server-side — the extra client params are for
    // the mock path only (no cross-source agreement lookup there).
    // The sale INSERT is cross-tenant and RLS-blocked for direct writes.
    // See triggers.sql `purchase_from_partner()`.
    await _db.rpc('purchase_from_partner', params: {
      'p_buyer_user_id': buyerUserId,
      'p_agreement_id': agreementId,
      'p_item_title': itemTitle,
      'p_amount': amount,
      'p_currency': currency,
      'p_partner_name': partnerName,
    });
  }
}
