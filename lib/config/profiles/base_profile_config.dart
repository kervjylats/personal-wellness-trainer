// lib/config/profiles/base_profile_config.dart

abstract class BaseProfileConfig {
  const BaseProfileConfig();

  /// The marketing-friendly display name of the profile
  String get displayName;

  /// Visibility flag for the gold "Upgrade to Pro" card
  bool get showUpgradeBanner;

  /// Permission flag to unlock the custom branding/design settings
  bool get canCustomizeBranding;

  /// Permission flag to allow inviting partners to their network
  bool get canInvitePartners;

  /// Permission flag to view advanced business financial summaries
  bool get canViewFinance;
  
  /// Map of allowed modules compiled into this specific profile's workspace
  Map<String, bool> get enabledModules;
}