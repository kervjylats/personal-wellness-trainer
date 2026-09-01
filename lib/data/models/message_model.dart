// lib/data/models/message_model.dart
//
// Represents a single message sent within a conversation.
// Immutable. fromJson/toJson for Supabase (Phase 10). copyWith for state.
// Zero business logic — pure data container.

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.attachmentId,
    this.attachmentType,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;

  /// Raw role string: 'owner' | 'partner' | 'staff' | 'client'
  final String senderRole;

  final String content;
  final DateTime createdAt;
  final bool isRead;

  /// Optional reference to a MessageAttachmentModel id.
  final String? attachmentId;

  /// Widget Registry key for the attachment card, e.g. 'activity.BookingConfirmationCard'.
  final String? attachmentType;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:             json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId:       json['sender_id'] as String,
      senderName:     json['sender_name'] as String? ?? '',
      senderRole:     json['sender_role'] as String? ?? 'owner',
      content:        json['content'] as String? ?? '',
      createdAt:      DateTime.parse(json['created_at'] as String),
      isRead:         json['is_read'] as bool? ?? false,
      attachmentId:   json['attachment_id'] as String?,
      attachmentType: json['attachment_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'conversation_id': conversationId,
    'sender_id':      senderId,
    'sender_name':    senderName,
    'sender_role':    senderRole,
    'content':        content,
    'created_at':     createdAt.toIso8601String(),
    'is_read':        isRead,
    if (attachmentId != null)   'attachment_id':   attachmentId,
    if (attachmentType != null) 'attachment_type': attachmentType,
  };

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? attachmentId,
    String? attachmentType,
  }) {
    return MessageModel(
      id:             id             ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId:       senderId       ?? this.senderId,
      senderName:     senderName     ?? this.senderName,
      senderRole:     senderRole     ?? this.senderRole,
      content:        content        ?? this.content,
      createdAt:      createdAt      ?? this.createdAt,
      isRead:         isRead         ?? this.isRead,
      attachmentId:   attachmentId   ?? this.attachmentId,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

  @override
  String toString() =>
      'MessageModel(id: $id, sender: $senderName, read: $isRead)';
}
