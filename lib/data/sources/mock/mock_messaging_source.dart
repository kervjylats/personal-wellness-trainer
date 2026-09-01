// lib/data/sources/mock/mock_messaging_source.dart
//
// Mock implementation of MessagingRepository.
// Active when DataConfig.useMockData = true.
// Seeded with conversations between the four mock users.
// Zero industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/models/message_model.dart';
import 'package:personal_wellness_trainer/data/repositories/messaging_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockMessagingSource with MockSourceMixin implements MessagingRepository {
  static const String _tag = 'MockMessagingSource';

  // ── In-memory state ───────────────────────────────────────────────────────────

  final List<ConversationModel> _conversations = _seedConversations();
  final Map<String, List<MessageModel>> _messages = _seedMessages();

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static const _biz   = 'biz_mock_001';
  static const _owner  = 'usr_owner_001';
  static const _partner = 'usr_partner_001';
  static const _staff  = 'usr_staff_001';

  static List<ConversationModel> _seedConversations() {
    final now = DateTime.now();
    return [
      ConversationModel(
        id:               'conv_001',
        businessId:       _biz,
        type:             'direct',
        participantIds:   [_owner, _partner],
        participantNames: ['Alex Owner', 'Jordan Partner'],
        createdAt:        now.subtract(const Duration(days: 5)),
        updatedAt:        now.subtract(const Duration(minutes: 30)),
        unreadCount:      2,
        lastMessageContent:  'Sounds good — see you then.',
        lastMessageSenderId: _partner,
        lastMessageAt:    now.subtract(const Duration(minutes: 30)),
      ),
      ConversationModel(
        id:               'conv_002',
        businessId:       _biz,
        type:             'direct',
        participantIds:   [_owner, _staff],
        participantNames: ['Alex Owner', 'Morgan Staff'],
        createdAt:        now.subtract(const Duration(days: 3)),
        updatedAt:        now.subtract(const Duration(hours: 2)),
        unreadCount:      0,
        lastMessageContent:  'Done. All records updated.',
        lastMessageSenderId: _staff,
        lastMessageAt:    now.subtract(const Duration(hours: 2)),
      ),
      ConversationModel(
        id:               'conv_003',
        businessId:       _biz,
        type:             'group',
        participantIds:   [_owner, _partner, _staff],
        participantNames: ['Alex Owner', 'Jordan Partner', 'Morgan Staff'],
        createdAt:        now.subtract(const Duration(days: 7)),
        updatedAt:        now.subtract(const Duration(hours: 5)),
        unreadCount:      1,
        groupName:        'Team Updates',
        lastMessageContent:  'Please review before the end of the week.',
        lastMessageSenderId: _owner,
        lastMessageAt:    now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  static Map<String, List<MessageModel>> _seedMessages() {
    final now = DateTime.now();
    return {
      'conv_001': [
        MessageModel(
          id:             'msg_001a',
          conversationId: 'conv_001',
          senderId:       _owner,
          senderName:     'Alex Owner',
          senderRole:     'owner',
          content:        'Hi Jordan — can we connect tomorrow at 10?',
          createdAt:      now.subtract(const Duration(hours: 3)),
          isRead:         true,
        ),
        MessageModel(
          id:             'msg_001b',
          conversationId: 'conv_001',
          senderId:       _partner,
          senderName:     'Jordan Partner',
          senderRole:     'partner',
          content:        'Of course! 10 works great.',
          createdAt:      now.subtract(const Duration(hours: 2)),
          isRead:         true,
        ),
        MessageModel(
          id:             'msg_001c',
          conversationId: 'conv_001',
          senderId:       _partner,
          senderName:     'Jordan Partner',
          senderRole:     'partner',
          content:        'Sounds good — see you then.',
          createdAt:      now.subtract(const Duration(minutes: 30)),
          isRead:         false,
        ),
      ],
      'conv_002': [
        MessageModel(
          id:             'msg_002a',
          conversationId: 'conv_002',
          senderId:       _owner,
          senderName:     'Alex Owner',
          senderRole:     'owner',
          content:        'Morgan — please update the records for this week.',
          createdAt:      now.subtract(const Duration(hours: 4)),
          isRead:         true,
        ),
        MessageModel(
          id:             'msg_002b',
          conversationId: 'conv_002',
          senderId:       _staff,
          senderName:     'Morgan Staff',
          senderRole:     'staff',
          content:        'Done. All records updated.',
          createdAt:      now.subtract(const Duration(hours: 2)),
          isRead:         true,
        ),
      ],
      'conv_003': [
        MessageModel(
          id:             'msg_003a',
          conversationId: 'conv_003',
          senderId:       _owner,
          senderName:     'Alex Owner',
          senderRole:     'owner',
          content:        'Team — please review the schedule.',
          createdAt:      now.subtract(const Duration(hours: 6)),
          isRead:         true,
        ),
        MessageModel(
          id:             'msg_003b',
          conversationId: 'conv_003',
          senderId:       _owner,
          senderName:     'Alex Owner',
          senderRole:     'owner',
          content:        'Please review before the end of the week.',
          createdAt:      now.subtract(const Duration(hours: 5)),
          isRead:         false,
        ),
      ],
    };
  }

  // ── MessagingRepository implementation ───────────────────────────────────────

  @override
  Future<List<ConversationModel>> getConversations(
    String businessId,
    String userId,
  ) async {
    await simulateNetworkDelay();

    final result = _conversations
        .where((c) =>
            c.businessId == businessId && c.participantIds.contains(userId))
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

    AppLogger.debug(
      'MockMessagingSource: ${result.length} conversations for $userId',
      tag: _tag,
    );
    return result;
  }

  @override
  Future<ConversationModel> getOrCreateDirectConversation({
    required String businessId,
    required String userAId,
    required String userAName,
    required String userBId,
    required String userBName,
  }) async {
    await simulateNetworkDelay();

    // Check if a direct conversation already exists between these two users.
    final existing = _conversations.where(
      (c) =>
          c.isDirect &&
          c.businessId == businessId &&
          c.participantIds.contains(userAId) &&
          c.participantIds.contains(userBId),
    );
    if (existing.isNotEmpty) return existing.first;

    // Create a new one.
    final id = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final conv = ConversationModel(
      id:               id,
      businessId:       businessId,
      type:             'direct',
      participantIds:   [userAId, userBId],
      participantNames: [userAName, userBName],
      createdAt:        now,
      updatedAt:        now,
      unreadCount:      0,
    );
    _conversations.add(conv);
    _messages[id] = [];
    AppLogger.info('MockMessagingSource: created direct conversation $id', tag: _tag);
    return conv;
  }

  @override
  Future<ConversationModel> createGroupConversation({
    required String businessId,
    required String creatorId,
    required String groupName,
    required List<String> participantIds,
    required List<String> participantNames,
  }) async {
    await simulateNetworkDelay();

    final id  = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final conv = ConversationModel(
      id:               id,
      businessId:       businessId,
      type:             'group',
      participantIds:   participantIds,
      participantNames: participantNames,
      createdAt:        now,
      updatedAt:        now,
      unreadCount:      0,
      groupName:        groupName,
    );
    _conversations.add(conv);
    _messages[id] = [];
    AppLogger.info('MockMessagingSource: created group "$groupName" ($id)', tag: _tag);
    return conv;
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    await simulateNetworkDelay();
    final msgs = List<MessageModel>.from(_messages[conversationId] ?? []);
    AppLogger.debug(
      'MockMessagingSource: ${msgs.length} messages in $conversationId',
      tag: _tag,
    );
    return msgs;
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
    await simulateNetworkDelay();

    final now  = DateTime.now();
    final id   = 'msg_${now.millisecondsSinceEpoch}';
    final msg  = MessageModel(
      id:             id,
      conversationId: conversationId,
      senderId:       senderId,
      senderName:     senderName,
      senderRole:     senderRole,
      content:        content,
      createdAt:      now,
      isRead:         true, // sender's own message is always read by them
      attachmentId:   attachmentId,
      attachmentType: attachmentType,
    );

    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(msg);

    // Update conversation metadata.
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        updatedAt:           now,
        lastMessageContent:  content,
        lastMessageSenderId: senderId,
        lastMessageAt:       now,
      );
    }

    AppLogger.info('MockMessagingSource: sent message $id', tag: _tag);
    return msg;
  }

  @override
  Future<void> markConversationRead(
    String conversationId,
    String userId,
  ) async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));

    // Mark all messages as read.
    if (_messages.containsKey(conversationId)) {
      _messages[conversationId] = _messages[conversationId]!
          .map((m) => m.copyWith(isRead: true))
          .toList();
    }

    // Reset unread count on conversation.
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
    }
    AppLogger.debug(
      'MockMessagingSource: marked $conversationId read for $userId',
      tag: _tag,
    );
  }

  @override
  Future<int> getTotalUnreadCount(String businessId, String userId) async {
    await simulateNetworkDelay(const Duration(milliseconds: 100));
    return _conversations
        .where(
          (c) => c.businessId == businessId && c.participantIds.contains(userId),
        )
        .fold<int>(0, (sum, c) => sum + c.unreadCount);
  }
}
