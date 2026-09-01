// lib/config/profiles/profile_config_resolver.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/config/profiles/base_profile_config.dart';
import 'package:personal_wellness_trainer/config/profiles/licensed_practice_config.dart';
import 'package:personal_wellness_trainer/config/profiles/starter_platform_config.dart';
import 'package:personal_wellness_trainer/config/profiles/premium_platform_config.dart';
import 'package:personal_wellness_trainer/config/profiles/collaborator_config.dart';
import 'package:personal_wellness_trainer/config/profiles/spinoff_practice_config.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';

/// Central provider that resolves the current user's profile configuration.
/// Any UI widget can watch this to read dynamic feature flags in real-time.
final profileConfigProvider = Provider<BaseProfileConfig>(
  (ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      return const StarterPlatformConfig(); // Safe fallback default
    }

    final profile = authState.profile;
    return resolveProfileConfig(profile);
  },
  // See lib/dev_tools/qa_console_screen.dart for why this is required.
  dependencies: [authNotifierProvider],
);

/// ── The 2-Axis Resolution Engine ──
BaseProfileConfig resolveProfileConfig(UserProfile profile) {
  // Axis 1: If they are a Partner, they get the Collaborator Config
  if (profile.role == 'partner') {
    return const CollaboratorConfig();
  }

  // Axis 2: If they are an Owner, resolve their specific tier/onboarding path
  if (profile.role == 'owner') {
    // Registered via Activation License Key
    if (profile.userId.startsWith('owner_')) {
      return const LicensedPracticeConfig(); 
    }
    
    // Upgraded Partner (Spin-off owner)
    if (profile.userId.startsWith('dev_partner') || profile.userId.startsWith('usr_partner_001')) {
      return const SpinOffPracticeConfig(); 
    }
    
    // Upgraded standard SaaS Owner
    if (profile.planTier == 'premium') {
      return const PremiumPlatformConfig(); 
    }
    
    // Standard Free SaaS Owner
    return const StarterPlatformConfig(); 
  }

  // Fallback default
  return const StarterPlatformConfig();
}