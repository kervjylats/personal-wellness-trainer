// lib/config/profiles/collaborator_config.dart

import 'package:personal_wellness_trainer/config/profiles/base_profile_config.dart';

class CollaboratorConfig extends BaseProfileConfig {
  const CollaboratorConfig();

  @override
  String get displayName => 'Platform Collaborator';

  @override
  bool get showUpgradeBanner => true; // Display the card to prompt them to buy their own app

  @override
  bool get canCustomizeBranding => false; // No custom branding inside another owner's room

  @override
  bool get canInvitePartners => false;

  @override
  bool get canViewFinance => true; // Can view their own dynamic commission earnings

  @override
  Map<String, bool> get enabledModules => const {
    'activity': true,
    'finance': true, // Displays partner earnings view only
    'team': false,
    'messaging': true,
    'media': false,
    'catalog': false,
    'scheduling': true,
    'reservations': true,
    'reviews': true,
  };
}