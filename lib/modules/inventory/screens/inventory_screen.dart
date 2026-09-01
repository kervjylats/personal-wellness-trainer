// lib/modules/inventory/screens/inventory_screen.dart
//
// Inventory management screen. Owner-only.
// Shows all inventory records with stock levels and low-stock warnings.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/inventory_item_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/modules/inventory/providers/inventory_notifier.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryNotifierProvider);
    final authState      = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('inventory');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(inventoryNotifierProvider),
        child: inventoryAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $moduleLabel.',
            onRetry: () => ref.invalidate(inventoryNotifierProvider),
          ),
          data: (items) => items.isEmpty
              ? AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  headline: '$moduleLabel is empty',
                  subtext: 'Add catalog items to start tracking stock.',
                )
              : _InventoryList(items: items, ref: ref),
        ),
      ),
    );
  }
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({required this.items, required this.ref});
  final List<InventoryItemModel> items;
  final WidgetRef                ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<InventoryItemModel>(
      items: items,
      itemBuilder: (context, index, item) =>
          _InventoryCard(item: item, ref: ref),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.ref});
  final InventoryItemModel item;
  final WidgetRef          ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.catalogItemTitle ?? item.catalogItemId,
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        'Available: ${item.availableCount}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: item.isLowStock
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (item.isLowStock) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.warning_amber_outlined,
                            size: 14, color: AppColors.error),
                        Text(
                          ' Low',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.success,
                  tooltip: 'Increase stock',
                  onPressed: () => ref
                      .read(inventoryNotifierProvider.notifier)
                      .adjustStock(item.id, 1),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: item.availableCount > 0
                      ? AppColors.error
                      : AppColors.textSecondary,
                  tooltip: 'Decrease stock',
                  onPressed: item.availableCount > 0
                      ? () => ref
                          .read(inventoryNotifierProvider.notifier)
                          .adjustStock(item.id, -1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
