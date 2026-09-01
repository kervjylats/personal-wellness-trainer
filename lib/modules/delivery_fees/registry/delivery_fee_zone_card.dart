// lib/modules/delivery_fees/registry/delivery_fee_zone_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/currency_text.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/providers/delivery_fees_notifier.dart';

class DeliveryFeeZoneCard extends ConsumerWidget {
  const DeliveryFeeZoneCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(deliveryFeesNotifierProvider);
    return feesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (fees) {
        final active = fees.where((f) => f.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${active.length} delivery zone${active.length == 1 ? '' : 's'}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                CurrencyText(
                  amount: active.first.fee,
                  currencySymbol: active.first.currency,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
