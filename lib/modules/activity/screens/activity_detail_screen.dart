// lib/modules/activity/screens/activity_detail_screen.dart
//
// Full detail view for a single activity.
// Displays all field values from ActivityModel.fields using FieldRenderer.
// Shows the status badge and a status change menu for owner/staff.
//
// Phase 9 fix (CRITICAL): activityLabel and activityFields now read from
// activeJobConfigProvider. Previously they read the platform base config,
// so the detail screen showed the wrong fields for the active job type
// (e.g. a Pilates Studio owner saw generic fields instead of Pilates fields).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';
import 'package:personal_wellness_trainer/modules/activity/widgets/activity_status_badge.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  static const List<String> _statuses = [
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityNotifierProvider);
    final authState       = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role          = AppRole.fromString(authState.profile.role);
    final jobConfig     = ref.watch(activeJobConfigProvider);
    final activityLabel = jobConfig.terminology.activity;
    final activityFields = jobConfig.activityFields;

    return Scaffold(
      appBar: AppBar(
        title: Text(activityLabel),
        actions: activitiesAsync.valueOrNull != null && role.isManagement
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) =>
                      _handleAction(context, ref, action, role),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'change_status',
                      child: Text('Change Status'),
                    ),
                    if (role.isOwner)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: AppTextStyles.listTileDestructive,
                        ),
                      ),
                  ],
                ),
              ]
            : null,
      ),
      body: activitiesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => const Center(
          child: Text(
            'Could not load activity.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (activities) {
          final activity =
              activities.where((a) => a.id == activityId).firstOrNull;

          if (activity == null) {
            return Center(
              child: Text(
                '$activityLabel not found.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    ActivityStatusBadge(status: activity.status),
                    const Spacer(),
                    Text(
                      AppFormatters.dateTime(activity.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                if (activityFields.isNotEmpty) ...[
                  const Text('Details', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  ...activityFields.map(
                    (field) => _FieldRow(
                      label: field.label,
                      value: activity.fields[field.name],
                      type: field.type,
                    ),
                  ),
                ] else ...[
                  ...activity.fields.entries.map(
                    (e) => _FieldRow(
                      label: e.key,
                      value: e.value,
                      type: 'text',
                    ),
                  ),
                ],

                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Text('Notes', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(activity.notes!, style: AppTextStyles.bodyMedium),
                ],

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    AppRole role,
  ) {
    switch (action) {
      case 'change_status':
        _showStatusSheet(context, ref);
      case 'delete':
        _confirmDelete(context, ref);
    }
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statuses
              .map((s) => ListTile(
                    title: Text(s.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.bodyMedium),
                    onTap: () {
                      ref
                          .read(activityNotifierProvider.notifier)
                          .updateStatus(activityId, s);
                      Navigator.of(context).pop();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Delete',
            isDestructive: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(activityNotifierProvider.notifier)
                  .delete(activityId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.type,
  });
  final String  label;
  final dynamic value;
  final String  type;

  @override
  Widget build(BuildContext context) {
    final display = _format(value, type);
    if (display.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(display, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _format(dynamic v, String t) {
    if (v == null) return '';
    final s = v.toString();
    if (s.isEmpty) return '';
    if (t == 'date' || t == 'datetime') {
      try {
        return AppFormatters.dateTime(DateTime.parse(s));
      } catch (_) {
        return s;
      }
    }
    return s;
  }
}
