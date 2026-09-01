// lib/modules/finance/screens/partner_finance_screen.dart
//
// Partner's limited finance screen — own earnings and commission records only.
// Full revenue view: NEVER shown. (Blueprint §5 hardcoded rule)
//
// FIX: replaced private _EmptyState with shared FinanceEmptyState from
// finance_widgets.dart. Was 100% identical to _EmptyState in owner_finance_screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/core/widgets/upgrade_prompt.dart';
import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/commission_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/widgets/finance_widgets.dart';

class PartnerFinanceScreen extends ConsumerWidget {
  const PartnerFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final profile = authState.profile;

    final config        = ref.watch(configProvider).valueOrNull;
    final jobConfig     = ref.watch(activeJobConfigProvider);
    final currency      = config?.industry.payment.currencyDefault ?? r'$';
    final financeLabel  = config?.industry.terminology.finance ?? 'Finance';

    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final commissionsAsync  = ref.watch(commissionNotifierProvider);
    final agreementsAsync   = ref.watch(agreementsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(financeLabel),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionNotifierProvider);
          ref.invalidate(commissionNotifierProvider);
          ref.invalidate(agreementsNotifierProvider);
        },
        child: transactionsAsync.when(
          loading: () => const LoadingIndicator(),
          error:   (_, __) => const FinanceEmptyState(message: 'Could not load finance data.'),
          data:    (transactions) => _PartnerFinanceBody(
            profile:          profile,
            transactions:     transactions,
            commissionsAsync: commissionsAsync,
            agreementsAsync:  agreementsAsync,
            currency:         currency,
            jobConfig:        jobConfig,
          ),
        ),
      ),
    );
  }
}

class _PartnerFinanceBody extends StatelessWidget {
  const _PartnerFinanceBody({
    required this.profile,
    required this.transactions,
    required this.commissionsAsync,
    required this.agreementsAsync,
    required this.currency,
    required this.jobConfig,
  });

  final dynamic  profile;
  final List<dynamic> transactions;
  final AsyncValue<List<CommissionModel>> commissionsAsync;
  final AsyncValue<List<dynamic>>         agreementsAsync;
  final String   currency;
  final dynamic  jobConfig;

  @override
  Widget build(BuildContext context) {
    double totalEarnings = 0, pendingEarnings = 0;
    for (final txn in transactions) {
      if (txn.type == 'commission') {
        if (txn.status == 'completed') totalEarnings   += txn.amount as double;
        if (txn.status == 'pending')   pendingEarnings += txn.amount as double;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
      children: [
        const SizedBox(height: AppSpacing.md),
        UpgradePrompt(compact: true,
            buttonLabel: jobConfig.upgrade.buttonLabel as String, onUpgradeTap: () {}),
        const SizedBox(height: AppSpacing.lg),
        _earningsSummarySection(totalEarnings, pendingEarnings),
        const SizedBox(height: AppSpacing.xl),
        ..._myDealsSection(),
        const SizedBox(height: AppSpacing.xl),
        ..._myCommissionsSection(),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _earningsSummarySection(double total, double pending) {
    return Row(children: [
      Expanded(child: _EarningsCard(label: 'Total Earned', amount: total,   currency: currency, color: AppColors.success)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _EarningsCard(label: 'Pending',      amount: pending, currency: currency, color: AppColors.warning)),
    ]);
  }

  List<Widget> _myDealsSection() => [
    const Text('My Deals', style: AppTextStyles.titleMedium),
    const SizedBox(height: AppSpacing.sm),
    agreementsAsync.when(
      loading: () => const LoadingIndicator(),
      error:   (_, __) => const FinanceEmptyState(message: 'Could not load deals.'),
      data: (agreements) {
        final myAgreements = agreements.where((a) => a.partnerUserId == profile.userId).toList();
        if (myAgreements.isEmpty) return const FinanceEmptyState(message: 'No active deals.');
        return Column(children: myAgreements.map((agreement) {
          final earningsForDeal = transactions
              .where((t) => t.type == 'commission' && t.agreementId == agreement.id)
              .fold<double>(0, (sum, t) => sum + (t.amount as double));
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(agreement.categoryId as String, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Your rate: ${(agreement.partnerCommissionPct as double).toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall),
                  Text('Status: ${agreement.status}',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: agreement.isActive == true ? AppColors.success : AppColors.grey600)),
                ]),
                if (earningsForDeal > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(AppFormatters.currency(earningsForDeal, currency), style: AppTextStyles.titleSmall),
                ],
              ]),
            ),
          );
        }).toList());
      },
    ),
  ];

  List<Widget> _myCommissionsSection() => [
    const Text('My Commissions', style: AppTextStyles.titleMedium),
    const SizedBox(height: AppSpacing.sm),
    commissionsAsync.when(
      loading: () => const LoadingIndicator(),
      error:   (_, __) => const FinanceEmptyState(message: 'Could not load commissions.'),
      data: (commissions) => commissions.isEmpty
          ? const FinanceEmptyState(message: 'No commission records yet.')
          : Column(children: commissions
              .map((c) => _CommissionTile(commission: c, currency: currency)).toList()),
    ),
  ];
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.label, required this.amount, required this.currency, required this.color});
  final String label; final double amount; final String currency; final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(AppFormatters.currencyCompact(amount, currency),
            style: AppTextStyles.titleLarge.copyWith(color: color)),
      ]),
    ),
  );
}

class _CommissionTile extends StatelessWidget {
  const _CommissionTile({required this.commission, required this.currency});
  final CommissionModel commission; final String currency;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ListTile(
      title:    Text(AppFormatters.currency(commission.amount, currency), style: AppTextStyles.titleSmall),
      subtitle: Text(commission.status.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
              color: commission.status == 'paid' ? AppColors.success : AppColors.warning)),
    ),
  );
}
// _EmptyState removed — use FinanceEmptyState from finance_widgets.dart
