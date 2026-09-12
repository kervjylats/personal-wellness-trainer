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
// ── inviteMember() IS NOT IMPLEMENTED — READ THIS BEFORE CALLING IT ──
// profiles.user_id has a hard foreign-key constraint to auth.users. A
// team member cannot exist without a real Supabase Auth account already
// existing for them. But TeamRepository.inviteMember()'s signature never
// receives an invitee user_id — it was designed around MockTeamSource's
// single-step model, where the mock invents a whole new identity out of
// nothing because it has no real auth system underneath it.
//
// In real Supabase mode, accepting an invite genuinely has to be a
// TWO-step flow: (1) the invitee signs up for real via
// Supabase Auth (creating their own auth.users row, which the
// on_auth_user_created trigger turns into a fresh profiles row with a
// default role/business_id), then (2) something reassigns that row's
// role/business_id/primary_partner_id to match the actual invite they
// clicked. Step 2 is what a real inviteMember() should do — but it needs
// an inviteeUserId parameter that doesn't exist on this interface yet,
// and accept_invitation_screen.dart itself doesn't call Supabase Auth at
// all currently (it's fully mock-shaped — see its own file). Fixing
// that screen is a separate piece of work from this repository file.
//
// Rather than silently insert a row with a fabricated user_id (which
// would just hard-fail at the database level against the FK constraint,
// or worse, succeed with a `deterministicUuid`-style fake id that never
// matches a real signed-in user, quietly breaking auth), this throws a
// clear, actionable error so the gap is visible instead of a confusing
// runtime crash somewhere else.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/repositories/team_repository.dart';

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
    throw UnimplementedError(
      'SupabaseTeamSource.inviteMember() needs accept_invitation_screen.dart '
      'to actually create a real Supabase Auth account first (it currently '
      "doesn't), and this interface needs an inviteeUserId parameter to know "
      'which resulting profiles row to reassign. See this file\'s header '
      'comment for the full explanation — this is a real, flagged gap, not '
      'an oversight to work around.',
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
    // Soft-delete, matching the RLS policy's `is_active = true` read
    // filter — a removed member's row stays (transactions/history still
    // reference it via FK) but stops showing up anywhere the app reads
    // the roster from.
    await _db
        .from('profiles')
        .update({'is_active': false})
        .eq('user_id', memberId)
        .eq('business_id', businessId);
    return true;
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
