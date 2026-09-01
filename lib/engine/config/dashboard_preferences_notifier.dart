// lib/engine/config/dashboard_preferences_notifier.dart
//
// Stores which dashboard slot IDs the owner wants to see.
// Defaults to all slots from module_composition.json.
// Persisted in shared_preferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_wellness_trainer/modules/dashboard/providers/dashboard_provider.dart';

const _prefsKey = 'ae_dashboard_prefs';

final dashboardPreferencesProvider =
    NotifierProvider<DashboardPreferencesNotifier, Set<String>>(
  DashboardPreferencesNotifier.new,
);

class DashboardPreferencesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Start with all slots enabled; actual prefs will be loaded asynchronously
    final defaults = Set<String>.from(DashboardSlots.owner);
    _loadFromPrefs().then((saved) {
      if (saved.isNotEmpty) {
        state = saved;
      }
    });
    return defaults;
  }

  Future<Set<String>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_prefsKey);
    if (strings != null && strings.isNotEmpty) {
      return strings.toSet();
    }
    return {};
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state.toList());
  }

  void toggleSlot(String slotId, bool enabled) {
    if (enabled) {
      state = {...state, slotId};
    } else {
      state = state.where((s) => s != slotId).toSet();
    }
    _saveToPrefs();
  }

  bool isSlotEnabled(String slotId) => state.contains(slotId);
}