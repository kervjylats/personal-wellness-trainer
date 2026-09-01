// lib/modules/activity/screens/activity_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/activity_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';
import 'package:personal_wellness_trainer/modules/activity/widgets/activity_status_badge.dart';

class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityNotifierProvider);
    final authState       = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile       = authState.profile;
    final role          = AppRole.fromString(profile.role);
    final jobConfig     = ref.watch(activeJobConfigProvider);
    final activityLabel = jobConfig.terminology.activities;
    final singleLabel   = jobConfig.terminology.activity;
    final engine        = ref.read(permissionsEngineProvider);
    final canCreate     = engine.canCreateActivity(profile);
    final theme = Theme.of(context);

    Future<void> onRefresh() async {
      ref.invalidate(activityNotifierProvider);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(activityLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _openCreate(context, role),
              tooltip: 'New $singleLabel',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: activitiesAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $activityLabel.',
            onRetry: () => ref.invalidate(activityNotifierProvider),
          ),
          data: (activities) => activities.isEmpty
              ? _EmptyState(role: role, singleLabel: singleLabel)
              : _ActivityList(
                  activities: activities,
                  onTap: (a) => _openDetail(context, role, a),
                ),
        ),
      ),
    );
  }

  void _openCreate(BuildContext context, AppRole role) {
    final name = switch (role) {
      AppRole.owner   => RouteNames.ownerActivityCreate,
      AppRole.partner => RouteNames.partnerActivityCreate,
      AppRole.staff   => RouteNames.staffActivityCreate,
      AppRole.client  => RouteNames.clientActivityCreate,
    };
    context.pushNamed(name);
  }

  void _openDetail(BuildContext context, AppRole role, ActivityModel activity) {
    final name = switch (role) {
      AppRole.owner   => RouteNames.ownerActivityDetail,
      AppRole.partner => RouteNames.partnerActivityDetail,
      AppRole.staff   => RouteNames.staffActivityDetail,
      AppRole.client  => RouteNames.clientActivityDetail,
    };
    context.pushNamed(name, extra: activity.id);
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities, required this.onTap});
  final List<ActivityModel>      activities;
  final ValueChanged<ActivityModel> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.md,
      ),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _ActivityTile(
        activity: activities[i],
        onTap: () => onTap(activities[i]),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.onTap});
  final ActivityModel activity;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = activity.fields['service_type']?.toString() ??
        activity.fields.values.firstOrNull?.toString() ??
        'Activity';

    final scheduledAt = activity.fields['scheduled_at']?.toString();
    final dateLabel = scheduledAt != null
        ? _formatScheduled(scheduledAt)
        : AppFormatters.dateTime(activity.createdAt);

    return Card(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _statusColor(colorScheme, activity.status).withAlpha(30),
          child: Icon(
            _statusIcon(activity.status),
            size: AppSpacing.iconSizeSm,
            color: _statusColor(colorScheme, activity.status),
          ),
        ),
        title: Text(title, style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(dateLabel, style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant)),
        trailing: ActivityStatusBadge(status: activity.status),
        onTap: onTap,
      ),
    );
  }

  String _formatScheduled(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return AppFormatters.dateTime(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(ColorScheme cs, String s) {
    switch (s) {
      case 'completed':  return cs.primary;
      case 'cancelled':  return cs.error;
      case 'in_progress': return cs.secondary;
      default:           return cs.tertiary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed':  return Icons.check_circle_outline;
      case 'cancelled':  return Icons.cancel_outlined;
      case 'in_progress': return Icons.play_circle_outline;
      default:           return Icons.radio_button_unchecked;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.role, required this.singleLabel});
  final AppRole role;
  final String  singleLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined,
                size: 64, color: colorScheme.onSurfaceVariant.withAlpha(120)),
            const SizedBox(height: AppSpacing.md),
            Text('No $singleLabel yet', style: AppTextStyles.headlineSmall.copyWith(color: colorScheme.onSurface)),
            if (role.isManagement) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tap + to create your first $singleLabel.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}