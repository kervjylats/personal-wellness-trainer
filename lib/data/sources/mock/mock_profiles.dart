// lib/data/sources/mock/mock_profiles.dart
//
// Mock profile data source for Phase 1 through Phase 9.
// Active when DataConfig.useMockData = true.
//
// ⚠️  ZERO industry-specific words anywhere in this file.
//     No 'trainer', 'driver', 'nurse', 'session', 'trip', 'appointment'.
//     All terminology visible to users comes from industry_config.json.
//     This file uses generic structural labels only.
//
// Email prefix determines role in development:
//   owner@*   → AppRole.owner
//   partner@* → AppRole.partner
//   staff@*   → AppRole.staff
//   anything  → AppRole.client
//
// All passwords accepted in mock mode — auth is simulated.
// Real auth (Supabase) is wired in Phase 10.
//
// Phase 9 fix: jobId changed from 'placeholder_job' to 'yoga_studio'
// so that activeJobConfigProvider resolves a real job when signing in
// as owner@test.com during development.

import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

/// Mock implementation of the profile data source.
/// Returns hardcoded profiles keyed by email prefix.
/// Used by AuthNotifier (Phase 1) and ProfileProvider (Phase 1).
abstract final class MockProfiles {
  static const String _tag = 'MockProfiles';

  // ── Business & User IDs (stable across the mock session) ─────────────────────
  static const String _businessId = 'biz_mock_001';
  static const String _ownerUserId = 'usr_owner_001';
  static const String _partnerUserId = 'usr_partner_001';
  static const String _staffUserId = 'usr_staff_001';
  static const String _clientUserId = 'usr_client_001';

  // ── The Four Mock Profiles ────────────────────────────────────────────────────

  static final UserProfile ownerProfile = UserProfile(
    userId: _ownerUserId,
    businessId: _businessId,
    role: AppConstants.roleOwner,
    displayName: 'Alex Owner',
    email: 'owner@test.com',
    phone: '+1 555 000 0001',
    joinedAt: DateTime(2024, 1, 15),
    isActive: true,
    // Owner-specific
    businessName: 'Demo Business',
    primaryColor: '#2471A3',
    planTier: 'premium',
    currency: r'$',
    selectedCategory: 'cat_1',
    // Phase 9 fix: was 'placeholder_job' — activeJobConfigProvider now resolves
    // a real job so all terminology, activity fields, and module flags are live.
    // Swap this to any valid id from jobs_config.json to test a different job.
    jobId: 'yoga_studio',
    // All on by default — matches pre-existing behaviour for anyone who
    // hasn't touched the new Business Features settings screen.
    partnersEnabled: true,
    marketplaceEnabled: true,
    agreementsEnabled: true,
  );

  static final UserProfile partnerProfile = UserProfile(
    userId: _partnerUserId,
    businessId: _businessId,
    role: AppConstants.rolePartner,
    displayName: 'Jordan Partner',
    email: 'partner@test.com',
    phone: '+1 555 000 0002',
    joinedAt: DateTime(2024, 3, 10),
    isActive: true,
    // businessName was previously unset (null) here, unlike ownerProfile.
    // partner_shell.dart's AppBar prefers showing the partner's own
    // business name over the generic role-term title ("Partners"), with
    // jobConfig.terminology.partner as a fallback only when no name is
    // set. Without this, the fallback always fired for the mock partner,
    // permanently showing "Partners" as the page title — which is what a
    // human would picture as a tab for browsing OTHER partner businesses,
    // even though no such feature exists for partner-role users.
    businessName: 'Sunrise Wellness Annex',
    // Partner-specific
    categoryId: 'cat_1',
    agreementStatus: 'active',
    commissionRate: 15.0,
    hasUpgradedToPro: false,
    featureToggles: {
      'messaging_gps': false,
      'can_upload_media': false,
      'can_view_client_list': false,
    },
  );

  static final UserProfile staffProfile = UserProfile(
    userId: _staffUserId,
    businessId: _businessId,
    role: AppConstants.roleStaff,
    displayName: 'Morgan Staff',
    email: 'staff@test.com',
    phone: '+1 555 000 0003',
    joinedAt: DateTime(2024, 2, 20),
    isActive: true,
    // Staff-specific
    jobTitle: 'staff_1',
    assignedActivityCount: 4,
    permissionToggles: {
      'can_create_activity': true,
      'can_view_finance': false,
      'can_manage_clients': false,
      'can_view_all_activities': true,
    },
  );

  static final UserProfile clientProfile = UserProfile(
    userId: _clientUserId,
    businessId: _businessId,
    role: AppConstants.roleClient,
    displayName: 'Sam Client',
    email: 'client@test.com',
    phone: '+1 555 000 0004',
    joinedAt: DateTime(2024, 4, 5),
    isActive: true,
    // Client-specific
    primaryPartnerId: _partnerUserId,
    bookingCount: 7,
    totalPaid: 420.00,
    outstandingBalance: 0.00,
  );

  // ── A few extra team members (used by Network module in Phase 4) ──────────────

  static final List<UserProfile> additionalStaff = [
    UserProfile(
      userId: 'usr_staff_002',
      businessId: _businessId,
      role: AppConstants.roleStaff,
      displayName: 'Casey Staff',
      email: 'staff2@test.com',
      joinedAt: DateTime(2024, 5, 1),
      isActive: true,
      jobTitle: 'staff_2',
      assignedActivityCount: 2,
      permissionToggles: {
        'can_create_activity': true,
        'can_view_finance': false,
        'can_manage_clients': false,
        'can_view_all_activities': false,
      },
    ),
    UserProfile(
      userId: 'usr_staff_003',
      businessId: _businessId,
      role: AppConstants.roleStaff,
      displayName: 'Riley Staff',
      email: 'staff3@test.com',
      joinedAt: DateTime(2024, 6, 12),
      isActive: false,
      jobTitle: 'staff_1',
      assignedActivityCount: 0,
      permissionToggles: {
        'can_create_activity': false,
        'can_view_finance': false,
        'can_manage_clients': false,
        'can_view_all_activities': true,
      },
    ),
  ];

  static final List<UserProfile> additionalClients = [
    UserProfile(
      userId: 'usr_client_002',
      businessId: _businessId,
      role: AppConstants.roleClient,
      displayName: 'Taylor Client',
      email: 'client2@test.com',
      joinedAt: DateTime(2024, 4, 18),
      isActive: true,
      bookingCount: 3,
      totalPaid: 150.00,
      outstandingBalance: 50.00,
    ),
    UserProfile(
      userId: 'usr_client_003',
      businessId: _businessId,
      role: AppConstants.roleClient,
      displayName: 'Drew Client',
      email: 'client3@test.com',
      joinedAt: DateTime(2024, 7, 2),
      isActive: true,
      bookingCount: 1,
      totalPaid: 80.00,
      outstandingBalance: 0.00,
    ),
  ];

  // ── Lookup Methods ────────────────────────────────────────────────────────────

  /// Returns the profile that corresponds to the given email,
  /// based on the email prefix convention.
  /// Used by MockAuthSource to simulate login.
  static Future<UserProfile?> getProfileByEmail(String email) async {
    assert(
      DataConfig.useMockData,
      'MockProfiles must only be used when DataConfig.useMockData is true.',
    );

    // Simulate network latency.
    await Future<void>.delayed(AppConstants.mockDelay);

    final normalised = email.toLowerCase().trim();
    AppLogger.debug(
      'MockProfiles: lookup for "$normalised"',
      tag: _tag,
    );

    if (normalised.startsWith(AppConstants.mockOwnerPrefix)) {
      return ownerProfile;
    }
    if (normalised.startsWith(AppConstants.mockPartnerPrefix)) {
      return partnerProfile;
    }
    if (normalised.startsWith(AppConstants.mockStaffPrefix)) {
      return staffProfile;
    }
    // Any other email → client role.
    return clientProfile;
  }

  /// Returns the profile for a given userId.
  /// Used by the engine to reload a profile (e.g. after permission change).
  static Future<UserProfile?> getProfileById(String userId) async {
    assert(
      DataConfig.useMockData,
      'MockProfiles must only be used when DataConfig.useMockData is true.',
    );

    await Future<void>.delayed(AppConstants.mockDelay);

    final all = [
      ownerProfile,
      partnerProfile,
      staffProfile,
      clientProfile,
      ...additionalStaff,
      ...additionalClients,
    ];

    try {
      return all.firstWhere((p) => p.userId == userId);
    } catch (_) {
      AppLogger.warning(
        'MockProfiles: no profile found for userId "$userId"',
        tag: _tag,
      );
      return null;
    }
  }

  /// Returns all profiles belonging to a business (owner's team view).
  static Future<List<UserProfile>> getTeamForBusiness(
    String businessId,
  ) async {
    assert(
      DataConfig.useMockData,
      'MockProfiles must only be used when DataConfig.useMockData is true.',
    );

    await Future<void>.delayed(AppConstants.mockDelay);

    final all = [
      partnerProfile,
      staffProfile,
      ...additionalStaff,
    ];

    return all.where((p) => p.businessId == businessId).toList();
  }

  /// Returns all client profiles for a business.
  static Future<List<UserProfile>> getClientsForBusiness(
    String businessId,
  ) async {
    assert(
      DataConfig.useMockData,
      'MockProfiles must only be used when DataConfig.useMockData is true.',
    );

    await Future<void>.delayed(AppConstants.mockDelay);

    return [clientProfile, ...additionalClients]
        .where((p) => p.businessId == businessId)
        .toList();
  }
}
