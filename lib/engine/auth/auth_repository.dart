// lib/engine/auth/auth_repository.dart

import 'package:personal_wellness_trainer/data/models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> signIn(String email, String password);

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
    // The ONLY thing the client can hand the server about who this
    // person is becoming — an opaque invite token or activation key
    // code. Everything else (role, business_id, category_id,
    // primary_partner_id for an invite; business_name/primary_color/
    // job_id/plan_tier for an activation key) is resolved SERVER-SIDE
    // from the actual invite_links/activation_keys row this code points
    // to (see handle_new_user() in triggers.sql). A client can no longer
    // just assert its own role/business_id the way earlier versions of
    // this method allowed. Null means a genuine fresh Owner self-signup
    // (SignupScreen, Owner-only) — mints a brand-new free-tier business.
    String? redemptionCode,
  });

  Future<void> signOut();

  Future<UserProfile?> restoreSession();

  Future<bool> isNewOwner(String userId);

  Future<void> setOnboardingComplete(String userId, {UserProfile? updatedProfile});

  /// Persists a plan-tier change (Free Owner → Pro Owner). The tier is
  /// unwritable via the normal table API (RLS + column grants block it, see
  /// schema.sql) — real mode goes through a SECURITY DEFINER RPC
  /// `set_plan_tier`. Mock mode writes the live + persisted profile.
  Future<void> setPlanTier(String userId, String planTier);

  /// Appends to the buyer-visible upgrade history (`upgrade_events` table)
  /// so the buyer can audit who upgraded to Pro and who launched their own
  /// business. Never throws — logging must not block an upgrade already in
  /// progress.
  Future<void> recordUpgradeEvent({
    required String userId,
    String? email,
    required String fromRole,
    required String toRole,
    String? fromTier,
    String? toTier,
    required String businessId,
  });
  // activateLicenseKey() removed — superseded by signUp(redemptionCode:),
  // which handles activation-key redemption correctly (real Supabase
  // Auth account, atomic single-use check, no broken deterministic-UUID
  // profile insert that would fail the auth.users FK constraint). See
  // MarketingLandingScreen / accept_invitation_screen.dart.
}