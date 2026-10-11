// lib/modules/chat/providers/chat_notifier.dart
//
// Manages the list of all conversations (private, group, community) for the authenticated user.
// Also provides methods to create conversations and mark them as read.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/messaging_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_messaging_source.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_messaging_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final _messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  if (DataConfig.useMockData) return MockMessagingSource();
  return SupabaseMessagingSource();
});

final chatNotifierProvider =
    AsyncNotifierProvider<ChatNotifier, List<ConversationModel>>(
  ChatNotifier.new,
  dependencies: [authNotifierProvider],
);

class ChatNotifier extends AsyncNotifier<List<ConversationModel>> {
  static const String _tag = 'ChatNotifier';

  MessagingRepository get _repo => ref.read(_messagingRepositoryProvider);

  @override
  Future<List<ConversationModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return const [];
    return _repo.getConversations(
      auth.profile.businessId,
      auth.profile.userId,
    );
  }

  Future<ConversationModel?> createConversation({
    required List<String> participantIds,
    required List<String> participantNames,
    String? groupName,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;

    final profile = auth.profile;

    try {
      ConversationModel conversation;

      if (groupName == null && participantIds.length == 1) {
        conversation = await _repo.getOrCreateDirectConversation(
          businessId: profile.businessId,
          userAId: profile.userId,
          userAName: profile.displayName,
          userBId: participantIds.first,
          userBName: participantNames.first,
        );
      } else {
        conversation = await _repo.createGroupConversation(
          businessId: profile.businessId,
          creatorId: profile.userId,
          groupName: groupName ?? 'Group',
          participantIds: [profile.userId, ...participantIds],
          participantNames: [profile.displayName, ...participantNames],
        );
      }

      ref.invalidateSelf();
      return conversation;
    } catch (e, st) {
      AppLogger.error(
        'createConversation failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return;
    try {
      await _repo.markConversationRead(conversationId, auth.profile.userId);
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error(
        'markConversationRead failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Returns the community feed conversation for this business, or creates it.
  Future<ConversationModel> getCommunityFeed() async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) throw Exception('Not authenticated');

    // Fast path: already loaded in this provider's state.
    final conversations = state.valueOrNull ?? [];
    final inMemory = conversations.where((c) => c.type == 'community').firstOrNull;
    if (inMemory != null) return inMemory;

    // Authoritative check against the repository (M6): the local state
    // resets whenever the provider rebuilds (invalidateSelf / fresh
    // session), and the old code only ever checked memory — so every
    // remount minted ANOTHER 'Community Feed' row. The type is now
    // persisted ('community' is in the conversations.type check), so one
    // DB query finds the existing row.
    final existing = await _repo.getConversations(
      auth.profile.businessId,
      auth.profile.userId,
    );
    final fromDb = existing.where((c) => c.type == 'community').firstOrNull;
    if (fromDb != null) return fromDb;

    // Create the community feed — once. The type travels with the INSERT
    // instead of being patched on in memory afterwards.
    final conversation = await _repo.createGroupConversation(
      businessId: auth.profile.businessId,
      creatorId: auth.profile.userId,
      groupName: 'Community Feed',
      participantIds: [auth.profile.userId],
      participantNames: [auth.profile.displayName],
      type: 'community',
    );
    ref.invalidateSelf();
    return conversation;
  }
}
