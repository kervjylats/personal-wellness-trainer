// lib/data/sources/mock/mock_auth_source.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_profiles.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_repository.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockAuthSource with MockSourceMixin implements AuthRepository {
  static const String _tag = 'MockAuthSource';

  static const String _kSessionEmail = 'ae_mock_session_email';
  static String _kOnboardingDone(String userId) => 'ae_mock_onboarding_done_$userId';
  static String _kSignedUpEmail(String userId) => 'ae_mock_signed_up_email_$userId';
  static String _kProfileJson(String email) => 'ae_mock_profile_json_$email';

  static final Map<String, UserProfile> _signedUpProfiles = {};

  @override
  Future<UserProfile> signIn(String email, String password) async {
    if (email.trim().isEmpty) throw Exception('Email address is required');
    if (password.isEmpty) throw Exception('Password is required');

    AppLogger.info('Mock sign-in attempt for "$email"', tag: _tag);
    await simulateNetworkDelay();

    final trimmed = email.trim().toLowerCase();

    final inMemory = _signedUpProfiles[trimmed];
    if (inMemory != null) {
      await _saveSession(trimmed);
      return inMemory;
    }

    final fromPrefs = await _loadPersistedProfile(trimmed);
    if (fromPrefs != null) {
      _signedUpProfiles[trimmed] = fromPrefs;
      await _saveSession(trimmed);
      return fromPrefs;
    }

    // Only the 4 recognized mock test accounts can sign in via the
    // email/password form. Any other email (that didn't sign up above)
    // is an invalid-credentials error.
    //
    // Without this check, MockProfiles.getProfileByEmail's "any other
    // email → client role" fallback would let ANY email/password combo
    // sign in successfully — including genuinely wrong credentials —
    // which is incorrect even for a mock.
    final isRecognized = trimmed.startsWith(AppConstants.mockOwnerPrefix) ||
        trimmed.startsWith(AppConstants.mockPartnerPrefix) ||
        trimmed.startsWith(AppConstants.mockStaffPrefix) ||
        trimmed.startsWith(AppConstants.mockClientPrefix);

    if (!isRecognized) {
      throw Exception('Invalid email or password.');
    }

    final profile = await MockProfiles.getProfileByEmail(email);
    if (profile == null) throw Exception('Sign-in failed. Please try again.');

    await _saveSession(email);
    return profile;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) throw Exception('Email address is required');
    if (password.length < AppConstants.minPasswordLength) {
      throw Exception('Password must be at least ${AppConstants.minPasswordLength} characters');
    }
    if (displayName.trim().isEmpty) throw Exception('Display name is required');

    AppLogger.info('Mock sign-up for "$trimmedEmail"', tag: _tag);
    await simulateNetworkDelay();

    final reservedPrefixes = ['owner@', 'partner@', 'staff@', 'client@'];
    for (final prefix in reservedPrefixes) {
      if (trimmedEmail.startsWith(prefix)) {
        throw Exception('This email is reserved for testing. Please use a different email.');
      }
    }

    if (_signedUpProfiles.containsKey(trimmedEmail)) {
      throw Exception('An account with this email already exists.');
    }
    final alreadyPersisted = await _loadPersistedProfile(trimmedEmail);
    if (alreadyPersisted != null) {
      throw Exception('An account with this email already exists.');
    }

    final userId = 'usr_owner_signup_${DateTime.now().millisecondsSinceEpoch}';
    final profile = UserProfile(
      userId: userId,
      businessId: 'biz_${DateTime.now().millisecondsSinceEpoch}',
      role: AppConstants.roleOwner,
      displayName: displayName.trim(),
      email: trimmedEmail,
      joinedAt: DateTime.now(),
      isActive: true,
      businessName: displayName.trim(),
      planTier: 'free',
    );

    _signedUpProfiles[trimmedEmail] = profile;
    await _persistProfile(profile);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSignedUpEmail(userId), trimmedEmail);
    await _saveSession(trimmedEmail);

    AppLogger.info('Mock sign-up complete: $userId', tag: _tag);
    return profile;
  }

  @override
  Future<void> signOut() async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionEmail);
    AppLogger.info('Mock sign-out complete', tag: _tag);
  }

  @override
  Future<UserProfile?> restoreSession() async {
    assert(DataConfig.useMockData);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kSessionEmail);
    if (email == null || email.isEmpty) return null;

    final inMemory = _signedUpProfiles[email];
    if (inMemory != null) return inMemory;

    final fromPrefs = await _loadPersistedProfile(email);
    if (fromPrefs != null) {
      _signedUpProfiles[email] = fromPrefs;
      return fromPrefs;
    }

    final profile = await MockProfiles.getProfileByEmail(email);
    if (profile == null) {
      await prefs.remove(_kSessionEmail);
      return null;
    }
    return profile;
  }

  @override
  Future<bool> isNewOwner(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_kOnboardingDone(userId)) ?? false;
    if (onboardingDone) return false;
    final email = prefs.getString(_kSignedUpEmail(userId));
    return email != null && email.isNotEmpty;
  }

  @override
  Future<void> setOnboardingComplete(String userId, {UserProfile? updatedProfile}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone(userId), true);
    if (updatedProfile != null) {
      await _persistProfile(updatedProfile);
      final email = updatedProfile.email;
      if (email != null) _signedUpProfiles[email] = updatedProfile;
    }
  }

  // Mock implementation of license key activation
  @override
  Future<UserProfile?> activateLicenseKey(String key) async {
    await simulateNetworkDelay();

    final trimmed = key.trim().toUpperCase();
    if (trimmed == 'ZEN-YOGA-777') {
      return UserProfile(
        userId: 'owner_${trimmed.toLowerCase()}',
        businessId: 'biz_${trimmed.toLowerCase()}',
        role: AppConstants.roleOwner,
        displayName: 'Tranquil Yoga Space',
        email: 'owner@zenyoga.com',
        joinedAt: DateTime.now(),
        isActive: true,
        businessName: 'Tranquil Yoga Space',
        planTier: 'premium',
        jobId: 'yoga_studio',
        selectedCategory: 'yoga_studio',
        primaryColor: '#7E57C2',
      );
    }
    return null;
  }

  Future<void> _saveSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionEmail, email.trim().toLowerCase());
  }

  Future<void> _persistProfile(UserProfile profile) async {
    final email = profile.email;
    if (email == null || email.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toJson());
      await prefs.setString(_kProfileJson(email), json);
    } catch (e) {
      AppLogger.warning('Failed to persist profile', tag: _tag, error: e);
    }
  }

  Future<UserProfile?> _loadPersistedProfile(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kProfileJson(email));
      if (json == null) return null;
      return UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(json) as Map));
    } catch (e) {
      AppLogger.warning('Failed to load persisted profile', tag: _tag, error: e);
      return null;
    }
  }
}