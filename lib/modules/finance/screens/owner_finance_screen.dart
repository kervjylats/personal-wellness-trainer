// lib/modules/finance/screens/owner_finance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/models/commission_model.dart';
import 'package:personal_wellness_trainer/data/models/transaction_model.dart';
import 'package:personal_wellness_trainer/data/models/revenue_summary_model.dart';
import 'package:personal_wellness_trainer/data/repositories/agreements_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_agreements_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/commission_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/revenue_summary_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/widgets/finance_widgets.dart';

// ── Private deals provider ────────────────────────────────────────────────────

final _financeAgreementsRepoProvider = Provider<AgreementsRepository>((ref) {
  if (DataConfig.useMockData) return MockAgreementsSource();
  throw UnimplementedError('Supabase agreements source — Phase 10 only.');
});

final _financeDealsProvider =
    FutureProvider.autoDispose<List<AgreementModel>>(
  (ref) async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return [];
    final repo = ref.read(_financeAgreementsRepoProvider);
    return repo.getAgreements(auth.profile.businessId);
  },
  // See _activePartnersProvider in propose_agreement_screen.dart for why
  // this is required — same Riverpod scoping rule, same QA Console reason.
  dependencies: [authNotifierProvider],
);

// ── Screen ────────────────────────────────────────────────────────────────────

class OwnerFinanceScreen extends ConsumerWidget {
  const OwnerFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync  = ref.watch(transactionNotifierProvider);
    final commissionsAsync   = ref.watch(commissionNotifierProvider);
    final dealsAsync         = ref.watch(_financeDealsProvider);
    final summary            = ref.watch(revenueSummaryProvider);
    final jobConfig          = ref.watch(activeJobConfigProvider);
    final currency           = jobConfig.payment.currencyDefault;
    final financeLabel       = jobConfig.terminology.finance;
    final theme = Theme.of(context);

    Future<void> onRefresh() async {
      ref.invalidate(transactionNotifierProvider);
      ref.invalidate(commissionNotifierProvider);
      ref.invalidate(_financeDealsProvider);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(financeLabel),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: transactionsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load finance data.',
            onRetry: () => ref.invalidate(transactionNotifierProvider),
          ),
          data: (_) => _FinanceBody(
            summary: summary,
            currency: currency,
            commissionsAsync: commissionsAsync,
            dealsAsync: dealsAsync,
            ref: ref,
          ),
        ),
      ),
    );
  }
}

class _FinanceBody extends StatelessWidget {
  const _FinanceBody({
    required this.summary,
    required this.currency,
    required this.commissionsAsync,
    required this.dealsAsync,
    required this.ref,
  });

  final RevenueSummaryModel                  summary;
  final String                               currency;
  final AsyncValue<List<CommissionModel>>    commissionsAsync;
  final AsyncValue<List<AgreementModel>>     dealsAsync;
  final WidgetRef                            ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme       = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final transactions      = transactionsAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
      children: [
        const SizedBox(height: AppSpacing.md),
        ..._revenueSummarySection(colorScheme),
        const SizedBox(height: AppSpacing.xl),
        ..._transactionsSection(transactions),
        const SizedBox(height: AppSpacing.xl),
        ..._commissionsSection(),
        const SizedBox(height: AppSpacing.xl),
        ..._activeDealsSection(),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  List<Widget> _revenueSummarySection(ColorScheme cs) => [
    const _SectionHeader(title: 'Revenue Summary'),
    const SizedBox(height: AppSpacing.sm),
    Row(children: [
      Expanded(child: _SummaryCard(label: 'Net Revenue',
          value: AppFormatters.currencyCompact(summary.netRevenue, currency),
          color: cs.primary, icon: Icons.trending_up)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _SummaryCard(label: 'Total Revenue',
          value: AppFormatters.currencyCompact(summary.totalRevenue, currency),
          color: cs.secondary, icon: Icons.payments_outlined)),
    ]),
    const SizedBox(height: AppSpacing.sm),
    Row(children: [
      Expanded(child: _SummaryCard(label: 'Commissions',
          value: AppFormatters.currencyCompact(summary.totalCommissionsPaid, currency),
          color: cs.tertiary, icon: Icons.handshake_outlined)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _SummaryCard(label: 'Pending',
          value: AppFormatters.currencyCompact(summary.pendingPayments, currency),
          color: cs.onSurfaceVariant, icon: Icons.schedule)),
    ]),
  ];

  List<Widget> _transactionsSection(List<dynamic> transactions) => [
    _SectionHeader(title: 'Transactions', subtitle: '${summary.transactionCount} total'),
    const SizedBox(height: AppSpacing.sm),
    if (transactions.isEmpty)
      const FinanceEmptyState(message: 'No transactions yet.')
    else
      ...transactions.map((txn) => _TransactionTile(transaction: txn, currency: currency)),
  ];

  List<Widget> _commissionsSection() => [
    const _SectionHeader(title: 'Commission'),
    const SizedBox(height: AppSpacing.sm),
    commissionsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const FinanceEmptyState(message: 'Could not load commissions.'),
      data: (commissions) => commissions.isEmpty
          ? const FinanceEmptyState(message: 'No commissions yet.')
          : Column(children: commissions.map((c) => _CommissionTile(
                commission: c, currency: currency,
                onMarkPaid: c.status == 'pending'
                    ? () => ref.read(commissionNotifierProvider.notifier).markPaid(c.id)
                    : null,
              )).toList()),
    ),
  ];

  List<Widget> _activeDealsSection() => [
    const _SectionHeader(title: 'Deals'),
    const SizedBox(height: AppSpacing.sm),
    dealsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (_, __) => const FinanceEmptyState(message: 'Could not load deals.'),
      data: (agreements) {
        final active = agreements.where((a) => a.status == 'active').toList();
        if (active.isEmpty) return const FinanceEmptyState(message: 'No active deals.');
        return Column(children: active.map((a) => _DealTile(agreement: a)).toList());
      },
    ),
  ];
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String  title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: AppTextStyles.titleSmall.copyWith(color: theme.colorScheme.onSurface)),
        if (subtitle != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(subtitle!,
              style: AppTextStyles.caption
                  .copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String   label;
  final String   value;
  final Color    color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.labelSmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value,
                style: AppTextStyles.titleLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.currency});
  final TransactionModel transaction;
  final String           currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDebit = transaction.type == 'commission' ||
        transaction.type == 'refund' ||
        transaction.type == 'payout';
    
    final amountColor  = isDebit ? colorScheme.error : colorScheme.primary;
    final amountPrefix = isDebit ? '-' : '+';

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _typeColor(colorScheme, transaction.type).withAlpha(30),
          child: Icon(_typeIcon(transaction.type),
              size: AppSpacing.iconSizeSm,
              color: _typeColor(colorScheme, transaction.type)),
        ),
        title: Text(transaction.description,
            style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(AppFormatters.dateTime(transaction.createdAt),
            style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$amountPrefix${AppFormatters.currency(transaction.amount, currency)}',
              style:
                  AppTextStyles.labelMedium.copyWith(color: amountColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            FinanceStatusBadge(status: transaction.status),
          ],
        ),
      ),
    );
  }

  Color  _typeColor(ColorScheme cs, String t) => switch (t) {
        'payment'    => cs.primary,
        'commission' => cs.tertiary,
        'refund'     => cs.error,
        _            => cs.onSurfaceVariant,
      };
  IconData _typeIcon(String t) => switch (t) {
        'payment'    => Icons.payments_outlined,
        'commission' => Icons.handshake_outlined,
        'refund'     => Icons.undo,
        _            => Icons.swap_horiz,
      };
}

class _CommissionTile extends StatelessWidget {
  const _CommissionTile({
    required this.commission,
    required this.currency,
    this.onMarkPaid,
  });
  final CommissionModel commission;
  final String          currency;
  final VoidCallback?   onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: ListTile(
        title: Text(
          AppFormatters.currency(commission.amount, currency),
          style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
        ),
        subtitle: Text(commission.status.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: commission.status == 'paid'
                  ? colorScheme.primary
                  : colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            )),
        trailing: onMarkPaid != null
            ? TextButton(
                onPressed: onMarkPaid,
                child: Text('Mark Paid', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  const _DealTile({required this.agreement});
  final AgreementModel agreement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: ListTile(
        leading: Icon(Icons.handshake_outlined, color: colorScheme.primary),
        title: Text(agreement.id, style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface)),
        subtitle: Text(agreement.status.toUpperCase(),
            style: AppTextStyles.labelSmall
                .copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}