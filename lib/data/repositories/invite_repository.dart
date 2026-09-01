import 'package:personal_wellness_trainer/data/models/invite_link_model.dart';

abstract class InviteRepository {
  Future<List<InviteLinkModel>> getLinks(String businessId);

  Future<InviteLinkModel?> getLinkByToken(String token);

  Future<InviteLinkModel> createLink({
    required String businessId,
    required String invitedByUserId,
    required String invitedByRole,
    required String targetRole,
    String? categoryId,
    String? label,
    int maxUses = 0,
    DateTime? expiresAt,
  });

  Future<InviteLinkModel> recordUse(String linkId);

  Future<void> deleteLink(String linkId);
}
