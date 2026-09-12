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
    String businessId,
    String userId,
  ) async {
    final rows = await _db
        .from('transactions')
        .select()
        .eq('business_id', businessId)
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
  }) async {
    final row = await _db.from('transactions').insert({
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
    }).select().single();

    return TransactionModel.fromJson(row);
  }

  @override
  Future<TransactionModel> updateTransactionStatus(
    String transactionId,
    String newStatus,
  ) async {
    final row = await _db
        .from('transactions')
        .update({'status': newStatus})
        .eq('id', transactionId)
        .select()
        .single();
    return TransactionModel.fromJson(row);
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
    String businessId,
    String partnerId,
  ) async {
    final rows = await _db
        .from('commissions')
        .select()
        .eq('business_id', businessId)
        .eq('partner_id', partnerId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => CommissionModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CommissionModel> markCommissionPaid(String commissionId) async {
    final row = await _db.rpc('mark_commission_paid', params: {
      'p_commission_id': commissionId,
    });
    return CommissionModel.fromJson(row as Map<String, dynamic>);
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
    final row = await _db.from('commissions').insert({
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
    }).select().single();

    return CommissionModel.fromJson(row);
  }
}
