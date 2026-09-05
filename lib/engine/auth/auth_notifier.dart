// lib/engine/auth/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_auth_source.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_profiles.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_auth_source.dart'; 
import 'package:personal_wellness_trainer/engine/auth/auth_repository.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/config/buyer_config.dart'; 

// ── Provider ──────────────────────────────────────────────────────────────────

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  static const String _tag = 'AuthNotifier';

  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = _resolveRepository();
    
    // ── DEVELOPER SANDBOX BYPASS ──
    if (BuyerConfig.testBypassRole != null) {
      final role = BuyerConfig.testBypassRole!;
      final profile = _mockProfileForRole(role);
      return AuthAuthenticated(profile: profile, isNewOwner: false);
    }

    _tryRestoreSession();
    return const AuthInitial();
  }

  UserProfile _mockProfileForRole(String role) {
    switch (role) {
      case 'partner': return MockProfiles.partnerProfile;
      case 'staff':   return MockProfiles.staffProfile;
      case 'client':  return MockProfiles.clientProfile;
      default:        return MockProfiles.ownerProfile;
    }
  }

  // ── Public Actions ─────────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    AppLogger.info('Signing in…', tag: _tag);

    try {
      final profile = await _repository.signIn(email.trim(), password);
      final newOwner = await _checkIsNewOwner(profile);
      state = AuthAuthenticated(profile: profile, isNewOwner: newOwner);
      AppLogger.info(
        'Signed in: ${profile.displayName} (${profile.role})',
        tag: _tag,
      );
    } catch (e, st) {
      AppLogger.error('Sign-in failed', tag: _tag, error: e, stackTrace: st);
      state = AuthUnauthenticated(errorMessage: _friendlyError(e));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role, 
  }) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    AppLogger.info('Signing up as $role…', tag: _tag);

    try {
      final profile = await _repository.signUp(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
      );
      
      final updatedProfile = profile.copyWith(role: role);
      state = AuthAuthenticated(profile: updatedProfile, isNewOwner: role == 'owner');
      AppLogger.info('Sign-up complete: ${updatedProfile.displayName}', tag: _tag);
    } catch (e, st) {
      AppLogger.error('Sign-up failed', tag: _tag, error: e, stackTrace: st);
      state = AuthUnauthenticated(errorMessage: _friendlyError(e));
    }
  }

  Future<bool> completeOnboarding({
    required String businessName,
    required String category,
    required String primaryColorHex,
    String? jobId,
  }) async {
    if (state is! AuthAuthenticated) return false;
    final current = state as AuthAuthenticated;

    try {
      final updatedProfile = current.profile.copyWith(
        businessName: businessName,
        selectedCategory: category,
        primaryColor: primaryColorHex,
        jobId: jobId ?? category,
      );

      await _repository.setOnboardingComplete(
        current.profile.userId,
        updatedProfile: updatedProfile,
      );

      state = AuthAuthenticated(
        profile: updatedProfile,
        isNewOwner: false,
      );

      AppLogger.info('Onboarding complete', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error(
        'completeOnboarding failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// ── Smart License Activation Engine (Cloud Connected!) 🎟️ ──
  /// Delegates the validation directly to the active database repository!
  Future<bool> activateLicenseKey(String key) async {
    if (state is AuthLoading) return false;
    state = const AuthLoading();
    AppLogger.info('Validating license key: $key', tag: _tag);

    try {
      // Direct repository delegation! Talks to Supabase when useMockData is false.
      final profile = await _repository.activateLicenseKey(key);

      if (profile != null) {
        state = AuthAuthenticated(profile: profile, isNewOwner: false);
        AppLogger.info('License Activated: ${profile.displayName} is now Premium!', tag: _tag);
        return true;
      }
    } catch (e, st) {
      AppLogger.error('activateLicenseKey failed critically', tag: _tag, error: e, stackTrace: st);
    }

    state = const AuthUnauthenticated(errorMessage: 'Invalid Activation Key');
    return false;
  }

  Future<void> upgradeToPremium() async {
    if (state is! AuthAuthenticated) return;
    final current = state as AuthAuthenticated;

    state = const AuthLoading();
    await Future<void>.delayed(AppConstants.mockDelay); 

    UserProfile updated;

    if (current.profile.role == 'partner') {
      final newBusinessId = 'biz_spin_${current.profile.userId}';
      
      updated = current.profile.copyWith(
        role: 'owner',
        planTier: 'premium',
        businessId: newBusinessId,
        businessName: '${current.profile.displayName} Space',
        jobId: 'yoga_studio', 
      );

      MockTeamSource().migratePartnerClients(current.profile.userId, newBusinessId);
      AppLogger.info('SaaS Spin-Off: Migrated clients to business $newBusinessId', tag: _tag);
    } else {
      updated = current.profile.copyWith(
        planTier: 'premium',
      );
    }

    state = AuthAuthenticated(
      profile: updated,
      isNewOwner: current.isNewOwner,
    );
    AppLogger.info('Mock Billing: Account upgraded to Premium!', tag: _tag);
  }

  /// Owner-only. Updates this business's feature toggles (Partnerships /
  /// Marketplace / Agreements) and pushes the change through to the shared
  /// team roster too — not just this device's own AuthState — so every
  /// other member of the business sees it immediately on their own Network
  /// screen. Mirrors upgradeToPremium()'s pattern of mutating both stores.
  Future<void> updateBusinessFeatures({
    bool? partnersEnabled,
    bool? marketplaceEnabled,
    bool? agreementsEnabled,
  }) async {
    if (state is! AuthAuthenticated) return;
    final current = state as AuthAuthenticated;
    if (current.profile.role != 'owner') return;

    final updated = current.profile.copyWith(
      partnersEnabled: partnersEnabled,
      marketplaceEnabled: marketplaceEnabled,
      agreementsEnabled: agreementsEnabled,
    );

    state = AuthAuthenticated(profile: updated, isNewOwner: current.isNewOwner);

    MockTeamSource().updateBusinessFeatures(
      current.profile.userId,
      partnersEnabled: partnersEnabled,
      marketplaceEnabled: marketplaceEnabled,
      agreementsEnabled: agreementsEnabled,
    );
    AppLogger.info('Business Features updated', tag: _tag);
  }

  Future<void> devQuickSignIn({
    required String jobId,
    required String jobLabel,
  }) async {
    assert(
      DataConfig.useMockData,
      'devQuickSignIn must only be used when DataConfig.useMockData is true.',
    );
    if (state is AuthLoading) return;
    state = const AuthLoading();

    UserProfile profile;

    // Partner / Staff / Client: use the REAL mock profiles.
    //
    // These profiles all share businessId 'biz_mock_001' (see MockProfiles),
    // which is the SAME business the mock owner belongs to. All mock data
    // sources (activities, finance, agreements, conversations, etc.) are
    // scoped to that one business — it's the only business that exists in
    // mock data. A synthetic profile with businessId 'biz_dev_partner' (etc.)
    // would belong to a business that has no data, no relationships, and no
    // counterpart conversations — causing empty screens or lookup crashes.
    //
    // Reuses the same mapping as BuyerConfig.testBypassRole
    // (see _mockProfileForRole above).
    if (jobId == 'partner' || jobId == 'staff' || jobId == 'client') {
      profile = _mockProfileForRole(jobId);
    } else {
      // Owner: synthetic per-job-type profile (existing behavior).
      // Owner-scoped mock sources don't require a pre-registered business —
      // they key off profile.jobId/selectedCategory for terminology/config,
      // so a unique businessId per job type is fine here.
      profile = UserProfile(
        userId: 'dev_$jobId',
        businessId: 'biz_dev_$jobId',
        role: AppConstants.roleOwner,
        displayName: 'Dev $jobLabel',
        email: 'dev_${jobId.replaceAll("_", "")}@test.com',
        joinedAt: DateTime.now(),
        isActive: true,
        businessName: 'My $jobLabel',
        planTier: 'free',
        jobId: jobId,
        selectedCategory: jobId,
        primaryColor: '#2471A3',
      );
    }

    state = AuthAuthenticated(profile: profile, isNewOwner: false);
    AppLogger.info(
      'Dev quick sign-in complete: $jobLabel (${profile.role})',
      tag: _tag,
    );
  }

  void updateProfile({
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
  }) {
    if (state is! AuthAuthenticated) return;
    final current = state as AuthAuthenticated;
    final updated = current.profile.copyWith(
      displayName: displayName ?? current.profile.displayName,
      email: email ?? current.profile.email,
      phone: phone ?? current.profile.phone,
      photoUrl: photoUrl ?? current.profile.photoUrl,
    );
    state = AuthAuthenticated(
      profile: updated,
      isNewOwner: current.isNewOwner,
    );
    AppLogger.info('Profile updated', tag: _tag);
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    AppLogger.info('Signing out…', tag: _tag);

    try {
      await _repository.signOut();
    } catch (e) {
      AppLogger.warning('Sign-out error (ignored)', tag: _tag, error: e);
    } finally {
      state = const AuthUnauthenticated();
    }
  }

  void clearError() {
    if (state is AuthUnauthenticated) {
      state = const AuthUnauthenticated();
    }
  }

  /// Completes sign-in with an ALREADY-RESOLVED profile, bypassing the
  /// normal email/password repository lookup entirely. Used by
  /// AcceptInvitationScreen once an invite token has been validated and
  /// TeamRepository.inviteMember() has created the new team member record
  /// — at that point we already have a real, freshly-created UserProfile
  /// in hand and just need to establish the session for it.
  Future<void> completeInviteJoin(UserProfile profile) async {
    state = AuthAuthenticated(profile: profile, isNewOwner: false);
    AppLogger.info(
      'Invite join complete: ${profile.displayName} (${profile.role})',
      tag: _tag,
    );
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  AuthRepository _resolveRepository() {
    if (DataConfig.useMockData) {
      AppLogger.debug('Using MockAuthSource', tag: _tag);
      return MockAuthSource();
    }
    AppLogger.debug('Using Real SupabaseAuthSource', tag: _tag);
    return SupabaseAuthSource(); 
  }

  Future<void> _tryRestoreSession() async {
    try {
      final profile = await _repository.restoreSession();
      if (profile != null) {
        final newOwner = await _checkIsNewOwner(profile);
        state = AuthAuthenticated(profile: profile, isNewOwner: newOwner);
        AppLogger.info('Session restored: ${profile.displayName}', tag: _tag);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      AppLogger.warning(
        'session restore failed — going to login',
        tag: _tag,
        error: e,
      );
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> _checkIsNewOwner(UserProfile profile) async {
    if (profile.role != 'owner') return false;
    try {
      return await _repository.isNewOwner(profile.userId);
    } catch (_) {
      return false;
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    if (message.contains('network') || message.contains('socket')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (message.isNotEmpty) return message;
    return 'Sign-in failed. Please check your details and try again.';
  }
}
/// Always starts fully unauthenticated, ignoring any persisted mock
/// session (SharedPreferences' 'ae_mock_session_email') that a normal
/// sign-in elsewhere in the same browser tab may have left behind.
///
/// Used by the QA Console (lib/dev_tools/qa_console_screen.dart) for the
/// Partner / Staff / Client panels, which are meant to start as a
/// genuinely fresh, unjoined person — arriving at the real sign-in
/// screen and joining via a real invite link generated from the Owner
/// panel, rather than jumping straight to a pre-existing mock account.
///
/// Defined in this file (not qa_console_screen.dart) specifically so it
/// can access the inherited private `_repository` field and
/// `_resolveRepository()` method — both are file-private in Dart (an
/// underscore-prefixed name is scoped to its OWN file, not just its own
/// class), so a subclass living in a different file cannot reach them.
///
/// Everything else is inherited unchanged: real signIn(), real signUp(),
/// real completeInviteJoin() all work normally here. Only the STARTING
/// state is forced to unauthenticated.
class QaFreshAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    _repository = _resolveRepository();
    return const AuthUnauthenticated();
  }
}
