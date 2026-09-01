// lib/data/models/message_attachment_model.dart
//
// Represents a card attachment pinned to a message.
// The attachmentType is a Widget Registry key (e.g. 'activity.BookingConfirmationCard').
// The payload is the data map passed to the registry builder.
// This allows any active module to attach cards without cross-module imports.

class MessageAttachmentModel {
  const MessageAttachmentModel({
    required this.id,
    required this.messageId,
    required this.attachmentType,
    required this.payload,
  });

  final String id;
  final String messageId;

  /// Widget Registry key. E.g. 'activity.BookingConfirmationCard'.
  final String attachmentType;

  /// Data passed to the registry builder.
  final Map<String, dynamic> payload;

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id:             json['id'] as String,
      messageId:      json['message_id'] as String,
      attachmentType: json['attachment_type'] as String,
      payload:        Map<String, dynamic>.from(
                        json['payload'] as Map<String, dynamic>? ?? {},
                      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'message_id':      messageId,
    'attachment_type': attachmentType,
    'payload':         payload,
  };

  @override
  String toString() =>
      'MessageAttachmentModel(id: $id, type: $attachmentType)';
}
