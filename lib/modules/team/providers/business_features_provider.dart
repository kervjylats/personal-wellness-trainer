// lib/modules/team/providers/business_features_provider.dart
//
// Single source of truth for "is Partnerships / Marketplace / Agreements
// turned on for this business" — every nav-gating and entry-point check
// should read from here rather than re-deriving _findOwner(all) locally.
//
// These are business-wide settings, so they're read off the Owner's own
// roster row (see TeamMemberModel doc comment) regardless of which role
// is currently signed in — a Partner checking "can I even be a partner
// here" reads the same flags an Owner would.
//
// Defaults to fully-on (true) whenever the roster hasn't loaded yet or the
// owner row is missing, so a slow/failed load never silently hides features
// that are actually enabled — the loading state should feel like "normal",
// not "everything's off".

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';

class BusinessFeatures {
  const BusinessFeatures({
    required this.partnersEnabled,
    required this.marketplaceEnabled,
    required this.agreementsEnabled,
  });

  static const BusinessFeatures allEnabled = BusinessFeatures(
    partnersEnabled: true,
    marketplaceEnabled: true,
    agreementsEnabled: true,
  );

  final bool partnersEnabled;
  final bool marketplaceEnabled;
  final bool agreementsEnabled;
}

final businessFeaturesProvider = Provider<BusinessFeatures>((ref) {
  final members = ref.watch(teamNotifierProvider).valueOrNull;
  if (members == null) return BusinessFeatures.allEnabled;

  TeamMemberModel? owner;
  for (final m in members) {
    if (m.role == 'owner') {
      owner = m;
      break;
    }
  }
  if (owner == null) return BusinessFeatures.allEnabled;

  return BusinessFeatures(
    partnersEnabled: owner.partnersEnabled ?? true,
    marketplaceEnabled: owner.marketplaceEnabled ?? true,
    agreementsEnabled: owner.agreementsEnabled ?? true,
  );
});
