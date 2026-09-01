// lib/engine/config/config_schema.dart
//
// The detail value classes making up industry_config.json / app_config.json,
// aside from IndustryConfig/AppEngineConfig themselves (those two stay in
// industry_config.dart) and the module-flags family (in modules_config.dart).
//
// Split out of industry_config.dart, which had grown to 889 lines.
//
// Design rules (same as the rest of the config layer):
//   - Immutable. All fields are final.
//   - fromJson() factories for each model. No logic — pure data mapping.
//   - Industry-specific terminology is stored as raw strings from config.
//     The engine never hardcodes industry words. Ever.

import 'package:personal_wellness_trainer/engine/config/modules_config.dart';

class AppBuildConfig {
  const AppBuildConfig({
    required this.buildName,
    required this.version,
    required this.modulesIncluded,
    required this.mediaTypes,
    required this.paymentProviders,
    required this.ownerHasControlPanel,
    required this.ownerCanInvitePartners,
    required this.ownerCanManageClientContent,
  });

  final String buildName;
  final String version;
  final ModulesIncluded modulesIncluded;
  final MediaTypes mediaTypes;
  final PaymentProviders paymentProviders;
  final bool ownerHasControlPanel;
  final bool ownerCanInvitePartners;
  final bool ownerCanManageClientContent;

  factory AppBuildConfig.fromJson(Map<String, dynamic> json) {
    return AppBuildConfig(
      buildName: json['build_name'] as String? ?? 'App Engine',
      version: json['version'] as String? ?? '1.0.0',
      modulesIncluded: ModulesIncluded.fromJson(
        json['modules_included'] as Map<String, dynamic>? ?? {},
      ),
      mediaTypes: MediaTypes.fromJson(
        json['media_types'] as Map<String, dynamic>? ?? {},
      ),
      paymentProviders: PaymentProviders.fromJson(
        json['payment_providers'] as Map<String, dynamic>? ?? {},
      ),
      ownerHasControlPanel:
          json['owner_has_control_panel'] as bool? ?? true,
      ownerCanInvitePartners:
          json['owner_can_invite_partners'] as bool? ?? true,
      ownerCanManageClientContent:
          json['owner_can_manage_client_content'] as bool? ?? true,
    );
  }
}

class MediaTypes {
  const MediaTypes({
    required this.video,
    required this.audio,
    required this.pdf,
    required this.images,
  });

  final bool video;
  final bool audio;
  final bool pdf;
  final bool images;

  factory MediaTypes.fromJson(Map<String, dynamic> json) {
    return MediaTypes(
      video:  json['video'] as bool? ?? true,
      audio:  json['audio'] as bool? ?? true,
      pdf:    json['pdf'] as bool? ?? true,
      images: json['images'] as bool? ?? true,
    );
  }
}

class PaymentProviders {
  const PaymentProviders({
    required this.stripe,
    required this.paypal,
    required this.manual,
  });

  final bool stripe;
  final bool paypal;

  /// Manual is always present — cannot be disabled.
  final bool manual;

  factory PaymentProviders.fromJson(Map<String, dynamic> json) {
    return PaymentProviders(
      stripe: json['stripe'] as bool? ?? false,
      paypal: json['paypal'] as bool? ?? false,
      manual: true, // Manual is always enabled — hardcoded engine rule.
    );
  }
}

class ConfigTerminology {
  const ConfigTerminology({
    required this.owner,
    required this.partner,
    required this.staff,
    required this.client,
    required this.activity,
    required this.activities,
    required this.network,
    required this.agreement,
    required this.finance,
    required this.team,
    required this.media,
    required this.catalog,
    required this.dashboard,
  });

  final String owner;
  final String partner;
  final String staff;
  final String client;
  final String activity;
  final String activities;
  final String network;
  final String agreement;
  final String finance;
  final String team;
  final String media;
  final String catalog;
  final String dashboard;

  /// Returns the display label for an entity type by its key.
  /// Defaults to the key itself if not found — never crashes.
  String labelFor(String key) {
    switch (key) {
      case 'owner':      return owner;
      case 'partner':    return partner;
      case 'staff':      return staff;
      case 'client':     return client;
      case 'activity':   return activity;
      case 'activities': return activities;
      case 'network':    return network;
      case 'agreement':  return agreement;
      case 'finance':    return finance;
      case 'team':       return team;
      case 'media':      return media;
      case 'catalog':    return catalog;
      case 'dashboard':  return dashboard;
      default:           return key;
    }
  }

  factory ConfigTerminology.fromJson(Map<String, dynamic> json) {
    return ConfigTerminology(
      owner:      json['owner'] as String? ?? 'Owner',
      partner:    json['partner'] as String? ?? 'Partner',
      staff:      json['staff'] as String? ?? 'Staff',
      client:     json['client'] as String? ?? 'Client',
      activity:   json['activity'] as String? ?? 'Activity',
      activities: json['activities'] as String? ?? 'Activities',
      network:    json['network'] as String? ?? 'Network',
      agreement:  json['agreement'] as String? ?? 'Agreement',
      finance:    json['finance'] as String? ?? 'Finance',
      team:       json['team'] as String? ?? 'Team',
      media:      json['media'] as String? ?? 'Media',
      catalog:    json['catalog'] as String? ?? 'Catalog',
      dashboard:  json['dashboard'] as String? ?? 'Dashboard',
    );
  }
}

class ConfigNavigation {
  const ConfigNavigation({required this.tabs});

  /// Max 4 tabs. Dashboard is always first — enforced by PermissionsEngine.
  final List<NavTab> tabs;

  factory ConfigNavigation.fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'] as List<dynamic>? ?? [];
    return ConfigNavigation(
      tabs: rawTabs
          .map((e) => NavTab.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NavTab {
  const NavTab({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final String icon;
  final String label;

  factory NavTab.fromJson(Map<String, dynamic> json) {
    return NavTab(
      id:    json['id'] as String,
      icon:  json['icon'] as String? ?? 'circle_outlined',
      label: json['label'] as String? ?? '',
    );
  }
}

class ActivityField {
  const ActivityField({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    this.options,
  });

  final String name;
  final String label;

  /// Field type. Supported: text | textarea | number | currency | dropdown |
  /// date | time | datetime | duration | boolean | staff_picker |
  /// client_picker | location | image_upload
  final String type;
  final bool required;

  /// Non-null when type is 'dropdown'. Contains the option strings.
  final List<String>? options;

  factory ActivityField.fromJson(Map<String, dynamic> json) {
    return ActivityField(
      name:     json['name'] as String,
      label:    json['label'] as String? ?? '',
      type:     json['type'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      options:  (json['options'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList(),
    );
  }
}

class ConfigCategory {
  const ConfigCategory({
    required this.id,
    required this.label,
    required this.group,
  });

  final String id;
  final String label;
  final String group;

  factory ConfigCategory.fromJson(Map<String, dynamic> json) {
    return ConfigCategory(
      id:    json['id'] as String,
      label: json['label'] as String? ?? '',
      group: json['group'] as String? ?? '',
    );
  }
}

class JobCategory {
  final String id;
  final String label;
  final String icon;
  final String color; // optional, defaults to primary if not provided

  const JobCategory({
    required this.id,
    required this.label,
    required this.icon,
    this.color = '#2471A3',
  });

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String? ?? 'business_center',
      color: json['color'] as String? ?? '#2471A3',
    );
  }
}

class ConfigPayment {
  const ConfigPayment({
    required this.model,
    required this.currencyDefault,
    required this.commissionType,
    required this.clientPaysVia,
  });

  /// Values: 'upfront' | 'post_service' | 'subscription' | 'commission_only'
  final String model;

  /// Currency symbol, e.g. '$', '€', '£'.
  final String currencyDefault;

  /// Values: 'percentage' | 'fixed' | 'tiered'
  final String commissionType;

  /// Values: 'in_app' | 'cash_on_delivery' | 'invoice' | 'bank_transfer'
  final String clientPaysVia;

  factory ConfigPayment.fromJson(Map<String, dynamic> json) {
    return ConfigPayment(
      model:           json['model'] as String? ?? 'upfront',
      currencyDefault: json['currency_default'] as String? ?? r'$',
      commissionType:  json['commission_type'] as String? ?? 'percentage',
      clientPaysVia:   json['client_pays_via'] as String? ?? 'in_app',
    );
  }
}

class ConfigPermissions {
  const ConfigPermissions({
    required this.staff,
    required this.partner,
    required this.client,
  });

  final Map<String, PermissionRule> staff;
  final Map<String, PermissionRule> partner;
  final Map<String, PermissionRule> client;

  factory ConfigPermissions.fromJson(Map<String, dynamic> json) {
    return ConfigPermissions(
      staff:   _parseRolePermissions(
                 json['staff'] as Map<String, dynamic>? ?? {},
               ),
      partner: _parseRolePermissions(
                 json['partner'] as Map<String, dynamic>? ?? {},
               ),
      client:  _parseRolePermissions(
                 json['client'] as Map<String, dynamic>? ?? {},
               ),
    );
  }

  static Map<String, PermissionRule> _parseRolePermissions(
    Map<String, dynamic> json,
  ) {
    return json.map(
      (key, value) => MapEntry(
        key,
        PermissionRule.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}

class PermissionRule {
  const PermissionRule({
    required this.defaultValue,
    required this.ownerCanToggle,
    required this.locked,
  });

  /// The default state before any owner override.
  final bool defaultValue;

  /// Whether the owner can toggle this per-individual in the Control Panel.
  final bool ownerCanToggle;

  /// If true, the permission is immutable — no toggle available.
  final bool locked;

  factory PermissionRule.fromJson(Map<String, dynamic> json) {
    final isLocked = json['locked'] as bool? ?? false;
    return PermissionRule(
      defaultValue:   json['default'] as bool? ?? false,
      ownerCanToggle: isLocked
          ? false
          : json['owner_can_toggle'] as bool? ?? false,
      locked:         isLocked,
    );
  }
}

class ConfigUpgrade {
  const ConfigUpgrade({
    required this.enabled,
    required this.url,
    required this.buttonLabel,
    required this.subtitle,
  });

  /// The upgrade prompt is always shown in the partner shell regardless
  /// of this flag. This flag only controls extra placements.
  final bool enabled;
  final String url;
  final String buttonLabel;
  final String subtitle;

  factory ConfigUpgrade.fromJson(Map<String, dynamic> json) {
    return ConfigUpgrade(
      enabled:     json['enabled'] as bool? ?? true,
      url:         json['url'] as String? ?? '',
      buttonLabel: json['button_label'] as String? ?? 'Upgrade to Pro',
      subtitle:    json['subtitle'] as String?
                     ?? 'Get your own platform with full owner access',
    );
  }
}

class ConfigMarketplace {
  const ConfigMarketplace({
    required this.enabled,
    required this.showBusinessName,
    required this.showRating,
    required this.showTagline,
    required this.requestMessageRequired,
  });

  /// Master switch — when false the marketplace entry point is hidden.
  final bool enabled;

  /// Whether to show the business name on the public profile card.
  final bool showBusinessName;

  /// Whether to show the average rating on the public profile card.
  final bool showRating;

  /// Whether to show the tagline on the public profile card.
  final bool showTagline;

  /// When true, a non-empty message is required before sending a request.
  final bool requestMessageRequired;

  factory ConfigMarketplace.fromJson(Map<String, dynamic> json) {
    return ConfigMarketplace(
      enabled:                json['enabled'] as bool? ?? true,
      showBusinessName:       json['show_business_name'] as bool? ?? true,
      showRating:             json['show_rating'] as bool? ?? true,
      showTagline:            json['show_tagline'] as bool? ?? true,
      requestMessageRequired: json['request_message_required'] as bool? ?? false,
    );
  }

  /// Safe default used when partnership_marketplace block is absent from config.
  static const ConfigMarketplace defaults = ConfigMarketplace(
    enabled: true,
    showBusinessName: true,
    showRating: true,
    showTagline: true,
    requestMessageRequired: false,
  );
}

class ConfigMessagingSettings {
  const ConfigMessagingSettings({required this.attachments});

  /// Module IDs whose attachment buttons appear in the chat input bar.
  /// Only modules also active in ConfigModules will actually appear.
  final List<String> attachments;

  factory ConfigMessagingSettings.fromJson(Map<String, dynamic> json) {
    return ConfigMessagingSettings(
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  bool hasAttachment(String moduleId) => attachments.contains(moduleId);
}

