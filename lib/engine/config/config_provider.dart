// lib/engine/config/config_provider.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/constants/asset_paths.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/config/job_definition.dart';

// ── ACTIVE JOB FILE PROVIDER (DEDICATED MODE) ─────────────────────────────
final activeJobFileProvider = FutureProvider<JobDefinition?>((ref) async {
  try {
    final jsonString = await rootBundle.loadString('assets/config/active_job.json');
    if (jsonString.trim().isEmpty) return null;
    
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return JobDefinition.fromJson(map);
  } catch (e) {
    AppLogger.debug('Active job file not present, running in dynamic mode.');
    return null;
  }
});

// ── MASTER CONFIG PROVIDER ────────────────────────────────────────────────
final configProvider = AsyncNotifierProvider<ConfigNotifier, AppEngineConfig>(
  ConfigNotifier.new,
);

class ConfigNotifier extends AsyncNotifier<AppEngineConfig> {
  static const String _tag = 'ConfigProvider';

  @override
  Future<AppEngineConfig> build() async {
    AppLogger.info('Loading configuration files…', tag: _tag);
    try {
      final results = await Future.wait([
        rootBundle.loadString(AssetPaths.appConfig),
        rootBundle.loadString(AssetPaths.industryConfig),
      ]);

      final buildConfig = AppBuildConfig.fromJson(
        jsonDecode(results[0]) as Map<String, dynamic>,
      );
      final industryConfig = IndustryConfig.fromJson(
        jsonDecode(results[1]) as Map<String, dynamic>,
      );

      return AppEngineConfig(
        build: buildConfig,
        industry: industryConfig,
      );
    } catch (e, st) {
      AppLogger.error('Failed to load configuration files',
          tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  void reload() => ref.invalidateSelf();
}

// ── DERIVED CONFIG PROVIDERS ──────────────────────────────────────────────
final industryConfigProvider = Provider<IndustryConfig>((ref) {
  return ref.watch(configProvider).requireValue.industry;
});

final buildConfigProvider = Provider<AppBuildConfig>((ref) {
  return ref.watch(configProvider).requireValue.build;
});