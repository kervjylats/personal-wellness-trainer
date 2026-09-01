// lib/modules/finance/registry/finance_dashboard_slots.dart
//
// Dashboard slot widgets contributed by the finance module.
// Registered in WidgetRegistry via FinanceRegistry.register().
// Dashboard screens consume these via WidgetRegistry.build(key, context).
//
// Registered keys:
//   'finance.OwnerRevenueSlot'   — revenue_summary slot  (owner dashboard)
//   'finance.PartnerEarningsSlot'— my_earnings slot      (partner dashboard)
//   'finance.ClientBalanceSlot'  — my_balance slot       (client dashboard)
//
// Pull-to-refresh:
//   Each slot listens to dashboardRefreshBusProvider. OwnerRevenueSlot and
//   ClientBalanceSlot invalidate transactionNotifierProvider (revenueSummaryProvider
//   auto-rebuilds from it). PartnerEarningsSlot invalidates commissionNotifierProvider.
//
// Blueprint §7 — cross-module widgets must go through WidgetRegistry.
// Blueprint §14 — no direct cross-module imports.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/commission_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/revenue_summary_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _cardShell({
  required String title,
  required IconData icon,
  required Widget child,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.iconSize, color: AppColors.grey600),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}

// ── Owner — revenue_summary slot ──────────────────────────────────────────────

/// Net revenue, commissions, pending breakdown. Used on the owner dashboard.
class OwnerRevenueSlot extends ConsumerWidget {
  const OwnerRevenueSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // revenueSummaryProvider is a computed Provider that watches
    // transactionNotifierProvider — invalidating transactions is enough.
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(transactionNotifierProvider);
    });

    final summary = ref.watch(revenueSummaryProvider);

    return _cardShell(
      title: 'Revenue Summary',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          _StatRow(
            label: 'Net Revenue',
            value: AppFormatters.currency(
                summary.netRevenue, summary.currencySymbol),
            valueStyle: AppTextStyles.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _StatRow(
            label: 'Gross Revenue',
            value: AppFormatters.currency(
                summary.totalRevenue, summary.currencySymbol),
          ),
          _StatRow(
            label: 'Commissions Paid',
            value: AppFormatters.currency(
                summary.totalCommissionsPaid, summary.currencySymbol),
            valueColor: AppColors.warning,
          ),
          if (summary.pendingPayments > 0)
            _StatRow(
              label: 'Pending',
              value: AppFormatters.currency(
                  summary.pendingPayments, summary.currencySymbol),
              valueColor: AppColors.grey600,
            ),
          const Divider(height: AppSpacing.md),
          _StatRow(
            label: 'Transactions',
            value: '${summary.transactionCount}',
            valueColor: AppColors.grey600,
          ),
        ],
      ),
    );
  }
}

// ── Partner — my_earnings slot ────────────────────────────────────────────────

/// Total earned + pending commissions for a partner.
class PartnerEarningsSlot extends ConsumerWidget {
  const PartnerEarningsSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(commissionNotifierProvider);
    });

    final commissionsAsync = ref.watch(commissionNotifierProvider);
    final agreementsAsync  = ref.watch(agreementsNotifierProvider);
    final config = ref.watch(configProvider).valueOrNull;
    final currency = config?.industry.payment.currencyDefault ?? r'$';

    return _cardShell(
      title: 'My Earnings',
      icon: Icons.account_balance_wallet_outlined,
      child: commissionsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load earnings.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (commissions) {
          final totalEarned = commissions.fold<double>(
            0,
            (sum, c) => c.status == 'paid' ? sum + c.amount : sum,
          );
          final pending = commissions.fold<double>(
            0,
            (sum, c) => c.status == 'pending' ? sum + c.amount : sum,
          );

          // Count active deals
          final activeDeals = agreementsAsync.valueOrNull
                  ?.where((a) => a.isActive)
                  .length ?? 0;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppFormatters.currency(totalEarned, currency),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Earned',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.grey600),
                      ),
                      if (activeDeals > 0)
                        Text(
                          '$activeDeals deal${activeDeals == 1 ? '' : 's'}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.success),
                        ),
                    ],
                  ),
                ],
              ),
              const Divider(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${commissions.length} commission'
                    '${commissions.length == 1 ? '' : 's'}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600),
                  ),
                  if (pending > 0)
                    Text(
                      '${AppFormatters.currency(pending, currency)} pending',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.warning),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Client — my_balance slot ──────────────────────────────────────────────────

/// Paid and pending payment totals for the current client.
class ClientBalanceSlot extends ConsumerWidget {
  const ClientBalanceSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(transactionNotifierProvider);
    });

    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final config = ref.watch(configProvider).valueOrNull;
    final currency = config?.industry.payment.currencyDefault ?? r'$';

    return _cardShell(
      title: 'My Balance',
      icon: Icons.payments_outlined,
      child: transactionsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (transactions) {
          final paid = transactions
              .where((t) => t.type == 'payment' && t.status == 'completed')
              .fold<double>(0, (sum, t) => sum + t.amount);
          final pending = transactions
              .where((t) => t.type == 'payment' && t.status == 'pending')
              .fold<double>(0, (sum, t) => sum + t.amount);

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600),
                  ),
                  Text(
                    AppFormatters.currency(paid, currency),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (pending > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey600),
                    ),
                    Text(
                      AppFormatters.currency(pending, currency),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Private shared widget ─────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.valueColor,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
          Text(
            value,
            style: valueStyle ??
                AppTextStyles.bodyMedium.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
