// lib/modules/team/providers/team_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/data/repositories/team_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_team_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final teamActionErrorProvider = StateProvider<String?>((ref) => null);

final _teamRepositoryProvider = Provider<TeamRepository>((ref) {
  if (DataConfig.useMockData) return MockTeamSource();
  throw UnimplementedError('Supabase team source — Phase 10 only.');
});

final teamNotifierProvider =
    AsyncNotifierProvider<TeamNotifier, List<TeamMemberModel>>(
  TeamNotifier.new,
  dependencies: [authNotifierProvider],
);

class TeamNotifier extends AsyncNotifier<List<TeamMemberModel>> {
  static const String _tag = 'TeamNotifier';

  bool _active = false;

  TeamRepository get _repo => ref.read(_teamRepositoryProvider);

  String get _businessId {
    final auth = ref.read(authNotifierProvider);
    if (auth is AuthAuthenticated) return auth.profile.businessId;
    throw StateError('TeamNotifier accessed without authenticated user.');
  }

  @override
  Future<List<TeamMemberModel>> build() async {
    _active = true;
    ref.onDispose(() => _active = false);

    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    AppLogger.info('Loading team members…', tag: _tag);
    return _repo.getMembers(auth.profile.businessId);
  }

  List<TeamMemberModel> membersForRole(String role) {
    return state.valueOrNull
            ?.where((m) => m.role == role)
            .toList() ??
        [];
  }

  TeamMemberModel? activePartnerForCategory(String categoryId) {
    return state.valueOrNull?.firstWhere(
      (m) => m.role == 'partner' && m.categoryId == categoryId && m.isActive,
      orElse: () => throw StateError('no partner'),
    );
  }

  Future<TeamMemberModel?> inviteMember({
    required String role,
    required String displayName,
    String? email,
    String? categoryId,
  }) async {
    final prevState = state;
    state = const AsyncLoading();
    try {
      final member = await _repo.inviteMember(
        businessId: _businessId,
        invitedByUserId: _currentUserId,
        role: role,
        displayName: displayName,
        email: email,
        categoryId: categoryId,
      );
      state = AsyncData([...prevState.valueOrNull ?? [], member]);
      AppLogger.info('Member invited: ${member.userId}', tag: _tag);
      return member;
    } catch (e, st) {
      AppLogger.error('inviteMember failed', tag: _tag, error: e, stackTrace: st);
      ref.read(teamActionErrorProvider.notifier).state =
          'Could not send invite. Please try again.';
      state = prevState;
      return null;
    }
  }

  Future<bool> toggleFeature({
    required String memberId,
    required String featureKey,
    required bool value,
  }) async {
    try {
      final updated = await _repo.toggleFeature(
        memberId: memberId,
        businessId: _businessId,
        featureKey: featureKey,
        value: value,
      );

      final current = state.valueOrNull ?? [];
      final index = current.indexWhere((m) => m.userId == memberId);
      if (index != -1) {
        final next = List<TeamMemberModel>.from(current);
        next[index] = updated;
        state = AsyncData(next);
      }

      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (_active) {
          ref.invalidateSelf();
        }
      });

      AppLogger.info(
        'Feature "$featureKey" → $value for member $memberId',
        tag: _tag,
      );
      return true;
    } catch (e, st) {
      AppLogger.error('toggleFeature failed', tag: _tag, error: e, stackTrace: st);
      ref.read(teamActionErrorProvider.notifier).state =
          'Could not update permission. Please try again.';
      return false;
    }
  }

  Future<bool> removeMember(String memberId) async {
    final prevState = state;
    try {
      final success = await _repo.removeMember(
        memberId: memberId,
        businessId: _businessId,
      );
      if (success) {
        state = AsyncData(
          (state.valueOrNull ?? [])
              .where((m) => m.userId != memberId)
              .toList(),
        );
      }
      return success;
    } catch (e, st) {
      AppLogger.error('removeMember failed', tag: _tag, error: e, stackTrace: st);
      state = prevState;
      ref.read(teamActionErrorProvider.notifier).state =
          'Could not remove member. Please try again.';
      return false;
    }
  }

  String get _currentUserId {
    final auth = ref.read(authNotifierProvider);
    if (auth is AuthAuthenticated) return auth.profile.userId;
    throw StateError('No authenticated user.');
  }
}
