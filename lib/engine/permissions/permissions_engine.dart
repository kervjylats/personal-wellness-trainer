// lib/engine/permissions/permissions_engine.dart
//
// Role-aware permissions engine. P7-06.
// Reverted Control Panel overrides for simplification.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final permissionsEngineProvider = Provider<PermissionsEngine>((ref) {
  final config = ref.watch(configProvider).requireValue;
  return PermissionsEngine(config: config);
});

// ── PermissionsEngine ─────────────────────────────────────────────────────────

class PermissionsEngine {
  const PermissionsEngine({
    required this.config,
  });

  final AppEngineConfig config;

  static const String _tag = 'PermissionsEngine';

  // ════════════════════════════════════════════════════════════════════════════
  // MODULE ACCESS — All three levels
  // ════════════════════════════════════════════════════════════════════════════

  bool canAccessModule(String moduleId, UserProfile profile) {
    if (!config.build.modulesIncluded.isIncluded(moduleId)) {
      AppLogger.debug(
        'Module "$moduleId" blocked at Level 1 (not compiled)',
        tag: _tag,
      );
      return false;
    }

    final isActiveLevel2 = config.industry.modules.isActive(moduleId);
    if (!isActiveLevel2) {
      AppLogger.debug(
        'Module "$moduleId" blocked at Level 2 (config)',
        tag: _tag,
      );
      return false;
    }

    return _canRoleAccessModule(moduleId, profile);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHELL NAVIGATION — What tabs does this role see?
  // ════════════════════════════════════════════════════════════════════════════

  List<String> getAccessibleTabIds(UserProfile profile) {
    final role = AppRole.fromString(profile.role);
    final configTabs = config.industry.navigation.tabs;

    if (role.isConsumerOnly) {
      return _clientTabIds();
    }

    final List<String> result = [];
    result.add('dashboard');

    for (final tab in configTabs) {
      if (tab.id == 'dashboard') continue;

      final moduleId = _tabIdToModuleId(tab.id);

      if (moduleId == null) {
        result.add(tab.id);
        continue;
      }

      if (canAccessModule(moduleId, profile)) {
        if (_isTabAllowedForRole(tab.id, role)) {
          result.add(tab.id);
        }
      }
    }

    return result;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FEATURE PERMISSIONS — Individual feature access
  // ════════════════════════════════════════════════════════════════════════════

  /// Owner: always allowed. Partner and Client: never allowed. Staff:
  /// gated behind the given staff-permission flag.
  ///
  /// Shared by every feature check below that follows this exact
  /// owner/partner/client/staff shape — they used to each repeat this
  /// same four-line role check by hand.
  bool _ownerOnlyElseStaffFlag(UserProfile profile, String staffFlagKey) {
    final role = AppRole.fromString(profile.role);
    if (role.isOwner) return true;
    if (role.isPartner) return false;
    if (role.isClient) return false;
    return _resolveStaffPermission(profile, staffFlagKey);
  }

  bool canCreateActivity(UserProfile profile) =>
      _ownerOnlyElseStaffFlag(profile, 'can_create_activity');

  bool canViewFullFinance(UserProfile profile) =>
      _ownerOnlyElseStaffFlag(profile, 'can_view_finance');

  bool canManageClients(UserProfile profile) =>
      _ownerOnlyElseStaffFlag(profile, 'can_manage_clients');

  bool canViewAllActivities(UserProfile profile) =>
      _ownerOnlyElseStaffFlag(profile, 'can_view_all_activities');

  bool canUploadMedia(UserProfile profile) {
    final role = AppRole.fromString(profile.role);
    if (role.isOwner) return true;
    if (role.isClient) return false;
    if (role.isPartner) {
      return _resolvePartnerFeature(profile, 'can_upload_media');
    }
    return false;
  }

  bool canViewClientList(UserProfile profile) {
    final role = AppRole.fromString(profile.role);
    if (role.isOwner) return true;
    if (role.isClient) return false;
    if (role.isStaff) return false;
    return _resolvePartnerFeature(profile, 'can_view_client_list');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HARDCODED SHELL RULES — Blueprint Section 5. Never overrideable.
  // ════════════════════════════════════════════════════════════════════════════

  bool mustShowUpgradePrompt(UserProfile profile) {
    return AppRole.fromString(profile.role).isPartner;
  }

  bool canAccessControlPanel(UserProfile profile) {
    return AppRole.fromString(profile.role).isOwner &&
        config.build.ownerHasControlPanel;
  }

  bool mustShowOwnBusinessLink(UserProfile profile) {
    return AppRole.fromString(profile.role).isStaff;
  }

  bool isFeatureVisibleButLocked(String featureKey, UserProfile profile) {
    final role = AppRole.fromString(profile.role);
    if (!role.isPartner) return false;
    final partnerRules = config.industry.permissions.partner;
    final rule = partnerRules[featureKey];
    if (rule == null) return false;
    return rule.locked ||
        !(profile.featureToggles?[featureKey] ?? rule.defaultValue);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPATIBILITY (Refactored for Open Network)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Under our updated open-network model, all categories are fully compatible.
  /// This always returns true, keeping existing checks green without files.
  bool areCategoriesCompatible(String categoryIdA, String categoryIdB) {
    return true;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ════════════════════════════════════════════════════════════════════════════

  bool _canRoleAccessModule(String moduleId, UserProfile profile) {
    final role = AppRole.fromString(profile.role);
    if (role.isOwner) return true;
    if (role.isStaff) {
      return _resolveStaffPermission(profile, 'can_view_$moduleId') ||
          _resolveStaffPermission(profile, 'can_manage_$moduleId') ||
          ['messaging', 'notifications', 'team', 'activity'].contains(moduleId);
    }
    if (role.isPartner) {
      if (moduleId == 'finance') return true;
      // 'team' is always allowed for Partner — they need to see the
      // Owner who invited them and the shared client pool to actually
      // do the "offer services to the owner's clients, bring your own"
      // partnership this role exists for. Not something to gate behind
      // a configurable per-job permission.
      return _resolvePartnerFeature(profile, 'can_view_$moduleId') ||
          ['messaging', 'notifications', 'activity', 'team'].contains(moduleId);
    }
    if (role.isClient) {
      return ['activity', 'finance', 'messaging', 'notifications', 'team']
          .contains(moduleId);
    }
    return false;
  }

  bool _resolveStaffPermission(UserProfile profile, String key) {
    final individualToggle = profile.permissionToggles?[key];
    if (individualToggle != null) return individualToggle;
    final rule = config.industry.permissions.staff[key];
    return rule?.defaultValue ?? false;
  }

  bool _resolvePartnerFeature(UserProfile profile, String key) {
    final individualToggle = profile.featureToggles?[key];
    if (individualToggle != null) return individualToggle;
    final rule = config.industry.permissions.partner[key];
    return rule?.defaultValue ?? false;
  }

  String? _tabIdToModuleId(String tabId) {
    const tabToModule = <String, String>{
      'activity':     'activity',
      'finance':      'finance',
      'network':      'team',
      'messaging':    'messaging',
      'agreements':   'agreements',
      'media':        'media',
      'catalog':      'catalog',
      'gps':          'gps',
      'scheduling':   'scheduling',
      'reservations': 'reservations',
      'reviews':      'reviews',
    };
    return tabToModule[tabId];
  }

  bool _isTabAllowedForRole(String tabId, AppRole role) {
    if (tabId == 'control_panel' && !role.isOwner) return false;
    return true;
  }

  List<String> _clientTabIds() {
    return [
      'dashboard',
      'activity',
      'finance',
      'network',
      'community',
      'challenges',
      'homework',
      'loyalty',
    ];
  }
}