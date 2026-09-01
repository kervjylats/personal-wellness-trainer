// lib/engine/config/job_definition.dart
//
// JobDefinition is the data model for a single job entry in jobs_config.json.
// It is self-contained: it carries its own terminology, module flags, and
// activity field definitions. When an owner selects their job during onboarding,
// their chosen JobDefinition becomes the active IndustryConfig for their shell.
//
// Design rules:
//   - Immutable. All fields are final.
//   - fromJson() factory — pure data mapping, no logic.
//   - toIndustryConfig() converts a JobDefinition into a full IndustryConfig,
//     merging with the platform-level IndustryConfig for fields not defined
//     per-job (app name, upgrade config, compatibility matrix, etc.).
//   - ZERO industry-specific words in this file.

import 'package:personal_wellness_trainer/core/theme/job_theme.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';

// ── JobDefinition ─────────────────────────────────────────────────────────────
class JobDefinition {
  const JobDefinition({
    required this.id,
    required this.category,
    required this.label,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.terminology,
    required this.modules,
    required this.activityFields,
    required this.theme,
  });

  /// Unique identifier. Stored in UserProfile.jobId and business_profiles table.
  final String id;

  final String category;

  /// Human-readable label shown on the onboarding job-picker card.
  final String label;
  /// Short description shown below the label on the job-picker card.
  final String description;

  /// Material icon name string. Resolved via navTabIconFromString() in the UI.
  final String icon;

  /// Hex colour string, e.g. '#2471A3'. Overrides platform primary colour.
  final String primaryColor;

  /// Terminology overrides for this job type.
  final ConfigTerminology terminology;

  /// Which modules are active for this job type.
  final ConfigModules modules;

  /// Activity form field definitions for this job type.
  final List<ActivityField> activityFields;

  /// Visual theme configuration for this job type.
  final JobTheme theme;

  factory JobDefinition.fromJson(Map<String, dynamic> json) {
    return JobDefinition(
      id:          json['id'] as String,
      category:    json['category'] as String? ?? 'generic',
      label:       json['label'] as String? ?? 'Business',
      description: json['description'] as String? ?? '',
      icon:        json['icon'] as String? ?? 'business_center',
      primaryColor: json['primary_color'] as String? ?? '#2471A3',
      terminology: ConfigTerminology.fromJson(
        json['terminology'] as Map<String, dynamic>? ?? {},
      ),
      modules: ConfigModules.fromJson(
        json['modules'] as Map<String, dynamic>? ?? {},
      ),
      activityFields: (json['activity_fields'] as List<dynamic>? ?? [])
          .map((e) => ActivityField.fromJson(e as Map<String, dynamic>))
          .toList(),
      theme: JobTheme.fromJson(json['theme'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Converts this JobDefinition into a full IndustryConfig by merging with
  /// the platform-level base config (app name, categories, compatibility matrix,
  /// payment model, permissions, upgrade config, navigation, marketplace config).
  ///
  /// The platform base config supplies everything that is app-wide.
  /// The job definition overrides: terminology, modules, activity fields,
  /// primary colour, and industry identity fields.
  IndustryConfig toIndustryConfig(IndustryConfig platformBase) {
    return IndustryConfig(
      // Identity — job overrides industry label and colour.
      appName:             platformBase.appName,
      industryId:          id,
      industryDisplayName: label,
      tagline:             description,
      primaryColor:        primaryColor,
      accentColor:         platformBase.accentColor,
      iconPath:            platformBase.iconPath,

      // Job-specific overrides.
      terminology:    terminology,
      modules:        modules,
      activityFields: activityFields,
      theme:          theme,

      // Platform-level — shared across all jobs in this app.
      navigation:             platformBase.navigation,
      categories:             platformBase.categories,
      jobCategories:          platformBase.jobCategories,
      compatibilityMatrix:    platformBase.compatibilityMatrix,
      payment:                platformBase.payment,
      permissions:            platformBase.permissions,
      upgrade:                platformBase.upgrade,
      partnershipMarketplace: platformBase.partnershipMarketplace,
      messagingSettings:      platformBase.messagingSettings,
    );
  }
}

// ── JobsRegistry ──────────────────────────────────────────────────────────────

/// In-memory registry of all job definitions loaded from jobs_config.json.
/// Provides O(1) lookup by job ID.
class JobsRegistry {
  const JobsRegistry(this._jobs);

  final List<JobDefinition> _jobs;

  /// All job definitions in display order.
  List<JobDefinition> get all => List.unmodifiable(_jobs);

  /// Returns the job with [id], or null if not found.
  JobDefinition? byId(String id) {
    try {
      return _jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  /// True if there is at least one job defined.
  bool get isNotEmpty => _jobs.isNotEmpty;

  /// Number of available jobs.
  int get length => _jobs.length;

  factory JobsRegistry.fromJson(Map<String, dynamic> json) {
    final jobs = (json['jobs'] as List<dynamic>? ?? [])
        .map((e) => JobDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
    return JobsRegistry(jobs);
  }
}
