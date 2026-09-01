// lib/modules/gps/screens/gps_tracking_screen.dart
//
// Role-aware GPS tracking screen.
// Owner: sees the latest location point per tracked user.
// Staff: sees their own location history.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/gps_point_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/gps/providers/gps_notifier.dart';

class GpsTrackingScreen extends ConsumerWidget {
  const GpsTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsAsync  = ref.watch(gpsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('gps');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
        actions: [
          if (role.isStaff)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear my history',
              onPressed: () async {
                await ref.read(gpsNotifierProvider.notifier).clearMyPoints();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(gpsNotifierProvider),
        child: gpsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load location data.',
            onRetry: () => ref.invalidate(gpsNotifierProvider),
          ),
          data: (points) => points.isEmpty
              ? const AppEmptyState(
                  icon: Icons.location_off_outlined,
                  headline: 'No location data',
                  subtext:
                      'Location points will appear here when tracking is active.',
                )
              : _PointList(points: points),
        ),
      ),
    );
  }
}

class _PointList extends StatelessWidget {
  const _PointList({required this.points});
  final List<GpsPointModel> points;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: points.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _PointCard(point: points[index]),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.point});
  final GpsPointModel point;

  @override
  Widget build(BuildContext context) {
    final time = point.recordedAt.toLocal();
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(
          point.label ??
              '${point.latitude.toStringAsFixed(4)}, '
                  '${point.longitude.toStringAsFixed(4)}',
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Text(
          timeLabel,
          style:
              AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: point.accuracyMetres != null
            ? Text(
                '±${point.accuracyMetres!.toStringAsFixed(0)}m',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              )
            : null,
      ),
    );
  }
}
