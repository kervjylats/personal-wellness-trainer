// lib/modules/reservations/registry/reservations_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/reservations/registry/reservations_upcoming_card.dart';

abstract final class ReservationsRegistry {
  static void register() {
    WidgetRegistry.register(
      'reservations.UpcomingCard',
      (context, data) => ReservationsUpcomingCard(data: data),
    );
  }
}
