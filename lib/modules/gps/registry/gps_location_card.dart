// lib/modules/gps/registry/gps_location_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/gps/providers/gps_notifier.dart';

class GpsLocationCard extends ConsumerWidget {
  const GpsLocationCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsAsync = ref.watch(gpsNotifierProvider);
    return gpsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (points) {
        if (points.isEmpty) return const SizedBox.shrink();
        final latest = points.first;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        latest.label ?? 'Last known location',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '${latest.latitude.toStringAsFixed(4)}, '
                        '${latest.longitude.toStringAsFixed(4)}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
