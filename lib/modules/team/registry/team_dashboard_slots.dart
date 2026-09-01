// lib/modules/team/registry/team_dashboard_slots.dart
//
// Dashboard slot widgets contributed by the team module.
// Registered in WidgetRegistry via TeamRegistry.register().
// Dashboard screens consume these via WidgetRegistry.build(key, context).
//
// Registered keys:
//   'team.OwnerTeamCountSlot' — team_count slot (owner dashboard)
//
// Pull-to-refresh:
//   Listens to dashboardRefreshBusProvider and invalidates
//   teamNotifierProvider when the counter increments.
//
// Blueprint §7 — cross-module widgets must go through WidgetRegistry.
// Blueprint §14 — no direct cross-module imports.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/dashboard_count_chip.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';

// ── Owner — team_count slot ───────────────────────────────────────────────────

/// Partner / staff / client count breakdown. Used on the owner dashboard.
class OwnerTeamCountSlot extends ConsumerWidget {
  const OwnerTeamCountSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(teamNotifierProvider);
    });

    final teamAsync = ref.watch(teamNotifierProvider);
    final config = ref.watch(configProvider).valueOrNull;
    final term = config?.industry.terminology;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: AppSpacing.iconSize,
                  color: AppColors.grey600,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    term?.team ?? 'Team',
                    style: AppTextStyles.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            teamAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(
                'Could not load.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey600),
              ),
              data: (members) {
                final partners =
                    members.where((m) => m.role == 'partner').length;
                final staff = members.where((m) => m.role == 'staff').length;
                final clients = members.where((m) => m.role == 'client').length;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    DashboardCountChip(
                        count: partners, label: term?.partner ?? 'Partners'),
                    DashboardCountChip(count: staff, label: term?.staff ?? 'Staff'),
                    DashboardCountChip(count: clients, label: term?.client ?? 'Clients'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

