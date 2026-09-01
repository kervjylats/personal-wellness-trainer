// lib/modules/dashboard/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';

// ── Slot lists (mirrored from module_composition.json) ────────────────────────

abstract final class DashboardSlots {
  static const List<String> owner   = [
    'revenue_summary',
    'upcoming_activity',
    'team_count',
    'deal_count',
  ];
  static const List<String> partner = [
    'my_earnings',
    'active_deals',
    'upgrade_cta',
  ];
  static const List<String> staff   = [
    'my_activities',
    'assigned_count',
  ];
  static const List<String> client  = [
    'next_activity',
    'my_balance',
    'content_preview',
  ];
}

// ── Module dependency map ─────────────────────────────────────────────────────

const Map<String, String?> _slotModuleDep = {
  'revenue_summary':   'finance',
  'upcoming_activity': 'activity',
  'team_count':        'team',
  'deal_count':        'agreements',
  'my_earnings':       'finance',
  'active_deals':      'agreements',
  'upgrade_cta':       null,
  'my_activities':     'activity',
  'assigned_count':    'activity',
  'next_activity':     'activity',
  'my_balance':        'finance',
  'content_preview':   'media',
};

// ── Providers ─────────────────────────────────────────────────────────────────

final ownerDashboardSlotsProvider = Provider<List<String>>((ref) {
  final config = ref.watch(configProvider).valueOrNull;
  if (config == null) return [];
  return _filterSlots(DashboardSlots.owner, config);
});

final partnerDashboardSlotsProvider = Provider<List<String>>((ref) {
  final config = ref.watch(configProvider).valueOrNull;
  if (config == null) return DashboardSlots.partner;
  return _filterSlots(DashboardSlots.partner, config);
});

final staffDashboardSlotsProvider = Provider<List<String>>((ref) {
  final config = ref.watch(configProvider).valueOrNull;
  if (config == null) return [];
  return _filterSlots(DashboardSlots.staff, config);
});

final clientDashboardSlotsProvider = Provider<List<String>>((ref) {
  final config = ref.watch(configProvider).valueOrNull;
  if (config == null) return [];
  return _filterSlots(DashboardSlots.client, config);
});

// ── Filter helper ─────────────────────────────────────────────────────────────

List<String> _filterSlots(List<String> slots, dynamic config) {
  return slots.where((slot) {
    final moduleId = _slotModuleDep[slot];
    if (moduleId == null) return true;
    return (config as dynamic).isModuleAvailable(moduleId) as bool;
  }).toList();
}
