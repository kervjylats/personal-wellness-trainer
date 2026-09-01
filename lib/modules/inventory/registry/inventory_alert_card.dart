// lib/modules/inventory/registry/inventory_alert_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/inventory/providers/inventory_notifier.dart';

class InventoryAlertCard extends ConsumerWidget {
  const InventoryAlertCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryNotifierProvider);
    return inventoryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final low = items.where((i) => i.isLowStock).toList();
        if (low.isEmpty) return const SizedBox.shrink();
        return Card(
          color: AppColors.error.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${low.length} item${low.length == 1 ? '' : 's'} low on stock',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
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
