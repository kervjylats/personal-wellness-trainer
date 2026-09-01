// lib/modules/scheduling/registry/scheduling_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/scheduling/registry/scheduling_next_slot_card.dart';

abstract final class SchedulingRegistry {
  static void register() {
    WidgetRegistry.register(
      'scheduling.NextSlotCard',
      (context, data) => SchedulingNextSlotCard(data: data),
    );
  }
}
