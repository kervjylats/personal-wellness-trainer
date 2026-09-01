// lib/data/models/homework_model.dart
//
// A task assigned by a coach (owner/partner) to a specific client.

class HomeworkModel {
  final String id;
  final String businessId;
  final String assignedByUserId;
  final String assignedToUserId;
  final String assignedToUserName;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const HomeworkModel({
    required this.id,
    required this.businessId,
    required this.assignedByUserId,
    required this.assignedToUserId,
    required this.assignedToUserName,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      assignedByUserId: json['assigned_by_user_id'] as String,
      assignedToUserId: json['assigned_to_user_id'] as String,
      assignedToUserName: json['assigned_to_user_name'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'assigned_by_user_id': assignedByUserId,
        'assigned_to_user_id': assignedToUserId,
        'assigned_to_user_name': assignedToUserName,
        'title': title,
        'description': description,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      };

  HomeworkModel copyWith({
    String? id,
    String? businessId,
    String? assignedByUserId,
    String? assignedToUserId,
    String? assignedToUserName,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}