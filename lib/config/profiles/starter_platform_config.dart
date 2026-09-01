// lib/config/profiles/starter_platform_config.dart

import 'package:personal_wellness_trainer/config/profiles/base_profile_config.dart';

class StarterPlatformConfig extends BaseProfileConfig {
  const StarterPlatformConfig();

  @override
  String get displayName => 'Starter Platform';

  @override
  bool get showUpgradeBanner => true; // Display the gold upgrade card

  @override
  bool get canCustomizeBranding => false; // Locked on free plan

  @override
  bool get canInvitePartners => false; // Lock collaborator invites on free plan

  @override
  bool get canViewFinance => true;

  @override
  Map<String, bool> get enabledModules => const {
    'activity': true,
    'finance': true,
    'team': true,
    'messaging': true,
    'media': false, // Gated on free plan
    'catalog': false, // Gated on free plan
    'scheduling': true,
    'reservations': true,
    'reviews': true,
  };
}