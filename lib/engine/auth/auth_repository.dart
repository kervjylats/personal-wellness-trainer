// lib/engine/auth/auth_repository.dart

import 'package:personal_wellness_trainer/data/models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> signIn(String email, String password);

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
    // All optional, and all unused by the existing Owner self-signup
    // screen (which needs none of them — a brand-new business gets a
    // fresh businessId and no partner/category). These exist specifically
    // for accept_invitation_screen.dart's real-mode path: an invited
    // Partner/Staff/Client needs to land in the INVITING business, not a
    // new one of their own, and a Client needs their ownership chain
    // (see mock_team_source.dart's _resolveClientOwnerId) resolved too.
    String? businessId,
    String? role,
    String? categoryId,
    String? primaryPartnerId,
  });

  Future<void> signOut();

  Future<UserProfile?> restoreSession();

  Future<bool> isNewOwner(String userId);

  Future<void> setOnboardingComplete(String userId, {UserProfile? updatedProfile});

  /// ── Smart License Activation Engine ──
  /// Validates an activation key against the active database.
  /// Returns the registered [UserProfile] on success, or null if invalid.
  Future<UserProfile?> activateLicenseKey(String key);
}