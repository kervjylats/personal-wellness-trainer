// lib/engine/config/modules_config.dart
//
// The "which modules are included/enabled" family: ModulesIncluded is the
// industry-level default set (from industry_config.json), ConfigModules is
// the job-level override set (from a specific job's config) — two distinct
// types since they mean different things at different layers, but they
// share identical field-parsing logic via the private _ModuleFlags helper.
//
// Split out of industry_config.dart, which had grown to 889 lines.

class ModulesIncluded {
  const ModulesIncluded({
    required this.activity,
    required this.finance,
    required this.team,
    required this.messaging,
    required this.notifications,
    required this.agreements,
    required this.media,
    required this.catalog,
    required this.gps,
    required this.deliveryFees,
    required this.scheduling,
    required this.reservations,
    required this.inventory,
    required this.reviews,
  });

  final bool activity;
  final bool finance;
  final bool team;
  final bool messaging;
  final bool notifications;
  final bool agreements;
  final bool media;
  final bool catalog;
  final bool gps;
  final bool deliveryFees;
  final bool scheduling;
  final bool reservations;
  final bool inventory;
  final bool reviews;

  /// Returns true if the named module is included in this build.
  /// This is a Level 1 check — use PermissionsEngine for runtime checks.
  bool isIncluded(String moduleId) {
    switch (moduleId) {
      case 'activity':       return activity;
      case 'finance':        return finance;
      case 'team':           return team;
      case 'messaging':      return messaging;
      case 'notifications':  return notifications;
      case 'agreements':     return agreements;
      case 'media':          return media;
      case 'catalog':        return catalog;
      case 'gps':            return gps;
      case 'delivery_fees':  return deliveryFees;
      case 'scheduling':     return scheduling;
      case 'reservations':   return reservations;
      case 'inventory':      return inventory;
      case 'reviews':        return reviews;
      default:               return false;
    }
  }

  factory ModulesIncluded.fromJson(Map<String, dynamic> json) {
    final f = _ModuleFlags.fromJson(json);
    return ModulesIncluded(
      activity: f.activity,
      finance: f.finance,
      team: f.team,
      messaging: f.messaging,
      notifications: f.notifications,
      agreements: f.agreements,
      media: f.media,
      catalog: f.catalog,
      gps: f.gps,
      deliveryFees: f.deliveryFees,
      scheduling: f.scheduling,
      reservations: f.reservations,
      inventory: f.inventory,
      reviews: f.reviews,
    );
  }
}

class _ModuleFlags {
  const _ModuleFlags({
    required this.activity,
    required this.finance,
    required this.team,
    required this.messaging,
    required this.notifications,
    required this.agreements,
    required this.media,
    required this.catalog,
    required this.gps,
    required this.deliveryFees,
    required this.scheduling,
    required this.reservations,
    required this.inventory,
    required this.reviews,
  });

  factory _ModuleFlags.fromJson(Map<String, dynamic> json) {
    return _ModuleFlags(
      activity:      json['activity'] as bool? ?? true,
      finance:       json['finance'] as bool? ?? true,
      team:          json['team'] as bool? ?? true,
      messaging:     json['messaging'] as bool? ?? true,
      notifications: json['notifications'] as bool? ?? true,
      agreements:    json['agreements'] as bool? ?? true,
      media:         json['media'] as bool? ?? false,
      catalog:       json['catalog'] as bool? ?? false,
      gps:           json['gps'] as bool? ?? false,
      deliveryFees:  json['delivery_fees'] as bool? ?? false,
      scheduling:    json['scheduling'] as bool? ?? false,
      reservations:  json['reservations'] as bool? ?? false,
      inventory:     json['inventory'] as bool? ?? false,
      reviews:       json['reviews'] as bool? ?? false,
    );
  }

  final bool activity;
  final bool finance;
  final bool team;
  final bool messaging;
  final bool notifications;
  final bool agreements;
  final bool media;
  final bool catalog;
  final bool gps;
  final bool deliveryFees;
  final bool scheduling;
  final bool reservations;
  final bool inventory;
  final bool reviews;
}

class ConfigModules {
  const ConfigModules({
    required this.activity,
    required this.finance,
    required this.team,
    required this.messaging,
    required this.notifications,
    required this.agreements,
    required this.media,
    required this.catalog,
    required this.gps,
    required this.deliveryFees,
    required this.scheduling,
    required this.reservations,
    required this.inventory,
    required this.reviews,
  });

  final bool activity;
  final bool finance;
  final bool team;
  final bool messaging;
  final bool notifications;
  final bool agreements;
  final bool media;
  final bool catalog;
  final bool gps;
  final bool deliveryFees;
  final bool scheduling;
  final bool reservations;
  final bool inventory;
  final bool reviews;

  /// Returns true if the named module is active at the industry config level.
  bool isActive(String moduleId) {
    switch (moduleId) {
      case 'activity':      return activity;
      case 'finance':       return finance;
      case 'team':          return team;
      case 'messaging':     return messaging;
      case 'notifications': return notifications;
      case 'agreements':    return agreements;
      case 'media':         return media;
      case 'catalog':       return catalog;
      case 'gps':           return gps;
      case 'delivery_fees': return deliveryFees;
      case 'scheduling':    return scheduling;
      case 'reservations':  return reservations;
      case 'inventory':     return inventory;
      case 'reviews':       return reviews;
      default:              return false;
    }
  }

  factory ConfigModules.fromJson(Map<String, dynamic> json) {
    final f = _ModuleFlags.fromJson(json);
    return ConfigModules(
      activity: f.activity,
      finance: f.finance,
      team: f.team,
      messaging: f.messaging,
      notifications: f.notifications,
      agreements: f.agreements,
      media: f.media,
      catalog: f.catalog,
      gps: f.gps,
      deliveryFees: f.deliveryFees,
      scheduling: f.scheduling,
      reservations: f.reservations,
      inventory: f.inventory,
      reviews: f.reviews,
    );
  }
}

