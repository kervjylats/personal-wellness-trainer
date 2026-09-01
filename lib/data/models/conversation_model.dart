// lib/data/models/conversation_model.dart
//
// Represents a direct-message thread or a group chat.
// 'direct' → exactly two participants.
// 'group'  → owner-created, any number of participants.

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCount,
    this.groupName,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageAt,
  });

  final String id;
  final String businessId;

  /// Values: 'direct' | 'group'
  final String type;

  final List<String> participantIds;
  final List<String> participantNames;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;

  /// Non-null for group conversations.
  final String? groupName;

  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;

  bool get isDirect => type == 'direct';
  bool get isGroup  => type == 'group';

  /// Display name for a conversation: group name or the other participant.
  String displayName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group';
    final otherIndex = participantIds.indexOf(currentUserId) == 0 ? 1 : 0;
    if (otherIndex < participantNames.length) {
      return participantNames[otherIndex];
    }
    return 'Conversation';
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id:                   json['id'] as String,
      businessId:           json['business_id'] as String,
      type:                 json['type'] as String? ?? 'direct',
      participantIds:       List<String>.from(
                              json['participant_ids'] as List<dynamic>? ?? [],
                            ),
      participantNames:     List<String>.from(
                              json['participant_names'] as List<dynamic>? ?? [],
                            ),
      createdAt:            DateTime.parse(json['created_at'] as String),
      updatedAt:            DateTime.parse(json['updated_at'] as String),
      unreadCount:          json['unread_count'] as int? ?? 0,
      groupName:            json['group_name'] as String?,
      lastMessageContent:   json['last_message_content'] as String?,
      lastMessageSenderId:  json['last_message_sender_id'] as String?,
      lastMessageAt:        json['last_message_at'] != null
                              ? DateTime.parse(json['last_message_at'] as String)
                              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                     id,
    'business_id':            businessId,
    'type':                   type,
    'participant_ids':        participantIds,
    'participant_names':      participantNames,
    'created_at':             createdAt.toIso8601String(),
    'updated_at':             updatedAt.toIso8601String(),
    'unread_count':           unreadCount,
    if (groupName != null)            'group_name':               groupName,
    if (lastMessageContent != null)   'last_message_content':     lastMessageContent,
    if (lastMessageSenderId != null)  'last_message_sender_id':   lastMessageSenderId,
    if (lastMessageAt != null)        'last_message_at':          lastMessageAt!.toIso8601String(),
  };

  ConversationModel copyWith({
    String? id,
    String? businessId,
    String? type,
    List<String>? participantIds,
    List<String>? participantNames,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    String? groupName,
    String? lastMessageContent,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id:                   id                  ?? this.id,
      businessId:           businessId          ?? this.businessId,
      type:                 type                ?? this.type,
      participantIds:       participantIds      ?? this.participantIds,
      participantNames:     participantNames    ?? this.participantNames,
      createdAt:            createdAt           ?? this.createdAt,
      updatedAt:            updatedAt           ?? this.updatedAt,
      unreadCount:          unreadCount         ?? this.unreadCount,
      groupName:            groupName           ?? this.groupName,
      lastMessageContent:   lastMessageContent  ?? this.lastMessageContent,
      lastMessageSenderId:  lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt:        lastMessageAt       ?? this.lastMessageAt,
    );
  }

  @override
  String toString() =>
      'ConversationModel(id: $id, type: $type, unread: $unreadCount)';
}
