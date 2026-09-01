// lib/data/models/transaction_model.dart
//
// Represents a single financial transaction in the system.
// Transactions are created when:
//   - A client makes a payment for an activity
//   - A commission is disbursed to a partner
//   - A manual payment is recorded by the owner
//   - A refund is issued
//
// Immutable. fromJson/toJson for Supabase (Phase 10). copyWith for state updates.
// Zero business logic — this is a data container only.

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.businessId,
    required this.amount,
    required this.currencySymbol,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.description,
    this.activityId,
    this.fromUserId,
    this.toUserId,
    this.fromUserName,
    this.toUserName,
    this.commissionId,
    this.agreementId,      // NEW
    this.paymentProvider,
    this.externalRef,
    this.notes,
  });

  final String id;
  final String businessId;
  final double amount;
  final String currencySymbol;
  final String type;
  final String status;
  final DateTime createdAt;
  final String description;
  final String? activityId;
  final String? fromUserId;
  final String? toUserId;
  final String? fromUserName;
  final String? toUserName;
  final String? commissionId;
  final String? agreementId;      // NEW
  final String? paymentProvider;
  final String? externalRef;
  final String? notes;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencySymbol: json['currency_symbol'] as String? ?? r'$',
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String,
      activityId: json['activity_id'] as String?,
      fromUserId: json['from_user_id'] as String?,
      toUserId: json['to_user_id'] as String?,
      fromUserName: json['from_user_name'] as String?,
      toUserName: json['to_user_name'] as String?,
      commissionId: json['commission_id'] as String?,
      agreementId: json['agreement_id'] as String?,   // NEW
      paymentProvider: json['payment_provider'] as String?,
      externalRef: json['external_ref'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'amount': amount,
        'currency_symbol': currencySymbol,
        'type': type,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'description': description,
        if (activityId != null) 'activity_id': activityId,
        if (fromUserId != null) 'from_user_id': fromUserId,
        if (toUserId != null) 'to_user_id': toUserId,
        if (fromUserName != null) 'from_user_name': fromUserName,
        if (toUserName != null) 'to_user_name': toUserName,
        if (commissionId != null) 'commission_id': commissionId,
        if (agreementId != null) 'agreement_id': agreementId,   // NEW
        if (paymentProvider != null) 'payment_provider': paymentProvider,
        if (externalRef != null) 'external_ref': externalRef,
        if (notes != null) 'notes': notes,
      };

  TransactionModel copyWith({
    String? id,
    String? businessId,
    double? amount,
    String? currencySymbol,
    String? type,
    String? status,
    DateTime? createdAt,
    String? description,
    String? activityId,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? toUserName,
    String? commissionId,
    String? agreementId,      // NEW
    String? paymentProvider,
    String? externalRef,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      amount: amount ?? this.amount,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      activityId: activityId ?? this.activityId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      commissionId: commissionId ?? this.commissionId,
      agreementId: agreementId ?? this.agreementId,   // NEW
      paymentProvider: paymentProvider ?? this.paymentProvider,
      externalRef: externalRef ?? this.externalRef,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TransactionModel(id: $id, type: $type, amount: $amount, status: $status)';
}
