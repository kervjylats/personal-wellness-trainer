// lib/engine/config/industry_config.dart
//
// Dart model layer for the two runtime configuration files:
//
//   app_config.json      → AppBuildConfig  (which modules exist in this build)
//   industry_config.json → IndustryConfig  (industry identity, terminology, etc.)
//
// The top-level AppEngineConfig wraps both and is what ConfigProvider exposes.
// PermissionsEngine and all shells receive AppEngineConfig.
//
// All 10 blocks from Blueprint Section 11 are represented here.
//
// Design rules:
//   - Immutable. All fields are final.
//   - fromJson() factories for each model. No logic — pure data mapping.
//   - Industry-specific terminology is stored as raw strings from config.
//     The engine never hardcodes industry words. Ever.
//
// This file used to hold all ~20 config model classes directly (889 lines).
// The module-inclusion-flags family moved to modules_config.dart, and every
// other detail value class moved to config_schema.dart — this file now only
// holds the two "envelope" classes (IndustryConfig, AppEngineConfig) that
// actually reference all the others. The `export` lines below mean every
// existing `import '.../industry_config.dart'` elsewhere in the app keeps
// working exactly as before — nothing else needed to change.

import 'package:personal_wellness_trainer/core/theme/job_theme.dart';
import 'package:personal_wellness_trainer/engine/config/config_schema.dart';
import 'package:personal_wellness_trainer/engine/config/modules_config.dart';

export 'package:personal_wellness_trainer/engine/config/config_schema.dart';
export 'package:personal_wellness_trainer/engine/config/modules_config.dart';

class IndustryConfig {
  const IndustryConfig({
    required this.appName,
    required this.industryId,
    required this.industryDisplayName,
    required this.tagline,
    required this.primaryColor,
    required this.accentColor,
    required this.iconPath,
    required this.terminology,
    required this.modules,
    required this.navigation,
    required this.activityFields,
    required this.categories,
    required this.jobCategories,
    required this.compatibilityMatrix,
    required this.payment,
    required this.permissions,
    required this.upgrade,
    required this.theme,
    this.partnershipMarketplace,
    this.messagingSettings,
  });

  // Block 1 — Identity
  final String appName;
  final String industryId;
  final String industryDisplayName;
  final String tagline;

  /// Hex color string, e.g. '#2471A3'. Used to build the runtime ThemeData.
  final String primaryColor;
  final String accentColor;
  final String iconPath;

  // Block 2 — Terminology
  final ConfigTerminology terminology;

  // Block 3 — Active Modules (within what AppBuildConfig included)
  final ConfigModules modules;

  // Block 4 — Navigation
  final ConfigNavigation navigation;

  // Block 5 — Activity Form Fields
  final List<ActivityField> activityFields;

  // Block 6 — Categories
  final List<ConfigCategory> categories;

  final List<JobCategory> jobCategories;

  // Block 7 — Compatibility Matrix
  final List<List<String>> compatibilityMatrix;

  // Block 8 — Payment Model
  final ConfigPayment payment;

  // Block 9 — Permissions
  final ConfigPermissions permissions;

  // Block 10 — Upgrade Prompt
  final ConfigUpgrade upgrade;

  // Block 11 — Partnership Marketplace
  final ConfigMarketplace? partnershipMarketplace;

  /// Visual theme configuration (Phase 9 template engine).
  final JobTheme theme;

  /// Which modules contribute attachment buttons to the chat input bar.
  final ConfigMessagingSettings? messagingSettings;

  factory IndustryConfig.fromJson(Map<String, dynamic> json) {
    return IndustryConfig(
      appName:             json['app_name'] as String? ?? 'App Engine',
      industryId:          json['industry_id'] as String? ?? 'generic',
      industryDisplayName: json['industry_display_name'] as String? ?? 'Generic',
      tagline:             json['tagline'] as String? ?? '',
      primaryColor:        json['primary_color'] as String? ?? '#2471A3',
      accentColor:         json['accent_color'] as String? ?? '#1ABC9C',
      iconPath:            json['icon_path'] as String? ?? '',
      terminology: ConfigTerminology.fromJson(
        json['terminology'] as Map<String, dynamic>? ?? {},
      ),
      modules: ConfigModules.fromJson(
        json['modules'] as Map<String, dynamic>? ?? {},
      ),
      navigation: ConfigNavigation.fromJson(
        json['navigation'] as Map<String, dynamic>? ?? {},
      ),
      activityFields: (json['activity_fields'] as List<dynamic>? ?? [])
          .map((e) => ActivityField.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => ConfigCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      compatibilityMatrix:
          (json['compatibility_matrix'] as List<dynamic>? ?? [])
              .map((pair) => (pair as List<dynamic>)
                  .map((e) => e as String)
                  .toList())
              .toList(),
      payment: ConfigPayment.fromJson(
        json['payment'] as Map<String, dynamic>? ?? {},
      ),
      permissions: ConfigPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>? ?? {},
      ),
      upgrade: ConfigUpgrade.fromJson(
        json['upgrade'] as Map<String, dynamic>? ?? {},
      ),
      theme: JobTheme.fromJson(json['theme'] as Map<String, dynamic>? ?? {}),
      jobCategories: (json['job_categories'] as List<dynamic>? ?? [])
          .map((e) => JobCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      messagingSettings: json['messaging'] is Map
          ? ConfigMessagingSettings.fromJson(
              json['messaging'] as Map<String, dynamic>)
          : null,
      partnershipMarketplace: json['partnership_marketplace'] != null
          ? ConfigMarketplace.fromJson(
              json['partnership_marketplace'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AppEngineConfig {
  const AppEngineConfig({
    required this.build,
    required this.industry,
  });

  final AppBuildConfig build;
  final IndustryConfig industry;

  /// Convenience: true only if the module is active at BOTH Level 1 and Level 2.
  /// This is the minimum bar — PermissionsEngine adds Level 3 on top.
  bool isModuleAvailable(String moduleId) {
    return build.modulesIncluded.isIncluded(moduleId) &&
        industry.modules.isActive(moduleId);
  }
}

