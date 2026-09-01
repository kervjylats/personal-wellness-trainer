// lib/data/repositories/loyalty_repository.dart

import 'package:personal_wellness_trainer/data/models/loyalty_models.dart';

abstract class LoyaltyRepository {
  // ── Points ──────────────────────────────────────────────────────────────
  Future<LoyaltyPoints> getPoints(String businessId, String userId);

  Future<LoyaltyPoints> addPoints({
    required String businessId,
    required String userId,
    required int amount,
    required String reason,
  });

  Future<LoyaltyPoints> redeemPoints({
    required String businessId,
    required String userId,
    required int amount,
    required String reason,
  });

  // ── Rewards (Owner) ─────────────────────────────────────────────────────
  Future<List<Reward>> getRewards(String businessId);

  Future<Reward> createReward({
    required String businessId,
    required String title,
    String description = '',
    required int pointsCost,
  });

  Future<void> deleteReward(String rewardId);
}