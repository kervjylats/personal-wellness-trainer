// lib/data/sources/supabase/supabase_team_source.dart
//
// Real Supabase implementation of TeamRepository. Was previously an
// UnimplementedError throw in team_notifier.dart's provider ("Phase 10
// only") — that's the gap this file fills.
//
// IMPORTANT — there is no separate "team_members" table. The team roster
// and the auth profile are the SAME row: public.profiles (see
// schema.sql). An Owner, Partner, Staff, or Client is just a profiles row
// with a given `role`. TeamMemberModel and UserProfile are two different
// Dart views over that one table — this file maps profiles rows to
// TeamMemberModel the same way SupabaseAuthSource maps them to
// UserProfile.
//
// ── inviteMember() — the invite-LINK path (M11) ──────────────────────────────
// There is no separate "team_members" table. The team roster and the auth
// profile are the SAME row: public.profiles (see schema.sql). A profiles
// row has a hard foreign key to auth.users, so a team member cannot exist
// until the invitee creates their own Supabase Auth account.
//
// In real mode, "inviting" someone therefore means creating an INVITE
// LINK — the invite_links row the invitee redeems through
// accept_invitation_screen, whose handle_new_user() trigger then resolves
// role/business/category/referral-chain server-side. That is what this
// method does now: it creates the link and returns a PENDING (not
// persisted) TeamMemberModel carrying the link's token as the
// acknowledgment, so callers get the same member-shaped result the mock
// path returns. The pending model's userId is prefixed 'pending_' and its
// inviteToken is set — it is an in-memory acknowledgment only, never a
// profiles row, and disappears on the next roster refresh (by which time
// either the invitee has signed up — a real row — or the invite is still
// outstanding in the links list).
//
// What it deliberately does NOT do: insert a profiles row with a
// fabricated user_id. That either hard-fails the auth.users FK or
// succeeds as a phantom identity that no real sign-in ever matches.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/repositories/team_repository.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_invite_source.dart';

class SupabaseTeamSource implements TeamRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<TeamMemberModel>> getMembers(
    String businessId, {
    String? role,
  }) async {
    var query = _db.from('profiles').select().eq('business_id', businessId);
    if (role != null) {
      query = query.eq('role', role);
    }
    final rows = await query;
    return (rows as List)
        .map((r) => _fromProfileRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeamMemberModel> inviteMember({
    required String businessId,
    required String invitedByUserId,
    required String role,
    required String displayName,
    String? email,
    String? categoryId,
  }) async {
    // M11: real-mode invite = create the invite link (see this file's
    // header). invited_by_role is NOT NULL on invite_links and the
    // caller's own role isn't in the method signature, so read it off
    // the caller's profiles row — always readable, the caller is a
    // member of their own business.
    final caller = await _db
        .from('profiles')
        .select('role')
        .eq('user_id', invitedByUserId)
        .single();

    final link = await SupabaseInviteSource().createLink(
      businessId: businessId,
      invitedByUserId: invitedByUserId,
      invitedByRole: caller['role'] as String,
      targetRole: role,
      categoryId: categoryId,
      label: displayName,
    );

    return TeamMemberModel(
      userId: 'pending_${link.token}',
      businessId: businessId,
      role: role,
      displayName: displayName,
      isActive: false,
      joinedAt: DateTime.now(),
      featureToggles: const {},
      categoryId: categoryId,
      email: email,
      inviteToken: link.token,
    );
  }

  @override
  Future<TeamMemberModel> toggleFeature({
    required String memberId,
    required String businessId,
    required String featureKey,
    required bool value,
  }) async {
    // feature_toggles is a jsonb map on the row — merge, don't overwrite,
    // so toggling one feature doesn't clobber the others already set.
    final current = await _db
        .from('profiles')
        .select('feature_toggles')
        .eq('user_id', memberId)
        .eq('business_id', businessId)
        .single();

    final toggles = Map<String, dynamic>.from(
      current['feature_toggles'] as Map<String, dynamic>? ?? {},
    );
    toggles[featureKey] = value;

    final updated = await _db
        .from('profiles')
        .update({'feature_toggles': toggles})
        .eq('user_id', memberId)
        .eq('business_id', businessId)
        .select()
        .single();

    return _fromProfileRow(updated);
  }

  @override
  Future<bool> removeMember({
    required String memberId,
    required String businessId,
  }) async {
    // Soft-delete, matching the RLS read filter's `is_active = true`
    // default — a removed member's row stays (transactions/history still
    // reference it via FK) but stops showing up anywhere the app reads
    // the roster from. Note the profiles SELECT policy now carries a
    // self-exception (M10): the removed user can still read their OWN
    // row, so sign-in fails with a clear message instead of a PGRST116
    // crash — but everyone else's reads keep filtering on is_active.
    // This write works because is_active is in the column grant and the
    // owner UPDATE policy matches by business_id regardless of the
    // target's is_active; recovery goes through set_member_active()
    // (getInactiveMembers/reactivateMember below) because the owner can
    // no longer SELECT the row to target it directly.
    await _db
        .from('profiles')
        .update({'is_active': false})
        .eq('user_id', memberId)
        .eq('business_id', businessId);
    return true;
  }

  @override
  Future<List<TeamMemberModel>> getInactiveMembers(String businessId) async {
    // Plain .from('profiles') can't see inactive rows (RLS), so the owner
    // lists them through the owner-gated SECURITY DEFINER function.
    // See triggers.sql get_deactivated_members() / M10.
    final rows = await _db.rpc('get_deactivated_members', params: {
      'p_business_id': businessId,
    }) as List;
    return rows
        .map((r) => _fromProfileRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> reactivateMember({
    required String memberId,
    required String businessId,
  }) async {
    // SECURITY DEFINER (owner-gated + business-scoped): the row itself is
    // invisible to RLS reads, so the owner can't target it with a raw
    // update. See triggers.sql set_member_active() / M10.
    final restored = await _db.rpc('set_member_active', params: {
      'p_user_id': memberId,
      'p_business_id': businessId,
      'p_active': true,
    });
    return restored == true;
  }

  @override
  Future<void> migratePartnerClients(
    String partnerId,
    String newBusinessId,
  ) async {
    // Wraps the existing migrate_partner_clients() Postgres function
    // (supabase/triggers.sql) rather than re-implementing the two-table
    // update (profiles + transactions) here in Dart — the SQL function
    // is the single source of truth for this logic in real mode.
    await _db.rpc('migrate_partner_clients', params: {
      'partner_id': partnerId,
      'new_business_id': newBusinessId,
    });
  }

  @override
  Future<void> updateBusinessFeatures(
    String ownerUserId, {
    bool? partnersEnabled,
    bool? marketplaceEnabled,
    bool? agreementsEnabled,
  }) async {
    final updates = <String, dynamic>{};
    if (partnersEnabled != null) updates['partners_enabled'] = partnersEnabled;
    if (marketplaceEnabled != null) updates['marketplace_enabled'] = marketplaceEnabled;
    if (agreementsEnabled != null) updates['agreements_enabled'] = agreementsEnabled;
    if (updates.isEmpty) return;

    await _db.from('profiles').update(updates).eq('user_id', ownerUserId);
  }

  // ── Mapping ──────────────────────────────────────────────────────────────

  TeamMemberModel _fromProfileRow(Map<String, dynamic> r) {
    return TeamMemberModel(
      userId: r['user_id'] as String,
      businessId: r['business_id'] as String,
      role: r['role'] as String,
      displayName: r['display_name'] as String? ?? '',
      isActive: r['is_active'] as bool? ?? true,
      joinedAt: DateTime.parse(r['joined_at'] as String),
      featureToggles: Map<String, bool>.from(
        (r['feature_toggles'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as bool)),
      ),
      categoryId: (r['category_id'] ?? r['selected_category']) as String?,
      email: r['email'] as String?,
      primaryPartnerId: r['primary_partner_id'] as String?,
      partnersEnabled: r['partners_enabled'] as bool?,
      marketplaceEnabled: r['marketplace_enabled'] as bool?,
      agreementsEnabled: r['agreements_enabled'] as bool?,
    );
  }
}
