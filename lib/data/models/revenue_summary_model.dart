// lib/data/models/revenue_summary_model.dart
//
// Aggregated revenue summary computed from transactions.
// Used by the owner finance screen and owner dashboard cards.
// Not stored in the database — computed from transaction records.
//
// The RevenueSummaryModel represents a snapshot in time.
// revenue_summary_provider.dart recomputes it whenever transactions change.

class RevenueSummaryModel {
  const RevenueSummaryModel({
    required this.totalRevenue,
    required this.totalCommissionsPaid,
    required this.totalRefunds,
    required this.netRevenue,
    required this.pendingPayments,
    required this.currencySymbol,
    required this.transactionCount,
    required this.periodLabel,
    required this.revenueByPartner,
  });

  /// Gross revenue from all completed client payments.
  final double totalRevenue;

  /// Total commission amounts paid or owed to partners.
  final double totalCommissionsPaid;

  /// Total refund amounts issued.
  final double totalRefunds;

  /// Net revenue = totalRevenue - totalCommissionsPaid - totalRefunds.
  final double netRevenue;

  /// Sum of all 'pending' transactions.
  final double pendingPayments;

  final String currencySymbol;
  final int transactionCount;

  /// Human-readable period label, e.g. 'All Time', 'Last 30 Days'.
  final String periodLabel;

  /// Breakdown of revenue attributed to each partner.
  /// Key = partnerId, Value = amount they generated.
  final Map<String, double> revenueByPartner;

  /// An empty summary — used while loading or when no data exists.
  static RevenueSummaryModel empty(String currencySymbol) {
    return RevenueSummaryModel(
      totalRevenue: 0,
      totalCommissionsPaid: 0,
      totalRefunds: 0,
      netRevenue: 0,
      pendingPayments: 0,
      currencySymbol: currencySymbol,
      transactionCount: 0,
      periodLabel: 'All Time',
      revenueByPartner: const {},
    );
  }

  RevenueSummaryModel copyWith({
    double? totalRevenue,
    double? totalCommissionsPaid,
    double? totalRefunds,
    double? netRevenue,
    double? pendingPayments,
    String? currencySymbol,
    int? transactionCount,
    String? periodLabel,
    Map<String, double>? revenueByPartner,
  }) {
    return RevenueSummaryModel(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCommissionsPaid: totalCommissionsPaid ?? this.totalCommissionsPaid,
      totalRefunds: totalRefunds ?? this.totalRefunds,
      netRevenue: netRevenue ?? this.netRevenue,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      transactionCount: transactionCount ?? this.transactionCount,
      periodLabel: periodLabel ?? this.periodLabel,
      revenueByPartner: revenueByPartner ?? this.revenueByPartner,
    );
  }

  @override
  String toString() =>
      'RevenueSummaryModel(net: $netRevenue, transactions: $transactionCount)';
}
