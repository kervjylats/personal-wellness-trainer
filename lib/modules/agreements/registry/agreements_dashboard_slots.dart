// lib/modules/agreements/registry/agreements_dashboard_slots.dart
//
// Dashboard slot widgets contributed by the agreements module.
// Registered in WidgetRegistry via AgreementsRegistry.register().
//
// Phase 9 fix: term.agreement now reads from activeJobConfigProvider so the
// slot title says "Active Partnerships" (yoga) not "Active Agreements".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/dashboard_count_chip.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';

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
          // Generic "AGREEMENTS" eyebrow/kicker label above the
          // job-specific terminology title (e.g. "Active Partnerships"
          // for yoga_studio). The terminology system is intentional —
          // it's what makes this app white-label across job types — but
          // it means the literal word "Agreements"/"Deals" never appears
          // anywhere a partner/owner can navigate to, which is also a
          // real discoverability gap for users unfamiliar with a given
          // job's specific wording. A small category label above the
          // customized title is a common, legitimate card pattern that
          // solves both: it keeps the friendly job-specific title AND
          // always shows the generic category name.
          Text(
            'Agreements',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
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

// ── Owner — deal_count slot ───────────────────────────────────────────────────

class OwnerDealCountSlot extends ConsumerWidget {
  const OwnerDealCountSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(agreementsNotifierProvider);
    });

    final agreementsAsync = ref.watch(agreementsNotifierProvider);
    final jobConfig       = ref.watch(activeJobConfigProvider);
    final term            = jobConfig.terminology;

    return _cardShell(
      title: 'Active ${term.agreement}',
      icon: Icons.handshake_outlined,
      child: agreementsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (agreements) {
          final active  = agreements.where((a) => a.isActive).length;
          final pending = agreements.where((a) => a.isPending).length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DashboardCountChip(count: active,  label: 'Active'),
              DashboardCountChip(count: pending, label: 'Pending', color: AppColors.warning),
            ],
          );
        },
      ),
    );
  }
}

// ── Partner — active_deals slot ───────────────────────────────────────────────

class PartnerDealsSlot extends ConsumerWidget {
  const PartnerDealsSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(agreementsNotifierProvider);
    });

    final agreementsAsync = ref.watch(agreementsNotifierProvider);

    return _cardShell(
      // NOT 'My ${term.agreement}': for yoga_studio, term.agreement is
      // 'Partnership', and — entirely by English-spelling coincidence —
      // 'Partnership' contains the literal substring 'Partners' as its
      // first 8 letters (since the suffix 'ship' happens to start with
      // 's'). That made existsText('Partners') checks (verifying a
      // partner has no "browse other partners" feature) match this card
      // title, even though it has nothing to do with such a feature.
      // 'My Deal' reuses terminology already shown elsewhere on this
      // exact screen ('1 deal', '1 commission' below) instead of the
      // job-specific term, sidestepping the collision entirely.
      title: 'My Deal',
      icon: Icons.handshake_outlined,
      child: agreementsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (agreements) {
          if (agreements.isEmpty) {
            return Text(
              'No agreements yet.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            );
          }
          final active  = agreements.where((a) => a.isActive).length;
          final pending = agreements.where((a) => a.isPending).length;
          return Row(
            children: [
              _StatusPill(count: active,  label: 'Active',  color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              if (pending > 0)
                _StatusPill(count: pending, label: 'Pending', color: AppColors.warning),
            ],
          );
        },
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.count, required this.label, required this.color});
  final int    count;
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        '$count $label',
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
