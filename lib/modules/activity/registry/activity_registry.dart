// lib/modules/activity/registry/activity_registry.dart
//
// Registers the activity module's shareable widgets into the WidgetRegistry.
// Called once at app startup, after config loads and before any screen renders.
//
// Registered widgets:
//   'activity.BookingConfirmationCard' — a card showing a just-confirmed activity.
//      Used by: Dashboard (Phase 6), Notifications (Phase 5).
//   'activity.UpcomingSessionCard' — a card showing the next upcoming activity.
//      Used by: Dashboard (Phase 6) for all roles.
//
// Dashboard slot widgets:
//   'activity.OwnerUpcomingSlot'  — upcoming_activity slot (owner dashboard).
//   'activity.StaffActivitiesSlot'— my_activities slot     (staff dashboard).
//   'activity.StaffCountSlot'     — assigned_count slot    (staff dashboard).
//   'activity.ClientNextSlot'     — next_activity slot     (client dashboard).
//
// Calling convention: ActivityRegistry.register() is called in main.dart
// after ProviderScope and config are ready, or lazily by the first widget
// that needs an activity widget.
//
// See Blueprint Section 7 for the WidgetRegistry architecture.

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/activity/registry/activity_dashboard_slots.dart';
import 'package:personal_wellness_trainer/modules/activity/registry/booking_confirmation_card.dart';
import 'package:personal_wellness_trainer/modules/activity/registry/upcoming_session_card.dart';

abstract final class ActivityRegistry {
  /// Registers all activity widgets into the global WidgetRegistry.
  /// Safe to call multiple times (registry logs a warning on re-registration).
  static void register() {
    WidgetRegistry.register(
      'activity.BookingConfirmationCard',
      (context, data) => BookingConfirmationCard(data: data),
    );

    WidgetRegistry.register(
      'activity.UpcomingSessionCard',
      (context, data) => UpcomingSessionCard(data: data),
    );

    // ── Dashboard slots ───────────────────────────────────────────────────────

    WidgetRegistry.register(
      'activity.OwnerUpcomingSlot',
      (context, data) => const OwnerUpcomingSlot(),
    );

    WidgetRegistry.register(
      'activity.StaffActivitiesSlot',
      (context, data) => const StaffActivitiesSlot(),
    );

    WidgetRegistry.register(
      'activity.StaffCountSlot',
      (context, data) => const StaffCountSlot(),
    );

    WidgetRegistry.register(
      'activity.ClientNextSlot',
      (context, data) => const ClientNextSlot(),
    );
  }
}
