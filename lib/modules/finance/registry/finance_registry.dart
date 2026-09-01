// lib/modules/finance/registry/finance_registry.dart
//
// Registers the finance module's shareable widgets into the WidgetRegistry.
// Called once at app startup after config loads.
//
// Registered widgets:
//   'finance.OwnerRevenueSlot'   — revenue_summary slot  (owner dashboard).
//   'finance.PartnerEarningsSlot'— my_earnings slot      (partner dashboard).
//   'finance.ClientBalanceSlot'  — my_balance slot       (client dashboard).
//
// See Blueprint Section 7 for the WidgetRegistry architecture.

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/finance/registry/finance_dashboard_slots.dart';

abstract final class FinanceRegistry {
  /// Registers all finance widgets into the global WidgetRegistry.
  /// Safe to call multiple times (registry logs a warning on re-registration).
  static void register() {
    WidgetRegistry.register(
      'finance.OwnerRevenueSlot',
      (context, data) => const OwnerRevenueSlot(),
    );

    WidgetRegistry.register(
      'finance.PartnerEarningsSlot',
      (context, data) => const PartnerEarningsSlot(),
    );

    WidgetRegistry.register(
      'finance.ClientBalanceSlot',
      (context, data) => const ClientBalanceSlot(),
    );
  }
}
