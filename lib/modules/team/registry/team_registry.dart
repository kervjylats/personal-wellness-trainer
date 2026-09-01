// lib/modules/team/registry/team_registry.dart
//
// Registers the team module's shareable widgets into the WidgetRegistry.
// Called once at app startup after config loads.
//
// Registered widgets:
//   'team.MemberCard'       — compact card showing a member's name, role, status.
//     Used by: Network screens, Messaging (Phase 5).
//
// Dashboard slot widgets:
//   'team.OwnerTeamCountSlot' — team_count slot (owner dashboard).

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/team/registry/member_card.dart';
import 'package:personal_wellness_trainer/modules/team/registry/team_dashboard_slots.dart';

abstract final class TeamRegistry {
  /// Registers all team widgets into the global WidgetRegistry.
  static void register() {
    WidgetRegistry.register(
      'team.MemberCard',
      (context, data) => MemberCard(data: data),
    );

    // ── Dashboard slot ────────────────────────────────────────────────────────

    WidgetRegistry.register(
      'team.OwnerTeamCountSlot',
      (context, data) => const OwnerTeamCountSlot(),
    );
  }
}
