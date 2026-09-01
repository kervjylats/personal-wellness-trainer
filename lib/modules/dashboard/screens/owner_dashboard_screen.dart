// lib/modules/dashboard/screens/owner_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';
import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/dashboard/providers/dashboard_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots     = ref.watch(ownerDashboardSlotsProvider);
    final jobConfig = ref.watch(activeJobConfigProvider);
    final authState = ref.watch(authNotifierProvider);
    final jobsRegistryAsync = ref.watch(jobsRegistryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dashLabel    = jobConfig.terminology.dashboard;
    
    final personalName = authState is AuthAuthenticated ? authState.profile.displayName : '';
    final businessName = authState is AuthAuthenticated ? (authState.profile.businessName ?? '') : '';
    final jobId = authState is AuthAuthenticated ? (authState.profile.jobId) : null;

    String jobTitle = '';
    if (jobsRegistryAsync.valueOrNull != null && jobId != null) {
      final jobDef = jobsRegistryAsync.valueOrNull!.byId(jobId);
      if (jobDef != null) {
        jobTitle = jobDef.label;
      }
    }

    // Verify if businessName is just a default placeholder (e.g., contains 'Partner' or 'My')
    final isPlaceholder = businessName.isEmpty || 
                          businessName.contains('Partner') || 
                          businessName.contains('My');

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(dashboardRefreshBusProvider.notifier).state++;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.lg),

          // ── BESPOKE IDENTITY HEADER 👑 ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  personalName.isNotEmpty ? personalName : dashLabel,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                
                // Only show the business badge if it is a real custom business name, otherwise show job title
                if (!isPlaceholder)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                      border: Border.all(color: colorScheme.primary.withAlpha(50)),
                    ),
                    child: Text(
                      businessName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (jobTitle.isNotEmpty)
                  Text(
                    jobTitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          for (final slot in slots) _buildSlot(context, slot),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, String slot) {
    switch (slot) {
      case 'revenue_summary':
        return WidgetRegistry.build('finance.OwnerRevenueSlot', context);
      case 'upcoming_activity':
        return WidgetRegistry.build('activity.OwnerUpcomingSlot', context);
      case 'team_count':
        return WidgetRegistry.build('team.OwnerTeamCountSlot', context);
      case 'deal_count':
        return WidgetRegistry.build('agreements.OwnerDealCountSlot', context);
      default:
        return const SizedBox.shrink();
    }
  }
}