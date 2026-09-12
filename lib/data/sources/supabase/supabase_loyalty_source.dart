// lib/data/sources/supabase/supabase_loyalty_source.dart
//
// Real Supabase implementation of LoyaltyRepository. addPoints()/
// redeemPoints() wrap the add_loyalty_points()/redeem_loyalty_points()
// Postgres functions (triggers.sql) rather than a client-side
// read-then-write — see those functions' own comments for why, especially
// redeemPoints()'s balance check needing to be atomic to prevent
// over-redeeming via a race.
//
// getPoints() composes the nested LoyaltyPoints.history shape from two
// tables (loyalty_points for the running total, loyalty_point_transactions
// for history) — same "normalize in SQL, reconstruct in the source file"
// approach used for Messaging's unreadCount.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/loyalty_models.dart';
import 'package:personal_wellness_trainer/data/repositories/loyalty_repository.dart';

class SupabaseLoyaltySource implements LoyaltyRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<LoyaltyPoints> getPoints(String businessId, String userId) async {
    final pointsRows = await _db
        .from('loyalty_points')
        .select()
        .eq('user_id', userId)
        .eq('business_id', businessId)
        .limit(1);

    final historyRows = await _db
        .from('loyalty_point_transactions')
        .select()
        .eq('user_id', userId)
        .eq('business_id', businessId)
        .order('created_at', ascending: true);

    final history = (historyRows as List)
        .map((r) => PointTransaction(
              id: r['id'] as String,
              reason: (r['reason'] as String?) ?? '',
              amount: (r['amount'] as num).toInt(),
              date: DateTime.parse(r['created_at'] as String),
            ))
        .toList();

    final rows = pointsRows as List;
    final totalPoints = rows.isEmpty
        ? 0
        : ((rows.first as Map<String, dynamic>)['total_points'] as num)
            .toInt();

    return LoyaltyPoints(userId: userId, totalPoints: totalPoints, history: history);
  }

  @override
  Future<LoyaltyPoints> addPoints({
    required String businessId,
    required String userId,
    required int amount,
    required String reason,
  }) async {
    await _db.rpc('add_loyalty_points', params: {
      'p_user_id': userId,
      'p_business_id': businessId,
      'p_amount': amount,
      'p_reason': reason,
    });
    return getPoints(businessId, userId);
  }

  @override
  Future<LoyaltyPoints> redeemPoints({
    required String businessId,
    required String userId,
    required int amount,
    required String reason,
  }) async {
    await _db.rpc('redeem_loyalty_points', params: {
      'p_user_id': userId,
      'p_business_id': businessId,
      'p_amount': amount,
      'p_reason': reason,
    });
    return getPoints(businessId, userId);
  }

  // ── Rewards ──────────────────────────────────────────────────────────────

  @override
  Future<List<Reward>> getRewards(String businessId) async {
    final rows = await _db
        .from('rewards')
        .select()
        .eq('business_id', businessId);
    return (rows as List)
        .map((r) => Reward.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Reward> createReward({
    required String businessId,
    required String title,
    String description = '',
    required int pointsCost,
  }) async {
    final row = await _db.from('rewards').insert({
      'business_id': businessId,
      'title': title,
      'description': description,
      'points_cost': pointsCost,
      'is_active': true,
    }).select().single();

    return Reward.fromJson(row);
  }

  @override
  Future<void> deleteReward(String rewardId) async {
    await _db.from('rewards').delete().eq('id', rewardId);
  }
}
