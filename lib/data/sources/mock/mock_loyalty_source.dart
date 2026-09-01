// lib/data/sources/mock/mock_loyalty_source.dart

import 'package:personal_wellness_trainer/data/models/loyalty_models.dart';
import 'package:personal_wellness_trainer/data/repositories/loyalty_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockLoyaltySource with MockSourceMixin implements LoyaltyRepository {
  static const String _businessId = 'biz_mock_001';

  // In-memory points store keyed by userId
  static final Map<String, LoyaltyPoints> _pointsStore = {
    'usr_client_001': LoyaltyPoints(
      userId: 'usr_client_001',
      totalPoints: 250,
      history: [
        PointTransaction(
          id: 'pt_001',
          reason: '7-day streak bonus',
          amount: 100,
          date: DateTime.now().subtract(const Duration(days: 3)),
        ),
        PointTransaction(
          id: 'pt_002',
          reason: 'Completed homework',
          amount: 50,
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PointTransaction(
          id: 'pt_003',
          reason: 'Referred a friend',
          amount: 100,
          date: DateTime.now(),
        ),
      ],
    ),
    'usr_client_002': LoyaltyPoints(
      userId: 'usr_client_002',
      totalPoints: 150,
      history: [
        PointTransaction(
          id: 'pt_004',
          reason: 'Welcome bonus',
          amount: 100,
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        PointTransaction(
          id: 'pt_005',
          reason: 'Daily streak',
          amount: 50,
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
  };

  static final List<Reward> _rewards = [
    const Reward(
      id: 'rw_001',
      businessId: _businessId,
      title: 'Free 1-on-1 Session',
      description: 'Redeem a free personal coaching session.',
      pointsCost: 200,
      isActive: true,
    ),
    const Reward(
      id: 'rw_002',
      businessId: _businessId,
      title: '10% Discount on Shop',
      description: 'Get 10% off your next purchase.',
      pointsCost: 100,
      isActive: true,
    ),
    const Reward(
      id: 'rw_003',
      businessId: _businessId,
      title: 'Exclusive Workshop Access',
      description: 'Unlock a member-only workshop.',
      pointsCost: 300,
      isActive: true,
    ),
  ];

  static int _transactionIdCounter = 10;
  static int _rewardIdCounter = 10;

  @override
  Future<LoyaltyPoints> getPoints(String businessId, String userId) async {
    await simulateNetworkDelay();
    return _pointsStore[userId] ??
        LoyaltyPoints(userId: userId);
  }

  @override
  Future<LoyaltyPoints> addPoints({
    required String businessId,
    required String userId,
    required int amount,
    required String reason,
  }) async {
    await simulateNetworkDelay();
    _transactionIdCounter++;
    final current = _pointsStore[userId] ??
        LoyaltyPoints(userId: userId);
    final transaction = PointTransaction(
      id: 'pt_$_transactionIdCounter',
      reason: reason,
      amount: amount,
      date: DateTime.now(),
    );
    final updated = LoyaltyPoints(
      userId: current.userId,
      totalPoints: current.totalPoints + amount,
      history: [...current.history, transaction],
    );
    _pointsStore[userId] = updated;
    return updated;
  }

  @override
  Future<LoyaltyPoints> redeemPoints({
    required String businessId,
    required String userId,
    required int amount,
    required String reason,
  }) async {
    await simulateNetworkDelay();
    final current = _pointsStore[userId] ??
        LoyaltyPoints(userId: userId);
    if (current.totalPoints < amount) {
      throw Exception('Not enough points');
    }
    _transactionIdCounter++;
    final transaction = PointTransaction(
      id: 'pt_$_transactionIdCounter',
      reason: reason,
      amount: -amount,
      date: DateTime.now(),
    );
    final updated = LoyaltyPoints(
      userId: current.userId,
      totalPoints: current.totalPoints - amount,
      history: [...current.history, transaction],
    );
    _pointsStore[userId] = updated;
    return updated;
  }

  @override
  Future<List<Reward>> getRewards(String businessId) async {
    await simulateNetworkDelay();
    return _rewards.where((r) => r.businessId == businessId).toList();
  }

  @override
  Future<Reward> createReward({
    required String businessId,
    required String title,
    String description = '',
    required int pointsCost,
  }) async {
    await simulateNetworkDelay();
    _rewardIdCounter++;
    final reward = Reward(
      id: 'rw_$_rewardIdCounter',
      businessId: businessId,
      title: title,
      description: description,
      pointsCost: pointsCost,
      isActive: true,
    );
    _rewards.add(reward);
    return reward;
  }

  @override
  Future<void> deleteReward(String rewardId) async {
    await simulateNetworkDelay();
    _rewards.removeWhere((r) => r.id == rewardId);
  }
}