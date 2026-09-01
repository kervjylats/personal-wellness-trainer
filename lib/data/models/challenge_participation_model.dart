// lib/data/models/challenge_participation_model.dart
//
// Links a user to a challenge and tracks their completion.

class ChallengeParticipationModel {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final int completedDays;
  final DateTime? lastCompletedDate;

  const ChallengeParticipationModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    this.completedDays = 0,
    this.lastCompletedDate,
  });

  factory ChallengeParticipationModel.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipationModel(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? '',
      completedDays: json['completed_days'] as int? ?? 0,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'challenge_id': challengeId,
    'user_id': userId,
    'user_name': userName,
    'completed_days': completedDays,
    if (lastCompletedDate != null)
      'last_completed_date': lastCompletedDate!.toIso8601String(),
  };

  ChallengeParticipationModel copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    int? completedDays,
    DateTime? lastCompletedDate,
  }) {
    return ChallengeParticipationModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      completedDays: completedDays ?? this.completedDays,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}