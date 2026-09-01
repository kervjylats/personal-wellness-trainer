// lib/modules/challenges/providers/challenges_notifier.dart
//
// Riverpod notifier for challenges – load, create, join, mark day, leave.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/challenge_model.dart';
import 'package:personal_wellness_trainer/data/repositories/challenges_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_challenges_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  if (DataConfig.useMockData) return MockChallengesSource();
  throw UnimplementedError('Supabase challenges source — Phase 10');
});

final challengesNotifierProvider =
    AsyncNotifierProvider<ChallengesNotifier, List<ChallengeModel>>(
  ChallengesNotifier.new,
  dependencies: [authNotifierProvider],
);

class ChallengesNotifier extends AsyncNotifier<List<ChallengeModel>> {
  static const String _tag = 'ChallengesNotifier';

  ChallengesRepository get _repo => ref.read(challengesRepositoryProvider);

  @override
  Future<List<ChallengeModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    return _repo.getChallenges(auth.profile.businessId);
  }

  Future<ChallengeModel?> create({
    required String title,
    required String description,
    required int durationDays,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;
    try {
      final challenge = await _repo.createChallenge(
        businessId: auth.profile.businessId,
        createdByUserId: auth.profile.userId,
        title: title,
        description: description,
        durationDays: durationDays,
      );
      ref.invalidateSelf();
      return challenge;
    } catch (e, st) {
      AppLogger.error('create challenge failed', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }
}
