// lib/modules/agreements/widgets/availability_card.dart
//
// The Availability Card — shown at the top of MarketplaceScreen.
// Lets the owner control their discoverability and open partnership slots.
//
// Blueprint §18 Hardcoded UI Rules enforced here:
//   Rule 3: Master "Discoverable" toggle MUST be ON before category toggles become interactive.
//   Rule 2: Category slots with an active agreement are greyed and non-interactive.
//   Rule 4: Jobs already covered by an active agreement are not offered.
//   Owner's own category is hidden from the toggle list ONLY while the
//   same-job peer network is off (no self-pairing). Once they opt in, their
//   own job becomes a normal offerable slot — that is the whole point of
//   the switch, and without it an owner could never be discovered by
//   someone in their own trade.

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
    final mpConfig = config?.industry.partnershipMarketplace;
    final ownerCategoryId =
        marketplaceState.myListing?.ownerCategoryId ?? '';

    final showsToSameTitle = marketplaceState.showsToSameTitle;
    final sameTitleLocked =
        mpConfig != null && !mpConfig.sameTitleVisibilityOwnerCanToggle;

    // The owner's own trade is always listed now. While the same-job peer
    // network is off it stays greyed out with the reason spelled out —
    // otherwise the owner has no idea such a slot is even possible. The
    // previous hard filter hid it entirely, which read as "my trade can
    // never be a slot" rather than "turn this on first".
    final toggleableCategories = categories.toList();

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
            _ToggleRow(
              title: 'Visible to owners with the same job',
              subtitle: sameTitleLocked
                  ? 'Set by the platform'
                  : showsToSameTitle
                      ? 'Other owners in your trade can find you, and you '
                          'can find them'
                      : 'Off — you only connect with owners in other trades',
              value: showsToSameTitle,
              locked: sameTitleLocked,
              lockReason:
                  sameTitleLocked ? 'Controlled by the platform owner' : null,
              onChanged: sameTitleLocked
                  ? null
                  : (v) => ref
                      .read(marketplaceNotifierProvider.notifier)
                      .setShowToSameTitle(v),
            ),
            if (toggleableCategories.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text(
                'Collab Slots',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.grey600),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...toggleableCategories.map((category) {
                final lockedByAgreement =
                    activeAgreementCategories.contains(category.id);
                final disabled = !isDiscoverable;
                final isOwnCategory = category.id == ownerCategoryId;
                // Your own trade is only offerable once you have opened the
                // same-job network — that switch is the gate, and mutual
                // opt-in means the row is pointless without it.
                final lockedBySameTitle = isOwnCategory && !showsToSameTitle;
                final isOpen = openCategories.contains(category.id);

                String? lockReason;
                if (lockedByAgreement) {
                  lockReason = 'Already in a Collab in this category';
                } else if (disabled) {
                  lockReason = 'Enable "Discoverable" first';
                } else if (lockedBySameTitle) {
                  lockReason = sameTitleLocked
                      ? 'Your own trade is hidden on this platform'
                      : 'Turn on "Visible to owners with the same job" to '
                          'offer your own trade';
                }

                return _ToggleRow(
                  title: isOwnCategory
                      ? '${category.label} (your trade)'
                      : category.label,
                  subtitle: lockedByAgreement
                      ? 'Active agreement — slot is filled'
                      : isOwnCategory
                          ? 'Connects you with owners in your own trade'
                          : isOpen
                              ? 'Open to Collab requests'
                              : 'Not currently seeking an associate',
                  value: isOpen,
                  locked: lockedByAgreement || disabled || lockedBySameTitle,
                  lockReason: lockReason,
                  onChanged:
                      (lockedByAgreement || disabled || lockedBySameTitle)
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
            // Flutter's Switch carries no name of its own, so a screen reader
            // (and the test harness) announces every row as "switch". Name it
            // after the row title so each control is addressable.
            Semantics(
              label: title,
              child: Switch(
                value: value,
                onChanged: isDisabled ? null : onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}