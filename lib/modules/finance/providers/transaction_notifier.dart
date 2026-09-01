// lib/modules/finance/providers/transaction_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/data/repositories/finance_repository.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/commission_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_repo_resolver.dart';
import 'package:personal_wellness_trainer/modules/discover/providers/partner_offers_provider.dart';

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  TransactionNotifier.new,
  dependencies: [authNotifierProvider],
);

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  static const String _tag = 'TransactionNotifier';
  late FinanceRepository _repo; // ◄ Fixed: Removed 'final' to allow re-initialization on re-build

  @override
  Future<List<TransactionModel>> build() async {
    try {
      _repo = resolveFinanceRepository();
      final authState = ref.watch(authNotifierProvider);
      if (authState is! AuthAuthenticated) return [];

      final profile = authState.profile;
      final role    = AppRole.fromString(profile.role);

      AppLogger.debug('TransactionNotifier: loading for ${role.value}', tag: _tag);

      if (role.isOwner)   return await _repo.getTransactions(profile.businessId);
      if (role.isPartner) return await _repo.getTransactionsForUser(profile.businessId, profile.userId);
      if (role.isClient)  return await _repo.getTransactionsForUser(profile.businessId, profile.userId);
      return [];
    } catch (e, st) {
      AppLogger.error(
        'TransactionNotifier build failed critically. Check logs.',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return []; 
    }
  }

  Future<bool> recordManualTransaction({
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
    ref.read(financeActionErrorProvider.notifier).state = null;
    try {
      await _repo.recordTransaction(
        businessId:    businessId,
        amount:        amount,
        currencySymbol: currencySymbol,
        type:          type,
        description:   description,
        fromUserId:    fromUserId,
        toUserId:      toUserId,
        fromUserName:  fromUserName,
        toUserName:    toUserName,
        activityId:    activityId,
        agreementId:   agreementId,
        notes:         notes,
      );
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('TransactionNotifier: recordManualTransaction failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(financeActionErrorProvider.notifier).state =
          'Failed to record transaction. Please try again.';
      return false;
    }
  }

  Future<bool> updateStatus(String transactionId, String newStatus) async {
    ref.read(financeActionErrorProvider.notifier).state = null;
    try {
      await _repo.updateTransactionStatus(transactionId, newStatus);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('TransactionNotifier: updateStatus failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(financeActionErrorProvider.notifier).state =
          'Failed to update transaction. Please try again.';
      return false;
    }
  }

  /// A client buying a catalog item from a partner business their coach
  /// has an active agreement with. Records the purchase, then the
  /// resulting commission — calculated from THIS SPECIFIC agreement's
  /// own ownerCommissionPct, never a guessed or hardcoded rate.
  ///
  /// The purchase itself is booked under the PARTNER's own business
  /// (agreement.partnerBusinessId) — they're the actual seller, so it's
  /// their revenue. The commission is booked under the CLIENT's own
  /// coach's business — that's the referral fee they earned. Writing to
  /// another tenant's ledger only works here because mock mode shares
  /// one in-memory store; see createMutualAgreementFromRequest's Phase
  /// 10 note for the same caveat.
  ///
  /// SIMPLIFICATION: both records reference agreement.id — the
  /// REFERRING coach's own copy of the agreement, not the partner's
  /// separate copy of it (which this flow has no read access to). Good
  /// enough to trace "which relationship generated this" for now; a
  /// real reconciliation system would need the partner's own copy too.
  Future<bool> purchaseFromPartner({
    required PartnerOffer offer,
    required CatalogItemModel item,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return false;

    final agreement = offer.agreement;
    ref.read(financeActionErrorProvider.notifier).state = null;
    try {
      await _repo.recordTransaction(
        businessId: agreement.partnerBusinessId,
        amount: item.price,
        currencySymbol: item.currency,
        type: 'payment',
        description: 'Sold "${item.title}" via partner referral',
        fromUserId: auth.profile.userId,
        fromUserName: auth.profile.displayName,
        toUserId: agreement.partnerUserId,
        agreementId: agreement.id,
      );

      final commissionAmount =
          item.price * (agreement.ownerCommissionPct / 100);
      if (commissionAmount > 0) {
        await _repo.recordCommission(
          businessId: auth.profile.businessId,
          agreementId: agreement.id,
          partnerId: agreement.partnerUserId,
          partnerName: offer.partnerBusinessName,
          amount: commissionAmount,
          currencySymbol: item.currency,
          rate: agreement.ownerCommissionPct,
          description: 'Referral commission on "${item.title}"',
        );
      }

      ref.invalidateSelf();
      ref.invalidate(commissionNotifierProvider);
      AppLogger.info(
          'purchaseFromPartner: ${item.id} via agreement ${agreement.id}',
          tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('TransactionNotifier: purchaseFromPartner failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(financeActionErrorProvider.notifier).state =
          'Could not complete the purchase. Please try again.';
      return false;
    }
  }
}
