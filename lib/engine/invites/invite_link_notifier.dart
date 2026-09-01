// lib/engine/invites/invite_link_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/invite_link_model.dart';
import 'package:personal_wellness_trainer/data/repositories/invite_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_invite_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

sealed class InviteLinkResult {}

final class InviteLinkCreated extends InviteLinkResult {
  InviteLinkCreated(this.link);
  final InviteLinkModel link;
}

final class InviteLinkError extends InviteLinkResult {
  InviteLinkError(this.message);
  final String message;
}

sealed class TokenValidationResult {}

final class TokenValid extends TokenValidationResult {
  TokenValid(this.link);
  final InviteLinkModel link;
}

final class TokenInvalid extends TokenValidationResult {
  TokenInvalid(this.reason);
  final String reason;
}

class InviteLinkNotifier extends AutoDisposeAsyncNotifier<List<InviteLinkModel>> {
  static const String _tag = 'InviteLinkNotifier';

  InviteRepository get _repo =>
      DataConfig.useMockData ? MockInviteSource() : throw UnimplementedError();

  @override
  Future<List<InviteLinkModel>> build() async {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];
    final businessId = authState.profile.businessId;
    return _repo.getLinks(businessId);
  }

  /// Generates a new invite link. All category and slot restrictions are 
  /// completely removed. Any invitee automatically joins as an active member.
  Future<InviteLinkResult> generateLink({
    required String targetRole,
    String? categoryId,
    String? label,
    int maxUses = 0,
    DateTime? expiresAt,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      return InviteLinkError('Not signed in.');
    }

    final profile = authState.profile;

    if (profile.role == 'partner' && targetRole == 'staff') {
      return InviteLinkError('Partners cannot invite staff members.');
    }

    try {
      final link = await _repo.createLink(
        businessId: profile.businessId,
        invitedByUserId: profile.userId,
        invitedByRole: profile.role,
        targetRole: targetRole,
        categoryId: categoryId,
        label: label,
        maxUses: maxUses,
        expiresAt: expiresAt,
      );
      ref.invalidateSelf();
      return InviteLinkCreated(link);
    } catch (e) {
      return InviteLinkError('Could not generate invite link. Please try again.');
    }
  }

  Future<TokenValidationResult> validateToken(String token) async {
    if (token.isEmpty) return TokenInvalid('No invite token provided.');
    try {
      final link = await _repo.getLinkByToken(token);
      if (link == null) return TokenInvalid('Invite link not found.');
      if (link.isExpired) return TokenInvalid('This invite link has expired.');
      if (link.isExhausted) {
        return TokenInvalid('This invite link has already been used.');
      }
      return TokenValid(link);
    } catch (e) {
      return TokenInvalid('Could not validate invite link.');
    }
  }

  Future<void> recordUse(String linkId) async {
    try {
      await _repo.recordUse(linkId);
      ref.invalidateSelf();
    } catch (e) {
      AppLogger.warning('InviteLinkNotifier: recordUse failed for $linkId — $e', tag: _tag);
    }
  }

  Future<bool> deleteLink(String linkId) async {
    try {
      await _repo.deleteLink(linkId);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final inviteLinkNotifierProvider =
    AsyncNotifierProvider.autoDispose<InviteLinkNotifier, List<InviteLinkModel>>(
  InviteLinkNotifier.new,
  dependencies: [authNotifierProvider],
);
