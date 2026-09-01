// lib/modules/activity/registry/activity_dashboard_slots.dart
//
// Dashboard slot widgets contributed by the activity module.
// Registered in WidgetRegistry via ActivityRegistry.register().
// Dashboard screens consume these via WidgetRegistry.build(key, context).
//
// Registered keys:
//   'activity.OwnerUpcomingSlot'  — upcoming_activity slot (owner dashboard)
//   'activity.StaffActivitiesSlot'— my_activities slot     (staff dashboard)
//   'activity.StaffCountSlot'     — assigned_count slot    (staff dashboard)
//   'activity.ClientNextSlot'     — next_activity slot     (client dashboard)
//
// Phase 9 fix: activityLabel now reads from activeJobConfigProvider so the
// slot titles say "Upcoming Classes" (Pilates/Yoga) not "Upcoming Activities".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/dashboard_count_chip.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

// _statusColor removed — use AppColors.forStatus() from core/theme/app_colors.dart

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

// ── Owner — upcoming_activity slot ───────────────────────────────────────────

/// Shows the 3 most recent activities. Used on the owner dashboard.
class OwnerUpcomingSlot extends ConsumerWidget {
  const OwnerUpcomingSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(activityNotifierProvider);
    });

    final activitiesAsync = ref.watch(activityNotifierProvider);
    final jobConfig       = ref.watch(activeJobConfigProvider);
    final activityLabel   = jobConfig.terminology.activities;

    return _cardShell(
      title: 'Upcoming $activityLabel',
      icon: Icons.event_note_outlined,
      child: activitiesAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (activities) {
          final preview = activities.take(3).toList();
          if (preview.isEmpty) {
            return Text(
              'No $activityLabel yet.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            );
          }
          return Column(
            children: [
              for (final a in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.forStatus(a.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          a.fields['service_type']?.toString() ??
                              a.fields.values.firstOrNull?.toString() ??
                              a.id,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        a.status,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
              if (activities.length > 3)
                Text(
                  '+${activities.length - 3} more',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey400),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Staff — my_activities slot ────────────────────────────────────────────────

/// Shows activities assigned to the current staff member.
class StaffActivitiesSlot extends ConsumerWidget {
  const StaffActivitiesSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(activityNotifierProvider);
    });

    final activitiesAsync = ref.watch(activityNotifierProvider);
    final jobConfig       = ref.watch(activeJobConfigProvider);
    final activityLabel   = jobConfig.terminology.activities;

    return _cardShell(
      title: 'My $activityLabel',
      icon: Icons.assignment_outlined,
      child: activitiesAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (activities) {
          final recent = activities.take(5).toList();
          if (recent.isEmpty) {
            return Text(
              'No $activityLabel assigned.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            );
          }
          return Column(
            children: recent
                .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.forStatus(a.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              a.fields['service_type']?.toString() ??
                                  a.fields.values.firstOrNull?.toString() ??
                                  a.id,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            a.status,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.grey600),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ── Staff — assigned_count slot ───────────────────────────────────────────────

/// Shows total assigned vs completed count for the current staff member.
class StaffCountSlot extends ConsumerWidget {
  const StaffCountSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(activityNotifierProvider);
    });

    final activitiesAsync = ref.watch(activityNotifierProvider);
    final jobConfig       = ref.watch(activeJobConfigProvider);
    final activityLabel   = jobConfig.terminology.activities;

    return _cardShell(
      title: '$activityLabel Overview',
      icon: Icons.bar_chart_outlined,
      child: activitiesAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (activities) {
          final total     = activities.length;
          final completed = activities.where((a) => a.status == 'completed').length;
          final pending   = activities.where((a) => a.status == 'pending').length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DashboardCountChip(count: total,     label: 'Total'),
              DashboardCountChip(count: completed, label: 'Done',    color: AppColors.success),
              DashboardCountChip(count: pending,   label: 'Pending', color: AppColors.warning),
            ],
          );
        },
      ),
    );
  }
}

// ── Client — next_activity slot ───────────────────────────────────────────────

/// Shows the client's next upcoming activity.
class ClientNextSlot extends ConsumerWidget {
  const ClientNextSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(dashboardRefreshBusProvider, (_, __) {
      ref.invalidate(activityNotifierProvider);
    });

    final activitiesAsync = ref.watch(activityNotifierProvider);
    final jobConfig       = ref.watch(activeJobConfigProvider);
    final activityLabel   = jobConfig.terminology.activity;

    return _cardShell(
      title: 'Your Next $activityLabel',
      icon: Icons.event_outlined,
      child: activitiesAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => Text(
          'Could not load.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        data: (activities) {
          final upcoming = activities
              .where((a) => a.status == 'confirmed' || a.status == 'pending')
              .toList();
          if (upcoming.isEmpty) {
            return Text(
              'No upcoming $activityLabel.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            );
          }
          final next = upcoming.first;
          return Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.forStatus(next.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  next.fields['service_type']?.toString() ??
                      next.fields.values.firstOrNull?.toString() ??
                      next.id,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

