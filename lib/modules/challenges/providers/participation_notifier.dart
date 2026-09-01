// lib/modules/challenges/providers/participation_notifier.dart
//
// Riverpod notifier for challenge participants – family provider keyed by challengeId.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/challenge_participation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/challenges_repository.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/challenges/providers/challenges_notifier.dart';

final participationNotifierProvider = AsyncNotifierProvider.family<
    ParticipationNotifier, List<ChallengeParticipationModel>, String>(
  ParticipationNotifier.new,
);

class ParticipationNotifier
    extends FamilyAsyncNotifier<List<ChallengeParticipationModel>, String> {
  static const String _tag = 'ParticipationNotifier';

  ChallengesRepository get _repo => ref.read(challengesRepositoryProvider);

  @override
  Future<List<ChallengeParticipationModel>> build(String arg) async {
    return _repo.getParticipants(arg);
  }

  Future<ChallengeParticipationModel?> join({
    required String userName,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;
    try {
      final part = await _repo.joinChallenge(
        challengeId: arg,
        userId: auth.profile.userId,
        userName: userName,
      );
      ref.invalidateSelf();
      return part;
    } catch (e, st) {
      AppLogger.error('join challenge failed', tag: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> markDayComplete() async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return false;
    try {
      await _repo.markDayComplete(
        challengeId: arg,
        userId: auth.profile.userId,
      );
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('mark day complete failed', tag: _tag, error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> leave() async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return;
    try {
      await _repo.leaveChallenge(
        challengeId: arg,
        userId: auth.profile.userId,
      );
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error('leave challenge failed', tag: _tag, error: e, stackTrace: st);
    }
  }
}