// lib/data/repositories/agreements_repository.dart

import 'package:personal_wellness_trainer/data/models/agreement_model.dart';

abstract class AgreementsRepository {
  Future<List<AgreementModel>> getAgreements(String businessId);

  Future<AgreementModel> proposeAgreement({
    required String businessId,
    required String ownerUserId,
    required String partnerUserId,
    required String partnerBusinessId,
    required String categoryId,
    required double ownerCommissionPct,
    required double partnerCommissionPct,
    String? notes,
  });

  Future<AgreementModel> approveAgreement({
    required String agreementId,
    required String businessId,
  });

  Future<AgreementModel> declineAgreement({
    required String agreementId,
    required String businessId,
  });

  Future<AgreementModel> endAgreement({
    required String agreementId,
    required String businessId,
  });

  /// Marketplace collab acceptance. Creates BOTH sides of the agreement in
  /// one unit of work: the accepter's copy (status 'active', split in the
  /// accepter's favour) and the original sender's copy (status 'proposed',
  /// swapped split). Returns the accepter's copy — the one the calling
  /// UI/State must render and cache.
  ///
  /// Mock replicates the old three-step propose→approve→propose flow
  /// in-memory; Supabase goes through the `create_agreement_pair`
  /// SECURITY DEFINER RPC because the sender-side INSERT is cross-tenant
  /// and blocked by RLS for the accepting user.
  Future<AgreementModel> createMutualAgreementPair({
    required String receiverUserId,
    required String receiverBusinessId,
    required String senderUserId,
    required String senderBusinessId,
    required String receiverSideCategoryId,
    required String senderSideCategoryId,
    required double receiverOwnerPct,
    required double receiverPartnerPct,
    String? notes,
  });
}