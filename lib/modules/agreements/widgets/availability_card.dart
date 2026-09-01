// lib/modules/agreements/widgets/availability_card.dart
//
// The Availability Card — shown at the top of MarketplaceScreen.
// Lets the owner control their discoverability and open partnership slots.
//
// Blueprint §18 Hardcoded UI Rules enforced here:
//   Rule 3: Master "Discoverable" toggle MUST be ON before category toggles become interactive.
//   Rule 2: Category slots with an active agreement are greyed and non-interactive.
//   Owner's own category is NEVER shown in the toggle list (no self-pairing).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/marketplace_notifier.dart';

class AvailabilityCard extends ConsumerWidget {
  const AvailabilityCard({
    super.key,
    required this.marketplaceState,
    required this.activeAgreementCategories,
  });

  final MarketplaceState marketplaceState;
  final Set<String> activeAgreementCategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];
    final ownerCategoryId =
        marketplaceState.myListing?.ownerCategoryId ?? '';

    final toggleableCategories =
        categories.where((c) => c.id != ownerCategoryId).toList();

    final isDiscoverable = marketplaceState.isDiscoverable;
    final openCategories = marketplaceState.openCategories;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: AppSpacing.iconSize,
                  color: AppColors.grey600,
                ),
                SizedBox(width: AppSpacing.xs),
                Text('My Availability', style: AppTextStyles.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _ToggleRow(
              title: 'Discoverable',
              subtitle: isDiscoverable
                  ? 'Other owners can find you in the marketplace.'
                  : 'You are hidden from the marketplace.',
              value: isDiscoverable,
              locked: false,
              lockReason: null,
              onChanged: (_) => ref
                  .read(marketplaceNotifierProvider.notifier)
                  .toggleDiscoverable(),
            ),
            if (toggleableCategories.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                'Partnership Slots',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.grey600),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...toggleableCategories.map((category) {
                final lockedByAgreement =
                    activeAgreementCategories.contains(category.id);
                final disabled = !isDiscoverable;
                final isOpen = openCategories.contains(category.id);

                String? lockReason;
                if (lockedByAgreement) {
                  lockReason = 'Already partnered in this category';
                } else if (disabled) {
                  lockReason = 'Enable "Discoverable" first';
                }

                return _ToggleRow(
                  title: category.label,
                  subtitle: lockedByAgreement
                      ? 'Active agreement — slot is filled'
                      : isOpen
                          ? 'Open to partnership requests'
                          : 'Not currently seeking a partner',
                  value: isOpen,
                  locked: lockedByAgreement || disabled,
                  lockReason: lockReason,
                  onChanged: (lockedByAgreement || disabled)
                      ? null
                      : (_) => ref
                          .read(marketplaceNotifierProvider.notifier)
                          .toggleCategory(
                            categoryId: category.id,
                            lockedByAgreement: lockedByAgreement,
                          ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.locked,
    required this.lockReason,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool locked;
  final String? lockReason;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDisabled = locked || onChanged == null;

    return Opacity(
      opacity: isDisabled ? 0.50 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    lockReason ?? subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: locked
                          ? AppColors.grey400
                          : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isDisabled ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}