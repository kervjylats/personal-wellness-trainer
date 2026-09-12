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