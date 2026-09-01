// lib/data/models/commission_model.dart
//
// A commission record is created when an agreement deal triggers a payout.
// The commission links a partner, an agreement, an activity (optional),
// and the resulting transaction.
//
// Commission models are read-only from the partner's perspective.
// The owner sees all commissions. The partner sees only their own.
//
// Immutable. fromJson/toJson. copyWith.

class CommissionModel {
  const CommissionModel({
    required this.id,
    required this.businessId,
    required this.agreementId,
    required this.partnerId,
    required this.partnerName,
    required this.amount,
    required this.currencySymbol,
    required this.rate,
    required this.rateType,
    required this.status,
    required this.createdAt,
    this.activityId,
    this.transactionId,
    this.description,
    this.paidAt,
  });

  final String id;
  final String businessId;

  /// The agreement that governs this commission.
  final String agreementId;

  final String partnerId;
  final String partnerName;

  /// Commission amount in the business's currency.
  final double amount;
  final String currencySymbol;

  /// The rate applied (percentage or fixed amount).
  final double rate;

  /// Values: 'percentage' | 'fixed'
  final String rateType;

  /// Values: 'pending' | 'paid' | 'cancelled'
  final String status;

  final DateTime createdAt;

  /// The activity that generated this commission, if applicable.
  final String? activityId;

  /// The transaction created when this commission was paid out.
  final String? transactionId;

  final String? description;
  final DateTime? paidAt;

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      agreementId: json['agreement_id'] as String,
      partnerId: json['partner_id'] as String,
      partnerName: json['partner_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencySymbol: json['currency_symbol'] as String? ?? r'$',
      rate: (json['rate'] as num).toDouble(),
      rateType: json['rate_type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      activityId: json['activity_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      description: json['description'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'agreement_id': agreementId,
        'partner_id': partnerId,
        'partner_name': partnerName,
        'amount': amount,
        'currency_symbol': currencySymbol,
        'rate': rate,
        'rate_type': rateType,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        if (activityId != null) 'activity_id': activityId,
        if (transactionId != null) 'transaction_id': transactionId,
        if (description != null) 'description': description,
        if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      };

  CommissionModel copyWith({
    String? id,
    String? businessId,
    String? agreementId,
    String? partnerId,
    String? partnerName,
    double? amount,
    String? currencySymbol,
    double? rate,
    String? rateType,
    String? status,
    DateTime? createdAt,
    String? activityId,
    String? transactionId,
    String? description,
    DateTime? paidAt,
  }) {
    return CommissionModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      agreementId: agreementId ?? this.agreementId,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      amount: amount ?? this.amount,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      rate: rate ?? this.rate,
      rateType: rateType ?? this.rateType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      activityId: activityId ?? this.activityId,
      transactionId: transactionId ?? this.transactionId,
      description: description ?? this.description,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommissionModel(id: $id, partner: $partnerName, amount: $amount, status: $status)';
}
