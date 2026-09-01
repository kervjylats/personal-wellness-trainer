// lib/data/sources/mock/mock_challenges_source.dart
//
// Mock implementation of ChallengesRepository.

import 'package:personal_wellness_trainer/data/models/challenge_model.dart';
import 'package:personal_wellness_trainer/data/models/challenge_participation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/challenges_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockChallengesSource with MockSourceMixin implements ChallengesRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _ownerId   = 'usr_owner_001';

  static final List<ChallengeModel> _challenges = [
    ChallengeModel(
      id: 'ch_001',
      businessId: _businessId,
      createdByUserId: _ownerId,
      title: '7 Days of Morning Yoga',
      description: 'Start every day with a 15‑minute flow.',
      durationDays: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isActive: true,
    ),
    ChallengeModel(
      id: 'ch_002',
      businessId: _businessId,
      createdByUserId: _ownerId,
      title: 'Daily Meditation Streak',
      description: 'Sit for 10 minutes every day.',
      durationDays: 14,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isActive: true,
    ),
  ];

  static final Map<String, List<ChallengeParticipationModel>> _participants = {
    'ch_001': [
      ChallengeParticipationModel(
        id: 'part_001',
        challengeId: 'ch_001',
        userId: 'usr_client_001',
        userName: 'Sam Client',
        completedDays: 2,
        lastCompletedDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChallengeParticipationModel(
        id: 'part_002',
        challengeId: 'ch_001',
        userId: 'usr_client_002',
        userName: 'Taylor Client',
        completedDays: 1,
        lastCompletedDate: DateTime.now(),
      ),
    ],
    'ch_002': [
      ChallengeParticipationModel(
        id: 'part_003',
        challengeId: 'ch_002',
        userId: 'usr_client_001',
        userName: 'Sam Client',
        completedDays: 5,
        lastCompletedDate: DateTime.now(),
      ),
    ],
  };

  static int _chIdCounter = 10;
  static int _partIdCounter = 10;

  @override
  Future<List<ChallengeModel>> getChallenges(String businessId) async {
    await simulateNetworkDelay();
    return _challenges
        .where((c) => c.businessId == businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ChallengeModel> createChallenge({
    required String businessId,
    required String createdByUserId,
    required String title,
    required String description,
    required int durationDays,
  }) async {
    await simulateNetworkDelay();
    _chIdCounter++;
    final challenge = ChallengeModel(
      id: 'ch_$_chIdCounter',
      businessId: businessId,
      createdByUserId: createdByUserId,
      title: title,
      description: description,
      durationDays: durationDays,
      createdAt: DateTime.now(),
      isActive: true,
    );
    _challenges.insert(0, challenge);
    _participants[challenge.id] = [];
    return challenge;
  }

  @override
  Future<List<ChallengeParticipationModel>> getParticipants(
      String challengeId) async {
    await simulateNetworkDelay();
    return List.from(_participants[challengeId] ?? []);
  }

  @override
  Future<ChallengeParticipationModel> joinChallenge({
    required String challengeId,
    required String userId,
    required String userName,
  }) async {
    await simulateNetworkDelay();
    final list = _participants.putIfAbsent(challengeId, () => []);
    _partIdCounter++;
    final part = ChallengeParticipationModel(
      id: 'part_$_partIdCounter',
      challengeId: challengeId,
      userId: userId,
      userName: userName,
      completedDays: 0,
    );
    list.add(part);
    return part;
  }

  @override
  Future<ChallengeParticipationModel> markDayComplete({
    required String challengeId,
    required String userId,
  }) async {
    await simulateNetworkDelay();
    final list = _participants[challengeId] ?? [];
    final idx = list.indexWhere(
        (p) => p.userId == userId && p.challengeId == challengeId);
    if (idx == -1) throw Exception('Not joined');
    final today = DateTime.now();
    final participant = list[idx];
    // Only allow once per day
    if (participant.lastCompletedDate != null &&
        participant.lastCompletedDate!.year == today.year &&
        participant.lastCompletedDate!.month == today.month &&
        participant.lastCompletedDate!.day == today.day) {
      return participant; // already completed today
    }
    final updated = participant.copyWith(
      completedDays: participant.completedDays + 1,
      lastCompletedDate: today,
    );
    list[idx] = updated;
    return updated;
  }

  @override
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    await simulateNetworkDelay();
    final list = _participants[challengeId];
    if (list != null) {
      list.removeWhere((p) => p.userId == userId);
    }
  }
}