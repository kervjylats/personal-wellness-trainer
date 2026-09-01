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
}