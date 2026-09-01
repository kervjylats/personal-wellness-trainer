// lib/engine/roles/app_role.dart
//
// The AppRole enum is the single source of truth for all role logic in the engine.
//
// NEVER use role strings ('owner', 'partner', etc.) for comparisons in Dart code.
// ALWAYS use AppRole.owner / .partner / .staff / .client.
//
// The only place raw role strings are used is:
//   - Parsing from JSON (UserProfile.fromJson, AppRole.fromString)
//   - Serialising to JSON (AppRole.value)
//   - AppConstants.roleOwner etc. (for the string literals themselves)
//
// These are the four permanent, universal role names. They cannot be changed
// by config, owner settings, or AI assistants. See Blueprint Section 2.

import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';

enum AppRole {
  owner,
  partner,
  staff,
  client;

  /// The raw string value used in JSON and the database.
  /// Maps back to AppConstants.roleOwner etc.
  String get value {
    switch (this) {
      case AppRole.owner:
        return AppConstants.roleOwner;
      case AppRole.partner:
        return AppConstants.rolePartner;
      case AppRole.staff:
        return AppConstants.roleStaff;
      case AppRole.client:
        return AppConstants.roleClient;
    }
  }

  /// Parses a raw role string into an AppRole.
  /// Unrecognised values default to [AppRole.client] and log a warning.
  /// Never throws — safe to call from untrusted data.
  static AppRole fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'owner':
        return AppRole.owner;
      case 'partner':
        return AppRole.partner;
      case 'staff':
        return AppRole.staff;
      case 'client':
        return AppRole.client;
      default:
        AppLogger.warning(
          'AppRole.fromString: unrecognised role "$raw" — defaulting to client',
          tag: 'AppRole',
        );
        return AppRole.client;
    }
  }
}

/// Convenience extensions on AppRole for shell-building logic.
extension AppRoleExtensions on AppRole {
  bool get isOwner => this == AppRole.owner;
  bool get isPartner => this == AppRole.partner;
  bool get isStaff => this == AppRole.staff;
  bool get isClient => this == AppRole.client;

  /// True for roles that manage the business (owner and staff).
  bool get isManagement => this == AppRole.owner || this == AppRole.staff;

  /// True for roles that have an agreement-based relationship (partner).
  bool get isIndependent => this == AppRole.partner;

  /// True for roles that consume services (client and, partially, partner).
  bool get isConsumer => this == AppRole.client;

  // ── Shell-safe role checks ───────────────────────────────────────────────────
  // These drive navigation building. They do NOT replace PermissionsEngine —
  // always use PermissionsEngine for feature-level decisions.

  /// Partner shells always show Upgrade to Pro. Cannot be removed. (Blueprint §5)
  bool get requiresUpgradePrompt => this == AppRole.partner;

  /// Only owner has the full Control Panel. (Blueprint §5)
  bool get hasControlPanel => this == AppRole.owner;

  /// Staff settings always show the "start your own business" contact link.
  bool get hasOwnBusinessLink => this == AppRole.staff;

  /// Client shell has zero management features. (Blueprint §5)
  bool get isConsumerOnly => this == AppRole.client;
}
