import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/currency_text.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';
import 'package:personal_wellness_trainer/modules/catalog/providers/catalog_notifier.dart';
import 'package:personal_wellness_trainer/modules/discover/providers/partner_offers_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';
import 'package:personal_wellness_trainer/modules/media/providers/media_notifier.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activityNotifierProvider);
    final catalogAsync = ref.watch(catalogNotifierProvider);
    final mediaAsync = ref.watch(mediaNotifierProvider);
    final partnerOffersAsync = ref.watch(partnerOffersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activityNotifierProvider);
        ref.invalidate(catalogNotifierProvider);
        ref.invalidate(mediaNotifierProvider);
        ref.invalidate(partnerOffersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),
          // ── From Your Coach ─────────────────────────────────────────────
          const Text('From Your Coach', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),

          // Upcoming Sessions
          activitiesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (activities) {
              final upcoming = activities
                  .where((a) => a.status == 'confirmed' || a.status == 'pending')
                  .take(3)
                  .toList();
              if (upcoming.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming Sessions', style: AppTextStyles.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  ...upcoming.map((a) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          leading: Icon(Icons.event,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(
                            a.fields['service_type']?.toString() ??
                                a.fields.values.firstOrNull?.toString() ??
                                a.id,
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: Text(a.status, style: AppTextStyles.caption),
                        ),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),

          // Coach's Catalog
          catalogAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              final active = items.where((i) => i.isActive).take(3).toList();
              if (active.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available to Buy', style: AppTextStyles.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  ...active.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          leading: const Icon(Icons.storefront, color: AppColors.moduleCatalog),
                          title: Text(item.title, style: AppTextStyles.bodyMedium),
                          trailing: CurrencyText(
                            amount: item.price,
                            currencySymbol: item.currency,
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),

          // Coach's Media
          mediaAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              final public = items.where((i) => i.isPublic).take(3).toList();
              if (public.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Content Library', style: AppTextStyles.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  ...public.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          leading: const Icon(Icons.play_circle, color: AppColors.moduleMedia),
                          title: Text(item.title, style: AppTextStyles.bodyMedium),
                          subtitle: Text(item.mediaType, style: AppTextStyles.caption),
                        ),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),

          // ── From Our Partners ───────────────────────────────────────────
          const Text('From Our Partners', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          partnerOffersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (offers) {
              if (offers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'Nothing from partners yet — check back once your '
                    'coach forms a new partnership.',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }
              return Column(
                children: offers
                    .map((offer) => _PartnerOfferCard(offer: offer))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _PartnerOfferCard extends ConsumerWidget {
  const _PartnerOfferCard({required this.offer});
  final PartnerOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    offer.partnerBusinessName.isNotEmpty
                        ? offer.partnerBusinessName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(offer.partnerBusinessName,
                      style: AppTextStyles.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...offer.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _PartnerOfferItemTile(offer: offer, item: item),
                )),
          ],
        ),
      ),
    );
  }
}

class _PartnerOfferItemTile extends ConsumerStatefulWidget {
  const _PartnerOfferItemTile({required this.offer, required this.item});
  final PartnerOffer offer;
  final CatalogItemModel item;

  @override
  ConsumerState<_PartnerOfferItemTile> createState() =>
      _PartnerOfferItemTileState();
}

class _PartnerOfferItemTileState extends ConsumerState<_PartnerOfferItemTile> {
  bool _buying = false;

  Future<void> _buy(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm purchase'),
        content: Text(
          'Buy "${widget.item.title}" from ${widget.offer.partnerBusinessName} '
          'for ${widget.item.currency}${widget.item.price.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _buying = true);
    final ok = await ref
        .read(transactionNotifierProvider.notifier)
        .purchaseFromPartner(offer: widget.offer, item: widget.item);
    if (!mounted || !context.mounted) return;
    setState(() => _buying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Purchased "${widget.item.title}".'
            : 'Purchase failed — please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.storefront, color: AppColors.moduleCatalog),
      title: Text(widget.item.title, style: AppTextStyles.bodyMedium),
      trailing: _buying
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () => _buy(context),
              child: CurrencyText(
                amount: widget.item.price,
                currencySymbol: widget.item.currency,
                style: AppTextStyles.labelMedium,
              ),
            ),
    );
  }
}