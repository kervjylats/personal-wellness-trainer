// lib/engine/config/notification_preferences_notifier.dart
//
// Stores which notification categories the owner wants to receive.
// Types: 'message', 'agreement', 'team', 'activity', 'system'
// Persisted in shared_preferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'ae_notification_prefs';

const List<String> notificationTypes = [
  'message',
  'agreement',
  'team',
  'activity',
  'system',
];

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, Map<String, bool>>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    // All enabled by default
    final defaults = {for (var t in notificationTypes) t: true};
    _loadFromPrefs().then((saved) {
      if (saved.isNotEmpty) {
        state = saved;
      }
    });
    return defaults;
  }

  Future<Map<String, bool>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_prefsKey);
    if (strings == null || strings.isEmpty) return {};
    final map = <String, bool>{};
    for (var s in strings) {
      final parts = s.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1] == 'true';
      }
    }
    return map;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = state.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_prefsKey, strings);
  }

  void toggleType(String type, bool enabled) {
    state = {...state, type: enabled};
    _saveToPrefs();
  }

  bool isEnabled(String type) => state[type] ?? true;
}

extension NotificationPrefsX on Map<String, bool> {
  bool isEnabled(String type) => this[type] ?? true;
}