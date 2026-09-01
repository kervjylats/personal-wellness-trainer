// lib/data/repositories/messaging_repository.dart
//
// Abstract interface for all messaging data operations.
// MockMessagingSource implements this for Phases 1–9.
// SupabaseMessagingSource will implement it in Phase 10.

import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/models/message_model.dart';

abstract class MessagingRepository {
  // ── Conversations ─────────────────────────────────────────────────────────────

  /// Returns all conversations for the given user, newest-activity first.
  Future<List<ConversationModel>> getConversations(
    String businessId,
    String userId,
  );

  /// Returns or creates the direct conversation between two users.
  Future<ConversationModel> getOrCreateDirectConversation({
    required String businessId,
    required String userAId,
    required String userAName,
    required String userBId,
    required String userBName,
  });

  /// Creates a new group conversation. Owner only.
  Future<ConversationModel> createGroupConversation({
    required String businessId,
    required String creatorId,
    required String groupName,
    required List<String> participantIds,
    required List<String> participantNames,
  });

  // ── Messages ──────────────────────────────────────────────────────────────────

  /// Returns all messages for a conversation, oldest first.
  Future<List<MessageModel>> getMessages(String conversationId);

  /// Sends a new message. Returns the created record.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    String? attachmentId,
    String? attachmentType,
  });

  /// Marks all unread messages in a conversation as read for the given user.
  Future<void> markConversationRead(String conversationId, String userId);

  /// Returns total unread count across all conversations for a user.
  Future<int> getTotalUnreadCount(String businessId, String userId);
}
