// lib/data/repositories/team_repository.dart

import 'package:personal_wellness_trainer/data/models/team_member_model.dart';

abstract class TeamRepository {
  Future<List<TeamMemberModel>> getMembers(
    String businessId, {
    String? role,
  });

  Future<TeamMemberModel> inviteMember({
    required String businessId,
    required String invitedByUserId,
    required String role,
    required String displayName,
    String? email,
    String? categoryId,
  });

  Future<TeamMemberModel> toggleFeature({
    required String memberId,
    required String businessId,
    required String featureKey,
    required bool value,
  });

  Future<bool> removeMember({
    required String memberId,
    required String businessId,
  });

  /// M10 recovery: lists the business's deactivated (is_active = false)
  /// members so the owner has any way to reach the restore action — the
  /// profiles SELECT policy hides inactive rows from plain roster
  /// queries. Supabase wraps the owner-gated `get_deactivated_members`
  /// SECURITY DEFINER function (triggers.sql); mock returns the rows its
  /// soft-delete removal left behind.
  Future<List<TeamMemberModel>> getInactiveMembers(String businessId);

  /// Reverses [removeMember] — sets the member's is_active back to true.
  /// Without this, one tap of "Remove" was a permanent, unrecoverable
  /// lockout (M10): no code path anywhere ever wrote is_active = true.
  /// Supabase wraps the owner-gated `set_member_active` SECURITY DEFINER
  /// function (triggers.sql) — the raw table update can't be listed or
  /// targeted by the owner once RLS hides the row.
  Future<bool> reactivateMember({
    required String memberId,
    required String businessId,
  });

  /// Moves a Partner's own invited clients (and any pending transactions
  /// tied to them) over to the Partner's new independent businessId once
  /// they upgrade to Pro. In Supabase mode this wraps the existing
  /// `migrate_partner_clients` Postgres function (see triggers.sql) rather
  /// than re-implementing the logic in Dart.
  Future<void> migratePartnerClients(String partnerId, String newBusinessId);

  /// Owner-only. Persists the business-wide Partnerships/Marketplace/
  /// Agreements toggles (see business_features_provider.dart). Pass only
  /// the flags that changed — omitted ones are left untouched.
  Future<void> updateBusinessFeatures(
    String ownerUserId, {
    bool? partnersEnabled,
    bool? marketplaceEnabled,
    bool? agreementsEnabled,
  });
}