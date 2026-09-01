// lib/data/models/loyalty_models.dart

class LoyaltyPoints {
  final String userId;
  final int totalPoints;
  final List<PointTransaction> history;

  const LoyaltyPoints({
    required this.userId,
    this.totalPoints = 0,
    this.history = const [],
  });

  factory LoyaltyPoints.fromJson(Map<String, dynamic> json) {
    return LoyaltyPoints(
      userId: json['user_id'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => PointTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'total_points': totalPoints,
        'history': history.map((e) => e.toJson()).toList(),
      };
}

class PointTransaction {
  final String id;
  final String reason;
  final int amount; // positive = earned, negative = redeemed
  final DateTime date;

  const PointTransaction({
    required this.id,
    required this.reason,
    required this.amount,
    required this.date,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] as String,
      reason: json['reason'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': reason,
        'amount': amount,
        'date': date.toIso8601String(),
      };
}

class Reward {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final int pointsCost;
  final bool isActive;

  const Reward({
    required this.id,
    required this.businessId,
    required this.title,
    this.description = '',
    required this.pointsCost,
    this.isActive = true,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      pointsCost: json['points_cost'] as int,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'title': title,
        'description': description,
        'points_cost': pointsCost,
        'is_active': isActive,
      };
}