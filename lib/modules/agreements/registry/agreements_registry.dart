// lib/modules/agreements/registry/agreements_registry.dart
//
// Registers the agreements module's shareable widgets into the WidgetRegistry.
// Called once at app startup after config loads.
//
// Registered widgets:
//   'agreements.DealSummaryCard' — summary card for a partnership agreement.
//     Used by: Finance screen, Dashboard (Phase 6), Messaging (Phase 5).
//
//   'agreements.CommissionCard'  — card for a single commission record.
//     Used by: Finance screen, Partner dashboard (Phase 6).
//
// Dashboard slot widgets:
//   'agreements.OwnerDealCountSlot' — deal_count slot   (owner dashboard).
//   'agreements.PartnerDealsSlot'   — active_deals slot (partner dashboard).

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/agreements/registry/agreements_dashboard_slots.dart';
import 'package:personal_wellness_trainer/modules/agreements/registry/commission_card.dart';
import 'package:personal_wellness_trainer/modules/agreements/registry/deal_summary_card.dart';

abstract final class AgreementsRegistry {
  /// Registers all agreements widgets into the global WidgetRegistry.
  static void register() {
    WidgetRegistry.register(
      'agreements.DealSummaryCard',
      (context, data) => DealSummaryCard(data: data),
    );

    WidgetRegistry.register(
      'agreements.CommissionCard',
      (context, data) => CommissionCard(data: data),
    );

    // ── Dashboard slots ───────────────────────────────────────────────────────

    WidgetRegistry.register(
      'agreements.OwnerDealCountSlot',
      (context, data) => const OwnerDealCountSlot(),
    );

    WidgetRegistry.register(
      'agreements.PartnerDealsSlot',
      (context, data) => const PartnerDealsSlot(),
    );
  }
}
