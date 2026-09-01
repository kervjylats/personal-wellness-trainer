// lib/modules/loyalty/screens/loyalty_screen.dart
// FIX: added `if (!context.mounted) return;` after `await showDialog` in _redeem().
// The widget is a ConsumerWidget so `mounted` isn't available — use `context.mounted`.
// Without the guard, if the client navigates away while the confirm dialog is open,
// the subsequent `await ref.read(...).redeem(...)` runs on a stale context tree and
// the final `context.mounted` SnackBar check may still pass on some Flutter versions.
// Belt-and-suspenders: bail out immediately after the dialog if context is gone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/modules/loyalty/providers/loyalty_notifier.dart';
import 'package:personal_wellness_trainer/modules/loyalty/providers/rewards_notifier.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync  = ref.watch(loyaltyNotifierProvider);
    final rewardsAsync = ref.watch(rewardsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── Points balance ──────────────────────────────────────────────
          pointsAsync.when(
            loading: () => const LoadingIndicator(),
            error:   (e, _) => const Text('Could not load points.'),
            data: (points) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(children: [
                  const Icon(Icons.stars, size: 48, color: AppColors.warning),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${points.totalPoints}',
                      style: AppTextStyles.displayLarge.copyWith(color: AppColors.warning)),
                  const Text('Available Points', style: AppTextStyles.bodyMedium),
                ]),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Available rewards ───────────────────────────────────────────
          const Text('Redeem Rewards', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          rewardsAsync.when(
            loading: () => const LoadingIndicator(),
            error:   (e, _) => const Text('Could not load rewards.'),
            data: (rewards) {
              final active = rewards.where((r) => r.isActive).toList();
              if (active.isEmpty) {
                return const Text('No rewards available yet.', style: AppTextStyles.bodyMedium);
              }
              return Column(
                children: active.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.warning.withAlpha(30),
                      child: Text('${r.pointsCost}', style: AppTextStyles.labelMedium),
                    ),
                    title:    Text(r.title, style: AppTextStyles.titleMedium),
                    subtitle: r.description.isNotEmpty
                        ? Text(r.description, style: AppTextStyles.caption)
                        : null,
                    trailing: FilledButton.tonal(
                      onPressed: () => _redeem(context, ref, r),
                      child: const Text('Redeem'),
                    ),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Transaction history ─────────────────────────────────────────
          const Text('History', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          pointsAsync.when(
            loading: () => const LoadingIndicator(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (points) {
              if (points.history.isEmpty) {
                return const Text('No transactions yet.', style: AppTextStyles.bodyMedium);
              }
              return Column(
                children: points.history.reversed.map((t) => ListTile(
                  dense: true,
                  leading: Icon(
                    t.amount > 0 ? Icons.add_circle : Icons.remove_circle,
                    color: t.amount > 0 ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  title: Text(t.reason, style: AppTextStyles.bodySmall),
                  trailing: Text(
                    '${t.amount > 0 ? '+' : ''}${t.amount}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: t.amount > 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Future<void> _redeem(BuildContext context, WidgetRef ref, dynamic reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   Text(reward.title),
        content: Text('Redeem for ${reward.pointsCost} points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Redeem')),
        ],
      ),
    );

    // FIX: guard before proceeding. If the user navigated away while the dialog
    // was open, context is no longer valid and the ref may be stale.
    if (confirm != true || !context.mounted) return;

    final success = await ref.read(loyaltyNotifierProvider.notifier).redeem(
          amount: reward.pointsCost,
          reason: 'Redeemed: ${reward.title}',
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(success ? 'Reward redeemed!' : 'Not enough points.'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    }
  }
}
