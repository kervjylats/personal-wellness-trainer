// lib/data/sources/supabase/supabase_challenges_source.dart
//
// Real Supabase implementation of ChallengesRepository. markDayComplete()
// wraps mark_challenge_day_complete() (triggers.sql) — see that
// function's own comment for why this isn't a client-side check-then-write.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/challenge_model.dart';
import 'package:personal_wellness_trainer/data/models/challenge_participation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/challenges_repository.dart';

class SupabaseChallengesSource implements ChallengesRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<ChallengeModel>> getChallenges(String businessId) async {
    final rows = await _db
        .from('challenges')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ChallengeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChallengeModel> createChallenge({
    required String businessId,
    required String createdByUserId,
    required String title,
    required String description,
    required int durationDays,
  }) async {
    final row = await _db.from('challenges').insert({
      'business_id': businessId,
      'created_by_user_id': createdByUserId,
      'title': title,
      'description': description,
      'duration_days': durationDays,
      'is_active': true,
    }).select().single();

    return ChallengeModel.fromJson(row);
  }

  @override
  Future<List<ChallengeParticipationModel>> getParticipants(
    String challengeId,
  ) async {
    final rows = await _db
        .from('challenge_participants')
        .select()
        .eq('challenge_id', challengeId);
    return (rows as List)
        .map((r) => ChallengeParticipationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChallengeParticipationModel> joinChallenge({
    required String challengeId,
    required String userId,
    required String userName,
  }) async {
    final row = await _db.from('challenge_participants').insert({
      'challenge_id': challengeId,
      'user_id': userId,
      'user_name': userName,
      'completed_days': 0,
    }).select().single();

    return ChallengeParticipationModel.fromJson(row);
  }

  @override
  Future<ChallengeParticipationModel> markDayComplete({
    required String challengeId,
    required String userId,
  }) async {
    final row = await _db.rpc('mark_challenge_day_complete', params: {
      'p_challenge_id': challengeId,
      'p_user_id': userId,
    });
    return ChallengeParticipationModel.fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    await _db
        .from('challenge_participants')
        .delete()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId);
  }
}
