// lib/engine/providers/dashboard_refresh_bus.dart
//
// A shared refresh signal for all dashboard screens.
//
// How it works:
//   1. A dashboard screen's RefreshIndicator calls:
//        ref.read(dashboardRefreshBusProvider.notifier).state++;
//   2. Each slot widget has a ref.listen on this provider.
//      When the counter increments, the slot invalidates its own backing
//      provider — which triggers its AsyncNotifier to reload from the source.
//
// Why this bus exists:
//   Dashboard screens cannot import module providers directly (Blueprint §14 —
//   cross-module imports are forbidden). The bus lives in engine/providers/,
//   which every layer is allowed to import. The slot widgets (which live inside
//   their own module) are the only ones that know which provider to invalidate.
//   The dashboard screen just fires the signal; it never knows what is behind it.
//
// This is the same pattern as module_error_bus.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented by dashboard screens on pull-to-refresh.
/// Watched by slot widgets — each slot invalidates its own provider on change.
final dashboardRefreshBusProvider = StateProvider<int>((ref) => 0);
