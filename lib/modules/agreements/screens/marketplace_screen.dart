// lib/modules/agreements/screens/marketplace_screen.dart
//
// The Partnership Marketplace screen — owner-only, accessible from the
// Network screen.
//
// Layout:
//   1. AvailabilityCard — master toggle + per-category toggles.
//   2. Discovery results — tiles of compatible, discoverable owners.
//   3. Received requests — pending inbound requests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/marketplace_notifier.dart';
import 'package:personal_wellness_trainer/modules/agreements/screens/marketplace_profile_card.dart';
import 'package:personal_wellness_trainer/modules/agreements/widgets/availability_card.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(marketplaceActionErrorProvider, (_, error) {
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(marketplaceActionErrorProvider.notifier).state = null;
      }
    });

    final config = ref.watch(configProvider).valueOrNull;
    final partnerTerm = config?.industry.terminology.partner ?? 'Partner';

    return Scaffold(
      appBar: AppBar(
        title: Text('$partnerTerm Marketplace'),
        automaticallyImplyLeading: true,
      ),
      body: const _MarketplaceBody(),
    );
  }
}

class _MarketplaceBody extends ConsumerWidget {
  const _MarketplaceBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketplaceAsync = ref.watch(marketplaceNotifierProvider);

    return marketplaceAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(
        message: 'Could not load marketplace.',
        onRetry: () => ref.invalidate(marketplaceNotifierProvider),
      ),
      data: (marketplaceState) {
        final agreementsAsync = ref.watch(agreementsNotifierProvider);
        final activeAgreementCategories = agreementsAsync.valueOrNull
                ?.where((a) => a.isActive)
                .map((a) => a.categoryId)
                .toSet() ??
            {};

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(marketplaceNotifierProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical: AppSpacing.md,
            ),
            children: [
              AvailabilityCard(
                marketplaceState: marketplaceState,
                activeAgreementCategories: activeAgreementCategories,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (marketplaceState.openCategories.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.search_outlined,
                  title: 'Discover Partners',
                  count: marketplaceState.listings.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (marketplaceState.listings.isEmpty)
                  _EmptyDiscovery()
                else
                  ...marketplaceState.listings.map(
                    (listing) => _ListingTile(
                      listing: listing,
                      sentRequests: marketplaceState.sentRequests,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (marketplaceState.receivedRequests.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.inbox_outlined,
                  title: 'Received Requests',
                  count: marketplaceState.pendingReceivedCount,
                  badgeColor: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.sm),
                ...marketplaceState.receivedRequests
                    .where((r) => r.isPending)
                    .map(
                      (request) => _ReceivedRequestTile(request: request),
                    ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.badgeColor,
  });
  final IconData icon;
  final String title;
  final int count;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconSize, color: AppColors.grey600),
        const SizedBox(width: AppSpacing.xs),
        Text(title, style: AppTextStyles.titleSmall),
        const SizedBox(width: AppSpacing.xs),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: (badgeColor ?? Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelSmall.copyWith(
                color: badgeColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ListingTile extends ConsumerWidget {
  const _ListingTile({
    required this.listing,
    required this.sentRequests,
  });
  final MarketplaceListing listing;
  final List<PartnershipRequest> sentRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];
    final categoryLabel = categories
        .where((c) => c.id == listing.ownerCategoryId)
        .map((c) => c.label)
        .firstOrNull ??
        listing.ownerCategoryId;

    final hasPending = sentRequests.any(
      (r) =>
          r.receiverOwnerUserId == listing.ownerUserId && r.isPending,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            listing.businessName.avatarInitials,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(listing.businessName, style: AppTextStyles.bodyMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryLabel, style: AppTextStyles.labelSmall),
            if (listing.tagline != null)
              Text(
                listing.tagline!,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.grey600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: listing.tagline != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (listing.averageRating != null) ...[
              const Icon(Icons.star, size: 14, color: AppColors.warning),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                listing.averageRating!.toStringAsFixed(1),
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            if (hasPending)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.badgeRadius),
                ),
                child: Text(
                  'Pending',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.warning),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _showProfileCard(context, ref),
      ),
    );
  }

  void _showProfileCard(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MarketplaceProfileCard(
        listing: listing,
        sentRequests: sentRequests,
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 48,
              color: AppColors.grey400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No compatible partners found.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Check back later — more owners join every day.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.grey400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedRequestTile extends ConsumerWidget {
  const _ReceivedRequestTile({required this.request});
  final PartnershipRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];

    final senderCatLabel = categories
        .where((c) => c.id == request.senderCategoryId)
        .map((c) => c.label)
        .firstOrNull ??
        request.senderCategoryId;
    final receiverCatLabel = categories
        .where((c) => c.id == request.receiverCategoryId)
        .map((c) => c.label)
        .firstOrNull ??
        request.receiverCategoryId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    request.senderBusinessName.isNotEmpty
                        ? request.senderBusinessName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.senderBusinessName,
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '$senderCatLabel → $receiverCatLabel',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                request.message!,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(context, ref),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(context, ref),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final accepted = await ref
        .read(marketplaceNotifierProvider.notifier)
        .acceptRequest(request.id);
    if (accepted == null || !context.mounted) return;

    // Set commission rates and finalize the partnership on both sides.
    final rates = await showDialog<(double, double)>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfigureCommissionDialog(request: accepted),
    );
    if (rates == null || !context.mounted) return;

    final ok = await ref
        .read(agreementsNotifierProvider.notifier)
        .createMutualAgreementFromRequest(
          request: accepted,
          ownerCommissionPct: rates.$1,
          partnerCommissionPct: rates.$2,
        );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Partnership with ${accepted.senderBusinessName} is active. '
                  'They\'ll confirm their own rate from their side.'
              : 'Accepted, but finalizing the agreement failed — you can '
                  'set it up from your Agreements list instead.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    await ref
        .read(marketplaceNotifierProvider.notifier)
        .declineRequest(request.id);
  }
}

// ── Configure commission dialog ───────────────────────────────────────────────

class _ConfigureCommissionDialog extends ConsumerStatefulWidget {
  const _ConfigureCommissionDialog({required this.request});
  final PartnershipRequest request;

  @override
  ConsumerState<_ConfigureCommissionDialog> createState() =>
      _ConfigureCommissionDialogState();
}

class _ConfigureCommissionDialogState
    extends ConsumerState<_ConfigureCommissionDialog> {
  final _ownerCtrl = TextEditingController(text: '20');
  final _partnerCtrl = TextEditingController(text: '80');

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _partnerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];
    final senderCatLabel = categories
            .where((c) => c.id == widget.request.senderCategoryId)
            .map((c) => c.label)
            .firstOrNull ??
        widget.request.senderCategoryId;

    return AlertDialog(
      title: const Text('Set your commission split'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When your clients buy $senderCatLabel from '
            '${widget.request.senderBusinessName}, how should the split work?',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _ownerCtrl,
                  label: 'You keep (%)',
                  hint: '0–100',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _partnerCtrl,
                  label: 'They keep (%)',
                  hint: '0–100',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'These don\'t need to add up to 100 — each side is tracked '
            'independently. ${widget.request.senderBusinessName} will set '
            'their own rate for your ${_categoryLabel(widget.request.receiverCategoryId)} '
            'the same way, from their side.',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final owner = double.tryParse(_ownerCtrl.text) ?? 0;
            final partner = double.tryParse(_partnerCtrl.text) ?? 0;
            Navigator.of(context).pop((owner, partner));
          },
          child: const Text('Confirm partnership'),
        ),
      ],
    );
  }

  String _categoryLabel(String categoryId) {
    final config = ref.read(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];
    return categories
            .where((c) => c.id == categoryId)
            .map((c) => c.label)
            .firstOrNull ??
        categoryId;
  }
}