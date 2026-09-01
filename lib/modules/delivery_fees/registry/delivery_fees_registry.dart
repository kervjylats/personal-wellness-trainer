// lib/modules/delivery_fees/registry/delivery_fees_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/registry/delivery_fee_zone_card.dart';

abstract final class DeliveryFeesRegistry {
  static void register() {
    WidgetRegistry.register(
      'delivery_fees.ZoneCard',
      (context, data) => DeliveryFeeZoneCard(data: data),
    );
  }
}
