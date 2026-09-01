// lib/config/profiles/premium_platform_config.dart

import 'package:personal_wellness_trainer/config/profiles/base_profile_config.dart';

class PremiumPlatformConfig extends BaseProfileConfig {
  const PremiumPlatformConfig();

  @override
  String get displayName => 'Premium Platform';

  @override
  bool get showUpgradeBanner => false; // Upgraded, hide card

  @override
  bool get canCustomizeBranding => true; // Custom branding fully unlocked

  @override
  bool get canInvitePartners => true;

  @override
  bool get canViewFinance => true;

  @override
  Map<String, bool> get enabledModules => const {
    'activity': true,
    'finance': true,
    'team': true,
    'messaging': true,
    'media': true,
    'catalog': true,
    'scheduling': true,
    'reservations': true,
    'reviews': true,
  };
}