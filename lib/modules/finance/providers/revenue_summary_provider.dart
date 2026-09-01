// lib/modules/finance/providers/revenue_summary_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/data/models/revenue_summary_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';

final revenueSummaryProvider = Provider<RevenueSummaryModel>(
  (ref) {
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final configAsync = ref.watch(configProvider);
    final agreementsAsync = ref.watch(agreementsNotifierProvider);

    final currency =
        configAsync.valueOrNull?.industry.payment.currencyDefault ?? r'$';
    final agreements = agreementsAsync.valueOrNull ?? [];

    return transactionsAsync.when(
      loading: () => RevenueSummaryModel.empty(currency),
      error: (_, __) => RevenueSummaryModel.empty(currency),
      data: (transactions) => _compute(transactions, currency, agreements),
    );
  },
  // transactionNotifierProvider and agreementsNotifierProvider both watch
  // authNotifierProvider — see lib/dev_tools/qa_console_screen.dart for
  // why this matters. configProvider is NOT listed: it's never overridden
  // anywhere, so Riverpod doesn't require declaring it.
  dependencies: [transactionNotifierProvider, agreementsNotifierProvider],
);

RevenueSummaryModel _compute(
  List<TransactionModel> transactions,
  String currency,
  List<dynamic> agreements,   
) {
  double totalRevenue = 0;
  double totalCommissions = 0;
  double totalRefunds = 0;
  double pendingPayments = 0;
  final revenueByPartner = <String, double>{};

  for (final txn in transactions) {
    switch (txn.type) {
      case 'payment':
        if (txn.status == 'completed') {
          totalRevenue += txn.amount;
        } else if (txn.status == 'pending') {
          pendingPayments += txn.amount;
        }
      case 'commission':
        if (txn.status == 'completed' || txn.status == 'pending') {
          totalCommissions += txn.amount;
          // FIX: Added null safety check to prevent NullAssertion crashes
          if (txn.toUserId != null) {
            revenueByPartner[txn.toUserId!] =
                (revenueByPartner[txn.toUserId!] ?? 0) + txn.amount;
          }
        }
      case 'refund':
        if (txn.status == 'completed') {
          totalRefunds += txn.amount;
        }
    }
  }

  final net = totalRevenue - totalCommissions - totalRefunds;

  return RevenueSummaryModel(
    totalRevenue: totalRevenue,
    totalCommissionsPaid: totalCommissions,
    totalRefunds: totalRefunds,
    netRevenue: net,
    pendingPayments: pendingPayments,
    currencySymbol: currency,
    transactionCount: transactions.length,
    periodLabel: 'All Time',
    revenueByPartner: revenueByPartner,
  );
}