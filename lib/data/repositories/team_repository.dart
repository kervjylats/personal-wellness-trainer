// lib/data/repositories/team_repository.dart

import 'package:personal_wellness_trainer/data/models/team_member_model.dart';

abstract class TeamRepository {
  Future<List<TeamMemberModel>> getMembers(
    String businessId, {
    String? role,
  });

  Future<TeamMemberModel> inviteMember({
    required String businessId,
    required String invitedByUserId,
    required String role,
    required String displayName,
    String? email,
    String? categoryId,
  });

  Future<TeamMemberModel> toggleFeature({
    required String memberId,
    required String businessId,
    required String featureKey,
    required bool value,
  });

  Future<bool> removeMember({
    required String memberId,
    required String businessId,
  });
}