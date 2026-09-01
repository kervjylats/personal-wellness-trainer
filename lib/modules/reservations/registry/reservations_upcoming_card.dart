// lib/modules/reservations/registry/reservations_upcoming_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/reservations/providers/reservations_notifier.dart';

class ReservationsUpcomingCard extends ConsumerWidget {
  const ReservationsUpcomingCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationsNotifierProvider);
    return reservationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reservations) {
        final upcoming = reservations
            .where((r) =>
                r.status == 'pending' || r.status == 'confirmed')
            .toList();
        if (upcoming.isEmpty) return const SizedBox.shrink();
        final next = upcoming.first;
        final start = next.startTime.toLocal();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.event_available_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next: ${start.day}/${start.month} '
                        '${start.hour.toString().padLeft(2, '0')}:'
                        '${start.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '${upcoming.length} upcoming',
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
