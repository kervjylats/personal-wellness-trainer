// lib/core/constants/app_constants.dart
//
// Named constants for limits, durations, counts, and configuration values.
// Replaces magic numbers scattered through the codebase.
//
// Role string constants (roleOwner, etc.) are for JSON parsing ONLY.
// In all Dart code, use the AppRole enum from lib/engine/roles/app_role.dart.

abstract final class AppConstants {
  // ── Authentication ────────────────────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxEmailLength = 254;
  static const int maxDisplayNameLength = 80;

  // ── Timeouts & Delays ─────────────────────────────────────────────────────────
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Simulated async delay for mock data sources.
  /// Makes mock behavior feel like real network calls.
  static const Duration mockDelay = Duration(milliseconds: 400);

  /// Simulated delay for mock real-time permission sync.
  /// Mimics the Supabase Realtime latency (implemented for real in Phase 10).
  static const Duration permissionSyncSimDelay = Duration(seconds: 2);

  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration debounceDelay = Duration(milliseconds: 500);

  // ── Pagination ────────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ── Navigation ────────────────────────────────────────────────────────────────
  static const int maxTabCount = 4;

  // ── Finance ───────────────────────────────────────────────────────────────────
  static const int currencyDecimalPlaces = 2;
  static const double maxCommissionRate = 100.0;

  // ── Role Strings — JSON Parsing Only ─────────────────────────────────────────
  // These map role field values in JSON / database to Dart code.
  // DO NOT use these for role comparisons in Dart — use AppRole enum instead.
  static const String roleOwner = 'owner';
  static const String rolePartner = 'partner';
  static const String roleStaff = 'staff';
  static const String roleClient = 'client';

  // ── Mock Email Prefixes ────────────────────────────────────────────────────────
  // Used by MockAuthSource to determine role from email during development.
  // Example: owner@test.com → AppRole.owner
  static const String mockOwnerPrefix = 'owner@';
  static const String mockPartnerPrefix = 'partner@';
  static const String mockStaffPrefix = 'staff@';
  static const String mockClientPrefix = 'client@';
  // Any other prefix → client role for getProfileByEmail's fallback,
  // but signIn() only accepts these 4 recognized prefixes (plus any
  // email that signed up during this session) — see MockAuthSource.signIn.

  // ── Config Field Names ────────────────────────────────────────────────────────
  // JSON key names used when parsing industry_config.json and app_config.json.
  static const String configKeyAppName = 'app_name';
  static const String configKeyPrimaryColor = 'primary_color';
  static const String configKeyModules = 'modules';
  static const String configKeyTerminology = 'terminology';
  static const String configKeyNavigation = 'navigation';
  static const String configKeyPermissions = 'permissions';
  static const String configKeyPayment = 'payment';
  static const String configKeyUpgrade = 'upgrade';

  // ── Upgrade Prompt ────────────────────────────────────────────────────────────
  // Default text shown before industry_config.json upgrade block is loaded.
  static const String defaultUpgradeButtonLabel = 'Upgrade to Pro';
  static const String defaultUpgradeSubtitle =
      'Get your own platform with full owner access';

  // ── Misc ──────────────────────────────────────────────────────────────────────
  static const String appName = 'Personal Wellness Trainer';
  static const String appVersion = '1.0.0';
}
