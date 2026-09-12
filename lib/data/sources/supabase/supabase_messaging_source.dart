// lib/data/sources/supabase/supabase_messaging_source.dart
//
// Real Supabase implementation of MessagingRepository.
//
// unreadCount is deliberately NOT read off a stored column — it's
// computed live per-viewer for each conversation (count of messages
// where sender_id != this viewer AND is_read = false). See
// schema.sql's conversations table comment for why: the mock stores it
// as one shared int and resets it to 0 for EVERYONE when any participant
// reads the conversation, which is a real correctness bug for real users,
// not something worth preserving.
//
// is_read itself is still a single shared boolean per message (matches
// MessageModel) — correct for 'direct' conversations, a known
// model-level limitation for 'group' ones with 3+ participants (see
// schema.sql's messages table comment). Not something this file can fix
// without a schema/model change outside this task's scope.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/models/message_model.dart';
import 'package:personal_wellness_trainer/data/repositories/messaging_repository.dart';

class SupabaseMessagingSource implements MessagingRepository {
  final SupabaseClient _db = Supabase.instance.client;

  // ── Conversations ────────────────────────────────────────────────────────

  @override
  Future<List<ConversationModel>> getConversations(
    String businessId,
    String userId,
  ) async {
    final rows = await _db
        .from('conversations')
        .select()
        .eq('business_id', businessId)
        .contains('participant_ids', [userId])
        .order('updated_at', ascending: false);

    final conversations = (rows as List)
        .map((r) => ConversationModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // One unread count per conversation, computed live for THIS viewer —
    // see file header for why this can't just be a stored column.
    final withUnread = <ConversationModel>[];
    for (final c in conversations) {
      final unread = await _unreadCountFor(c.id, userId);
      withUnread.add(c.copyWith(unreadCount: unread));
    }
    return withUnread;
  }

  Future<int> _unreadCountFor(String conversationId, String userId) async {
    final rows = await _db
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .eq('is_read', false)
        .neq('sender_id', userId);
    return (rows as List).length;
  }

  @override
  Future<ConversationModel> getOrCreateDirectConversation({
    required String businessId,
    required String userAId,
    required String userAName,
    required String userBId,
    required String userBName,
  }) async {
    final existingRows = await _db
        .from('conversations')
        .select()
        .eq('business_id', businessId)
        .eq('type', 'direct')
        .contains('participant_ids', [userAId, userBId]);

    final existing = existingRows as List;
    if (existing.isNotEmpty) {
      return ConversationModel.fromJson(existing.first as Map<String, dynamic>);
    }

    final row = await _db.from('conversations').insert({
      'business_id': businessId,
      'type': 'direct',
      'participant_ids': [userAId, userBId],
      'participant_names': [userAName, userBName],
    }).select().single();

    return ConversationModel.fromJson(row).copyWith(unreadCount: 0);
  }

  @override
  Future<ConversationModel> createGroupConversation({
    required String businessId,
    required String creatorId,
    required String groupName,
    required List<String> participantIds,
    required List<String> participantNames,
  }) async {
    final row = await _db.from('conversations').insert({
      'business_id': businessId,
      'type': 'group',
      'participant_ids': participantIds,
      'participant_names': participantNames,
      'group_name': groupName,
    }).select().single();

    return ConversationModel.fromJson(row).copyWith(unreadCount: 0);
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final rows = await _db
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) => MessageModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    String? attachmentId,
    String? attachmentType,
  }) async {
    final row = await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'content': content,
      'is_read': false,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (attachmentType != null) 'attachment_type': attachmentType,
    }).select().single();

    // Denormalized preview fields on the conversation, for a conversation
    // list that doesn't need to join/query messages just to show a
    // preview snippet.
    await _db.from('conversations').update({
      'last_message_content': content,
      'last_message_sender_id': senderId,
      'last_message_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    return MessageModel.fromJson(row);
  }

  @override
  Future<void> markConversationRead(
    String conversationId,
    String userId,
  ) async {
    // Only marks messages sent by SOMEONE ELSE as read — a user's own
    // sent messages were never "unread" from their own perspective in
    // the first place, and this is what keeps a shared is_read boolean
    // reasonably correct for the direct (2-person) case: the only other
    // person who could mark it read is the recipient.
    await _db
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('is_read', false)
        .neq('sender_id', userId);
  }

  @override
  Future<int> getTotalUnreadCount(String businessId, String userId) async {
    final conversationRows = await _db
        .from('conversations')
        .select('id')
        .eq('business_id', businessId)
        .contains('participant_ids', [userId]);

    int total = 0;
    for (final c in conversationRows as List) {
      total += await _unreadCountFor(c['id'] as String, userId);
    }
    return total;
  }
}
