// lib/engine/registry/widget_registry.dart
//
// The Widget Registry solves cross-module widget sharing without direct imports.
// Direct imports between modules create circular dependencies — the registry
// eliminates this. See Blueprint Section 7.
//
// How it works (the "Lego table" analogy from the Blueprint):
//   1. App starts → config loads → active modules call WidgetRegistry.register()
//      to put their shareable widgets "on the table".
//   2. Any screen that needs those widgets calls WidgetRegistry.get() to
//      pick up what is available.
//   3. If a module was not compiled or not active, its widgets were never
//      registered — the caller gets null and handles it gracefully.
//
// Phase 1 status: The registry infrastructure is in place but no modules
// have registered any widgets yet. Modules register their widgets in their
// own registry/ subdirectory (e.g. lib/modules/activity/registry/).
// Those registrations call WidgetRegistry.register() at app startup.
//
// Widget keys follow the convention: 'moduleId.widgetName'
// Example: 'activity.BookingConfirmationCard', 'media.MediaThumbnailCard'

import 'package:flutter/widgets.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';

// ── Widget builder type ───────────────────────────────────────────────────────

/// A function that builds a registered widget, optionally receiving
/// a data payload from the caller.
typedef RegistryWidgetBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic>? data,
);

// ── Registry ──────────────────────────────────────────────────────────────────

abstract final class WidgetRegistry {
  static const String _tag = 'WidgetRegistry';

  static final Map<String, RegistryWidgetBuilder> _registry = {};

  /// Registers a widget builder under the given [key].
  /// Convention: key = 'moduleId.WidgetName'
  /// Safe to call multiple times — re-registration logs a warning.
  static void register(String key, RegistryWidgetBuilder builder) {
    if (_registry.containsKey(key)) {
      AppLogger.warning(
        'WidgetRegistry: "$key" is already registered — overwriting.',
        tag: _tag,
      );
    }
    _registry[key] = builder;
    AppLogger.debug('WidgetRegistry: registered "$key"', tag: _tag);
  }

  /// Returns the builder for [key], or null if not registered.
  /// The caller decides how to handle null (graceful degradation,
  /// not a crash — see Blueprint Section 7).
  static RegistryWidgetBuilder? get(String key) {
    return _registry[key];
  }

  /// Builds and returns the registered widget for [key].
  /// Returns [fallback] if the key is not registered.
  static Widget build(
    String key,
    BuildContext context, {
    Map<String, dynamic>? data,
    Widget fallback = const SizedBox.shrink(),
  }) {
    final builder = _registry[key];
    if (builder == null) {
      AppLogger.debug(
        'WidgetRegistry: "$key" not registered — using fallback.',
        tag: _tag,
      );
      return fallback;
    }
    return builder(context, data);
  }

  /// Returns all currently registered widget keys.
  /// Useful for debugging and during development.
  static List<String> get registeredKeys => List.unmodifiable(_registry.keys);

  /// Removes a registered widget. Primarily used in tests.
  static void unregister(String key) {
    _registry.remove(key);
  }

  /// Clears all registrations. Used in tests only.
  static void clearAll() {
    _registry.clear();
    AppLogger.debug('WidgetRegistry: cleared all registrations.', tag: _tag);
  }
}
