// lib/modules/loyalty/providers/loyalty_notifier.dart
//
// Riverpod notifier for client loyalty points.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/loyalty_models.dart';
import 'package:personal_wellness_trainer/data/repositories/loyalty_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_loyalty_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  if (DataConfig.useMockData) return MockLoyaltySource();
  throw UnimplementedError('Supabase loyalty source — Phase 10');
});

final loyaltyNotifierProvider =
    AsyncNotifierProvider<LoyaltyNotifier, LoyaltyPoints>(
  LoyaltyNotifier.new,
  dependencies: [authNotifierProvider],
);

class LoyaltyNotifier extends AsyncNotifier<LoyaltyPoints> {
  static const String _tag = 'LoyaltyNotifier';

  LoyaltyRepository get _repo => ref.read(loyaltyRepositoryProvider);

  @override
  Future<LoyaltyPoints> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) {
      return const LoyaltyPoints(userId: '');
    }
    return _repo.getPoints(auth.profile.businessId, auth.profile.userId);
  }

  Future<bool> redeem({
    required int amount,
    required String reason,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return false;
    try {
      await _repo.redeemPoints(
        businessId: auth.profile.businessId,
        userId: auth.profile.userId,
        amount: amount,
        reason: reason,
      );
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('redeem points failed', tag: _tag, error: e, stackTrace: st);
      return false;
    }
  }
}
