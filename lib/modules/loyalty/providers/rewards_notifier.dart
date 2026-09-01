// lib/modules/loyalty/providers/rewards_notifier.dart
//
// Riverpod notifier for the owner's reward management.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/loyalty_models.dart';
import 'package:personal_wellness_trainer/data/repositories/loyalty_repository.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/loyalty/providers/loyalty_notifier.dart';

final rewardsNotifierProvider =
    AsyncNotifierProvider<RewardsNotifier, List<Reward>>(
  RewardsNotifier.new,
  dependencies: [authNotifierProvider],
);

class RewardsNotifier extends AsyncNotifier<List<Reward>> {
  static const String _tag = 'RewardsNotifier';

  LoyaltyRepository get _repo => ref.read(loyaltyRepositoryProvider);

  @override
  Future<List<Reward>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    return _repo.getRewards(auth.profile.businessId);
  }

  Future<Reward?> create({
    required String title,
    String description = '',
    required int pointsCost,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;
    try {
      final reward = await _repo.createReward(
        businessId: auth.profile.businessId,
        title: title,
        description: description,
        pointsCost: pointsCost,
      );
      ref.invalidateSelf();
      return reward;
    } catch (e, st) {
      AppLogger.error('create reward failed', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> delete(String rewardId) async {
    try {
      await _repo.deleteReward(rewardId);
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error('delete reward failed', tag: _tag, error: e, stackTrace: st);
    }
  }
}
