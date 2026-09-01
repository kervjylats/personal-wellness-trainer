// lib/data/models/notification_model.dart
//
// Represents a single in-app notification.
// Created by engine events: new message, agreement proposed/approved,
// permission toggled, etc. Zero industry words.

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.referenceId,
    this.referenceType,
  });

  final String id;
  final String userId;
  final String businessId;
  final String title;
  final String body;

  /// Values: 'message' | 'agreement' | 'team' | 'activity' | 'system'
  final String type;

  final DateTime createdAt;
  final bool isRead;

  /// Optional ID of the related entity (conversation id, agreement id, etc.)
  final String? referenceId;

  /// Values: 'conversation' | 'agreement' | 'activity' | 'team_member'
  final String? referenceType;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:            json['id'] as String,
      userId:        json['user_id'] as String,
      businessId:    json['business_id'] as String,
      title:         json['title'] as String? ?? '',
      body:          json['body'] as String? ?? '',
      type:          json['type'] as String? ?? 'system',
      createdAt:     DateTime.parse(json['created_at'] as String),
      isRead:        json['is_read'] as bool? ?? false,
      referenceId:   json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'user_id':     userId,
    'business_id': businessId,
    'title':       title,
    'body':        body,
    'type':        type,
    'created_at':  createdAt.toIso8601String(),
    'is_read':     isRead,
    if (referenceId != null)   'reference_id':   referenceId,
    if (referenceType != null) 'reference_type': referenceType,
  };

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? title,
    String? body,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? referenceId,
    String? referenceType,
  }) {
    return NotificationModel(
      id:            id            ?? this.id,
      userId:        userId        ?? this.userId,
      businessId:    businessId    ?? this.businessId,
      title:         title         ?? this.title,
      body:          body          ?? this.body,
      type:          type          ?? this.type,
      createdAt:     createdAt     ?? this.createdAt,
      isRead:        isRead        ?? this.isRead,
      referenceId:   referenceId   ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
    );
  }

  @override
  String toString() =>
      'NotificationModel(id: $id, type: $type, read: $isRead)';
}
