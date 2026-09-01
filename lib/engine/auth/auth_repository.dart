// lib/engine/auth/auth_repository.dart

import 'package:personal_wellness_trainer/data/models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> signIn(String email, String password);

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
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