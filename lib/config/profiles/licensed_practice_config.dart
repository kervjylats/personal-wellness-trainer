// lib/config/profiles/licensed_practice_config.dart

import 'package:personal_wellness_trainer/config/profiles/base_profile_config.dart';

class LicensedPracticeConfig extends BaseProfileConfig {
  const LicensedPracticeConfig();

  @override
  String get displayName => 'Licensed Practice';

  @override
  bool get showUpgradeBanner => false; // Already paid, never show up-sells

  @override
  bool get canCustomizeBranding => true; // White-labeling is unlocked out of the box

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