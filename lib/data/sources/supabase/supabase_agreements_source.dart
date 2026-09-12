// lib/data/sources/supabase/supabase_agreements_source.dart
//
// Real Supabase implementation of AgreementsRepository. proposeAgreement()
// is Owner-gated at both layers — the Dart notifier (agreements_notifier.dart)
// AND the agreements table's own INSERT policy (schema.sql) — so the
// restriction holds even if a client bypassed the app's own UI/logic.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/repositories/agreements_repository.dart';

class SupabaseAgreementsSource implements AgreementsRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<AgreementModel>> getAgreements(String businessId) async {
    final rows = await _db
        .from('agreements')
        .select()
        .eq('business_id', businessId)
        .order('proposed_at', ascending: false);
    return (rows as List)
        .map((r) => AgreementModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

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
    final row = await _db.from('agreements').insert({
      'business_id': businessId,
      'owner_user_id': ownerUserId,
      'partner_user_id': partnerUserId,
      'partner_business_id': partnerBusinessId,
      'category_id': categoryId,
      'owner_commission_pct': ownerCommissionPct,
      'partner_commission_pct': partnerCommissionPct,
      'status': 'proposed',
      if (notes != null) 'notes': notes,
    }).select().single();

    return AgreementModel.fromJson(row);
  }

  @override
  Future<AgreementModel> approveAgreement({
    required String agreementId,
    required String businessId,
  }) async {
    final row = await _db
        .from('agreements')
        .update({
          'status': 'active',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', agreementId)
        .eq('business_id', businessId)
        .select()
        .single();
    return AgreementModel.fromJson(row);
  }

  @override
  Future<AgreementModel> declineAgreement({
    required String agreementId,
    required String businessId,
  }) async {
    final row = await _db
        .from('agreements')
        .update({
          'status': 'declined',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', agreementId)
        .eq('business_id', businessId)
        .select()
        .single();
    return AgreementModel.fromJson(row);
  }

  @override
  Future<AgreementModel> endAgreement({
    required String agreementId,
    required String businessId,
  }) async {
    final row = await _db
        .from('agreements')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', agreementId)
        .eq('business_id', businessId)
        .select()
        .single();
    return AgreementModel.fromJson(row);
  }
}
