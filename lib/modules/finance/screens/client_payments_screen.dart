// lib/modules/finance/screens/client_payments_screen.dart
//
// The client's payment screen — own payment history and outstanding balance.
// Blueprint §5 hardcoded rule: client finance = own payments only.
//
// FIX: replaced private _StatusChip with shared FinanceStatusBadge
// from finance_widgets.dart. They were 97% identical.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_finance_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/modules/finance/widgets/finance_widgets.dart';

class ClientPaymentsScreen extends ConsumerWidget {
  const ClientPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile      = authState.profile;
    final config       = ref.watch(configProvider).valueOrNull;
    final currency     = config?.industry.payment.currencyDefault ?? r'$';
    final financeLabel = config?.industry.terminology.finance ?? 'Finance';

    final future = DataConfig.useMockData
        ? MockFinanceSource()
            .getTransactionsForUser(profile.businessId, profile.userId)
        : throw UnimplementedError('Phase 10');

    return Scaffold(
      appBar: AppBar(
        title: Text(financeLabel),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return ErrorDisplay(
              message: 'Could not load your payment history.',
              onRetry: () {},
            );
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: _ClientPaymentsBody(
              transactions: snapshot.data ?? [],
              profile:      profile,
              currency:     currency,
            ),
          );
        },
      ),
    );
  }
}

class _ClientPaymentsBody extends StatelessWidget {
  const _ClientPaymentsBody({
    required this.transactions,
    required this.profile,
    required this.currency,
  });

  final List<TransactionModel> transactions;
  final UserProfile            profile;
  final String                 currency;

  @override
  Widget build(BuildContext context) {
    double totalPaid = 0;
    for (final txn in transactions) {
      if (txn.type == 'payment' && txn.status == 'completed') {
        totalPaid += txn.amount;
      }
    }
    final outstanding = profile.outstandingBalance ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
      children: [
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _SummaryCard(label: 'Total Paid',  value: AppFormatters.currencyCompact(totalPaid, currency),    color: AppColors.success)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _SummaryCard(label: 'Outstanding', value: AppFormatters.currencyCompact(outstanding, currency), color: outstanding > 0 ? AppColors.error : AppColors.success)),
        ]),
        const SizedBox(height: AppSpacing.xl),
        const Text('Payment History', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (transactions.isEmpty)
          const FinanceEmptyState(message: 'No payment history yet.')
        else
          ...transactions.map((txn) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _colorForType(txn.type).withValues(alpha: 0.12),
                child: Icon(_iconForType(txn.type),
                    size: AppSpacing.iconSizeSm, color: _colorForType(txn.type)),
              ),
              title: Text(txn.description, style: AppTextStyles.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppFormatters.dateTime(txn.createdAt),
                  style: AppTextStyles.caption),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppFormatters.currency(txn.amount, currency),
                      style: AppTextStyles.labelMedium),
                  // FIX: was _StatusChip — now shared FinanceStatusBadge
                  FinanceStatusBadge(status: txn.status),
                ],
              ),
            ),
          )),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Color    _colorForType(String t) => switch(t) { 'refund' => AppColors.warning, 'payment' => AppColors.success, _ => AppColors.grey600 };
  IconData _iconForType(String t)  => switch(t) { 'refund' => Icons.undo, 'payment' => Icons.payments_outlined, _ => Icons.swap_horiz };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color});
  final String label; final String value; final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.titleLarge.copyWith(color: color)),
      ]),
    ),
  );
}
// _StatusChip removed — use FinanceStatusBadge from finance_widgets.dart
