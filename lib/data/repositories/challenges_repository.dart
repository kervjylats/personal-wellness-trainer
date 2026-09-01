// lib/data/repositories/challenges_repository.dart
//
// Abstract interface for challenge data operations.

import 'package:personal_wellness_trainer/data/models/challenge_model.dart';
import 'package:personal_wellness_trainer/data/models/challenge_participation_model.dart';

abstract class ChallengesRepository {
  Future<List<ChallengeModel>> getChallenges(String businessId);

  Future<ChallengeModel> createChallenge({
    required String businessId,
    required String createdByUserId,
    required String title,
    required String description,
    required int durationDays,
  });

  Future<List<ChallengeParticipationModel>> getParticipants(String challengeId);

  Future<ChallengeParticipationModel> joinChallenge({
    required String challengeId,
    required String userId,
    required String userName,
  });

  Future<ChallengeParticipationModel> markDayComplete({
    required String challengeId,
    required String userId,
  });

  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  });
}