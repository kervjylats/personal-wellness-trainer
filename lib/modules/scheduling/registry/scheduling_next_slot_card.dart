// lib/modules/scheduling/registry/scheduling_next_slot_card.dart
//
// Registry widget: shows the next available slot.
// Registered as 'scheduling.NextSlotCard'.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/scheduling/providers/scheduling_notifier.dart';

class SchedulingNextSlotCard extends ConsumerWidget {
  const SchedulingNextSlotCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(schedulingNotifierProvider);
    return slotsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (slots) {
        final available = slots.where((s) => s.isAvailable).toList();
        if (available.isEmpty) return const SizedBox.shrink();
        final next = available.first;
        final start = next.startTime.toLocal();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next Available Slot',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(
                      '${start.day}/${start.month}  '
                      '${start.hour.toString().padLeft(2, '0')}:'
                      '${start.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
