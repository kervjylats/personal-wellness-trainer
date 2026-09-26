// lib/data/sources/mock/mock_auth_source.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_invite_source.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_profiles.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
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

// Redemption-code resolution mirrors real mode's handle_new_user()
  // trigger (triggers.sql), which tries these in order:
  //   1. Invite-link token (wlp_...)  → join an EXISTING business as a
  //      Partner/Staff/Client (role comes from the link, not the client).
  //   2. Activation key (e.g. DEMO-YOGA-001) → spin up a BRAND NEW Pro
  //      Owner business (bought from the buyer/dev).
  //   3. Blank code → plain free sign-up → a BRAND NEW Free Owner.
  // The demo activation keys below are the mock-mode mirror of real
  // mode's activation_keys table (in-memory, for the landing page's
  // key-redemption path to have something real to try).
  static final Map<String, Map<String, String>> _demoActivationKeys = {
    'DEMO-YOGA-001': {'jobId': 'yoga_studio', 'businessName': 'Sunrise Yoga', 'primaryColor': '#2471A3'},
    'DEMO-NUTRITION-001': {'jobId': 'nutritionist', 'businessName': 'Fresh Start Nutrition', 'primaryColor': '#2E8B57'},
  };
  static final Set<String> _redeemedDemoKeys = {};

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
    String? redemptionCode,
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
    final code = (redemptionCode == null || redemptionCode.trim().isEmpty)
        ? null
        : redemptionCode.trim();

    UserProfile profile;
    if (code != null) {
      // Case 1: invite-link token into an existing business.
      final inviteRepo = MockInviteSource();
      final link = await inviteRepo.getLinkByToken(code);
      final linkUsable = link != null && !link.isExpired && !link.isExhausted;
      if (linkUsable) {
        final member = await MockTeamSource().inviteMember(
              businessId: link.businessId,
              invitedByUserId: link.invitedByUserId,
              role: link.targetRole,
              displayName: displayName.trim(),
              email: trimmedEmail,
              categoryId: link.categoryId,
            );
        profile = UserProfile(
          userId: member.userId,
          businessId: member.businessId,
          role: member.role,
          displayName: member.displayName,
          joinedAt: member.joinedAt,
          isActive: member.isActive,
          email: member.email,
          categoryId: member.categoryId,
          primaryPartnerId: member.primaryPartnerId,
          featureToggles: member.featureToggles,
        );
        await inviteRepo.recordUse(link.id);
      } else if (_demoActivationKeys.containsKey(code)) {
        if (_redeemedDemoKeys.contains(code)) {
          throw Exception('This activation key has already been used');
        }
        final key = _demoActivationKeys[code]!;
        profile = UserProfile(
          userId: userId,
          businessId: 'biz_${DateTime.now().millisecondsSinceEpoch}',
          role: AppConstants.roleOwner,
          displayName: displayName.trim(),
          email: trimmedEmail,
          joinedAt: DateTime.now(),
          isActive: true,
          businessName: key['businessName'],
          primaryColor: key['primaryColor'],
          jobId: key['jobId'],
          selectedCategory: key['jobId'],
          planTier: 'premium',
        );
        _redeemedDemoKeys.add(code);
      } else {
        throw Exception(
          code.startsWith('wlp_')
              ? 'This invite link is invalid or has already been used.'
              : 'Invalid or already-used activation key',
        );
      }
    } else {
      // Case 3: no code → a brand-new Free Owner.
      profile = UserProfile(
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
    }

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