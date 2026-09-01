// lib/engine/config/jobs_config_provider.dart
//
// Provides the full JobsRegistry (all available job definitions) and
// a helper to resolve the active IndustryConfig for a given job ID.
//
// Provider hierarchy:
//   jobsRegistryProvider   → AsyncNotifier<JobsRegistry>
//                            Loads jobs_config.json once at startup.
//
//   activeJobConfigProvider → reads jobsRegistryProvider + configProvider,
//                             resolves the active IndustryConfig from the
//                             authenticated owner's job_id.
//
// In mock mode (Phase 1–9):
//   The active job ID comes from the owner mock profile's jobId field.
//   Swap MockProfiles.ownerProfile.jobId to test different job types.
//
// In production (Phase 10+):
//   The job ID is stored in the Supabase business_profiles table and
//   loaded into UserProfile.jobId at sign-in.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/constants/asset_paths.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/config/job_definition.dart';

// ── jobsRegistryProvider ──────────────────────────────────────────────────────

final jobsRegistryProvider =
    AsyncNotifierProvider<JobsRegistryNotifier, JobsRegistry>(
  JobsRegistryNotifier.new,
);

class JobsRegistryNotifier extends AsyncNotifier<JobsRegistry> {
  static const String _tag = 'JobsRegistry';

  @override
  Future<JobsRegistry> build() async {
    AppLogger.info('Loading jobs_config.json…', tag: _tag);
    try {
      final raw = await rootBundle.loadString(AssetPaths.jobsConfig);
      final registry = JobsRegistry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      AppLogger.info(
        'Jobs loaded: ${registry.length} job type(s)',
        tag: _tag,
      );
      return registry;
    } catch (e, st) {
      AppLogger.error(
        'Failed to load jobs_config.json',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  void reload() => ref.invalidateSelf();
}

// ── activeJobConfigProvider ───────────────────────────────────────────────────

/// Resolves the active IndustryConfig for the current user.
///
/// Resolution order:
///   1. Read the authenticated owner's jobId from their profile.
///   2. Look up the matching JobDefinition in the JobsRegistry.
///   3. Call jobDef.toIndustryConfig(platformBase) to produce a merged config.
///
/// Falls back to the platform base IndustryConfig if:
///   - The user has no jobId (staff / client / partner — they inherit the
///     owner's job config via the business they belong to).
///   - The jobId doesn't match any registered job definition.
///   - The jobs registry hasn't loaded yet.
///
/// All shells and modules should watch activeJobConfigProvider instead of
/// configProvider.industry when they need the job-specific terminology,
/// modules, or activity fields.
final activeJobConfigProvider = Provider<IndustryConfig>(
  (ref) {
  final configAsync = ref.watch(configProvider);
  final platformBase = configAsync.valueOrNull?.industry;
  if (platformBase == null) {
    // Config not yet loaded — return a sensible default.
    return IndustryConfig.fromJson(const {});
  }

  final registryAsync = ref.watch(jobsRegistryProvider);
  final registry = registryAsync.valueOrNull;
  if (registry == null || !registry.isNotEmpty) {
    // Jobs not yet loaded or empty registry — fall back to platform config.
    return platformBase;
  }

  // Read the owner's job ID from their profile.
  final authState = ref.watch(authNotifierProvider);
  String? jobId;
  if (authState is AuthAuthenticated) {
    jobId = authState.profile.jobId;
  }

  if (jobId == null || jobId.isEmpty) {
    // No job selected yet (e.g. brand new owner mid-onboarding, or
    // staff / partner / client who inherit from the business).
    return platformBase;
  }

  final jobDef = registry.byId(jobId);
  if (jobDef == null) {
    AppLogger.warning(
      'activeJobConfigProvider: jobId "$jobId" not found in registry — '
      'falling back to platform config.',
      tag: 'JobsConfig',
    );
    return platformBase;
  }

  return jobDef.toIndustryConfig(platformBase);
  },
  // See lib/dev_tools/qa_console_screen.dart — this provider reads
  // authNotifierProvider, so it must declare that dependency for
  // Riverpod's override-scoping check to pass wherever authNotifierProvider
  // is overridden (the QA Console's 4 role panels).
  dependencies: [authNotifierProvider],
);
