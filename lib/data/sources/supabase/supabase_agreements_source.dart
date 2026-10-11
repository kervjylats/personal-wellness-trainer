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
          'responded_at': DateTime.now().toUtc().toIso8601String(),
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
          'responded_at': DateTime.now().toUtc().toIso8601String(),
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
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', agreementId)
        .eq('business_id', businessId)
        .select()
        .single();
    return AgreementModel.fromJson(row);
  }

  @override
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
  }) async {
    // One atomic SECURITY DEFINER transaction writes both the receiver's
    // ('active') and the original sender's ('proposed') agreement rows.
    // The sender-side INSERT is cross-tenant — the accepting user's session
    // cannot satisfy the agreements RLS policy on someone else's business,
    // so both rows must be written by the definer function.
    // See triggers.sql `create_agreement_pair()`.
    final receiverSideId = await _db.rpc('create_agreement_pair', params: {
      'p_receiver_user_id': receiverUserId,
      'p_receiver_business_id': receiverBusinessId,
      'p_sender_user_id': senderUserId,
      'p_sender_business_id': senderBusinessId,
      'p_receiver_side_category_id': receiverSideCategoryId,
      'p_sender_side_category_id': senderSideCategoryId,
      'p_receiver_owner_pct': receiverOwnerPct,
      'p_receiver_partner_pct': receiverPartnerPct,
      'p_notes': notes,
    });

    // Re-select the receiver's copy so the caller gets the full row (the
    // RPC returns only the new id).
    final row = await _db
        .from('agreements')
        .select()
        .eq('id', receiverSideId as String)
        .single();
    return AgreementModel.fromJson(row);
  }
}
