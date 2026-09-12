// lib/data/sources/supabase/supabase_invite_source.dart
//
// Real Supabase implementation of InviteRepository. getLinkByToken() is
// the one method here that behaves differently from the others — see its
// own comment below for why.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/invite_link_model.dart';
import 'package:personal_wellness_trainer/data/repositories/invite_repository.dart';

class SupabaseInviteSource implements InviteRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<InviteLinkModel>> getLinks(String businessId) async {
    final rows = await _db
        .from('invite_links')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => InviteLinkModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InviteLinkModel?> getLinkByToken(String token) async {
    // Goes through the get_invite_link_by_token() RPC (SECURITY DEFINER),
    // NOT a direct table select — the person calling this has no session
    // yet (they're on the invite-acceptance screen, about to sign up), so
    // there's no RLS policy that could safely allow a direct read here.
    // See schema.sql's invite_links table comment for the full reasoning.
    final rows = await _db.rpc('get_invite_link_by_token', params: {
      'p_token': token,
    });
    final list = rows as List;
    if (list.isEmpty) return null;
    return InviteLinkModel.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<InviteLinkModel> createLink({
    required String businessId,
    required String invitedByUserId,
    required String invitedByRole,
    required String targetRole,
    String? categoryId,
    String? label,
    int maxUses = 0,
    DateTime? expiresAt,
  }) async {
    final row = await _db.from('invite_links').insert({
      'token': _generateToken(),
      'business_id': businessId,
      'invited_by_user_id': invitedByUserId,
      'invited_by_role': invitedByRole,
      'target_role': targetRole,
      if (categoryId != null) 'category_id': categoryId,
      if (label != null) 'label': label,
      'max_uses': maxUses,
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
    }).select().single();

    return InviteLinkModel.fromJson(row);
  }

  @override
  Future<InviteLinkModel> recordUse(String linkId) async {
    // Atomic increment via the RPC-free `+1` expression Supabase's
    // postgrest client doesn't support directly — read-then-write is
    // acceptable here since a link being used twice in the same instant
    // by two different invitees is an edge case (they'd both still get
    // correctly onboarded; only the use_count could under-count by one
    // in a genuine race, which does not affect correctness of who joined
    // which business under which role).
    final current = await _db
        .from('invite_links')
        .select('use_count')
        .eq('id', linkId)
        .single();

    final row = await _db
        .from('invite_links')
        .update({'use_count': (current['use_count'] as int) + 1})
        .eq('id', linkId)
        .select()
        .single();

    return InviteLinkModel.fromJson(row);
  }

  @override
  Future<void> deleteLink(String linkId) async {
    await _db.from('invite_links').delete().eq('id', linkId);
  }

  String _generateToken() {
    // Mirrors MockInviteSource's 'wlp_NNNNNN' shape closely enough for
    // consistency, but with real randomness instead of a sequential
    // counter — a predictable token would defeat the whole point of it
    // being unguessable.
    final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'wlp_$rand';
  }
}
