// lib/modules/gps/registry/gps_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/gps/registry/gps_location_card.dart';

abstract final class GpsRegistry {
  static void register() {
    WidgetRegistry.register(
      'gps.LocationCard',
      (context, data) => GpsLocationCard(data: data),
    );
  }
}
