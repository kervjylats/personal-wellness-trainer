// lib/modules/inventory/registry/inventory_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/inventory/registry/inventory_alert_card.dart';

abstract final class InventoryRegistry {
  static void register() {
    WidgetRegistry.register(
      'inventory.AlertCard',
      (context, data) => InventoryAlertCard(data: data),
    );
  }
}
