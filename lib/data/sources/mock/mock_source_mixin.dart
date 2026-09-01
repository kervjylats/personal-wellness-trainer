// lib/data/sources/mock/mock_source_mixin.dart
import 'package:personal_wellness_trainer/core/constants/app_constants.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

mixin MockSourceMixin {
  /// Asserts mock mode is active and simulates network latency.
  ///
  /// Pass [duration] to override the default [AppConstants.mockDelay] —
  /// useful for sources that intentionally simulate a faster/slower
  /// round-trip (e.g. notification polling) than the standard delay.
  Future<void> simulateNetworkDelay([Duration? duration]) async {
    assert(DataConfig.useMockData);
    await Future<void>.delayed(duration ?? AppConstants.mockDelay);
  }
}