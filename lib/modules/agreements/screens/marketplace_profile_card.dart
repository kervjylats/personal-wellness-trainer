// lib/modules/agreements/screens/marketplace_profile_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/marketplace_notifier.dart';

class MarketplaceProfileCard extends ConsumerStatefulWidget {
  const MarketplaceProfileCard({
    super.key,
    required this.listing,
    required this.sentRequests,
  });
  final MarketplaceListing listing;
  final List<PartnershipRequest> sentRequests;

  @override
  ConsumerState<MarketplaceProfileCard> createState() => _MarketplaceProfileCardState();
}

class _MarketplaceProfileCardState extends ConsumerState<MarketplaceProfileCard> {
  String? _selectedCategoryId;
  final _messageController = TextEditingController();
  bool _showMessageField = false;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final data = _deriveViewData();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        color: colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant, 
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH, AppSpacing.sm,
                    AppSpacing.screenPaddingH, AppSpacing.xl),
                children: [
                  _ProfileHeader(
                    listing:       widget.listing,
                    ownerCatLabel: data.ownerCatLabel,
                    showName:      data.showName,
                    showRating:    data.showRating,
                    showTagline:   data.showTagline,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  _CategorySlots(
                    openCategoryItems:   data.openCategoryItems,
                    selectedCategoryId:  _selectedCategoryId,
                    isPendingRequest:    data.pendingRequest != null,
                    onSelectCategory:    (id) => setState(() => _selectedCategoryId = id),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_showMessageField) ...[
                    Text('Message${data.messageRequired ? "" : " (optional)"}',
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Introduce yourself or explain your interest…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _RequestActions(
                    pendingRequest:     data.pendingRequest,
                    selectedCategoryId: _selectedCategoryId,
                    showMessageField:   _showMessageField,
                    isSending:          _sending,
                    partnerTerm:        data.partnerTerm,
                    messageRequired:    data.messageRequired,
                    onMessage:          () => Navigator.of(context).pop(),
                    onShowMessageField: () => setState(() => _showMessageField = true),
                    onConfirm:          () => _sendRequest(data.messageRequired),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Derives every value the presentational sub-widgets below need from
  /// config + the widget's listing/requests — previously ~24 lines
  /// sitting inline at the top of build(). Pulling it out means build()
  /// itself reads as "assemble the sheet from this data", not "compute
  /// a dozen things, then assemble the sheet".
  ({
    String partnerTerm,
    bool showName,
    bool showRating,
    bool showTagline,
    bool messageRequired,
    List<_CategoryItem> openCategoryItems,
    String ownerCatLabel,
    PartnershipRequest? pendingRequest,
  }) _deriveViewData() {
    final config      = ref.watch(configProvider).valueOrNull;
    final categories  = config?.industry.categories ?? [];
    final partnerTerm = config?.industry.terminology.partner ?? 'Partner';
    final mpConfig    = config?.industry.partnershipMarketplace;

    final openCategoryItems = widget.listing.openCategories.map((catId) {
      final label = categories.where((c) => c.id == catId).map((c) => c.label).firstOrNull ?? catId;
      return _CategoryItem(id: catId, label: label);
    }).toList();

    final ownerCatLabel = categories
        .where((c) => c.id == widget.listing.ownerCategoryId)
        .map((c) => c.label)
        .firstOrNull ?? widget.listing.ownerCategoryId;

    final pendingRequest = widget.sentRequests.where(
      (r) => r.receiverOwnerUserId == widget.listing.ownerUserId && r.isPending,
    ).firstOrNull;

    return (
      partnerTerm: partnerTerm,
      showName: mpConfig?.showBusinessName ?? true,
      showRating: mpConfig?.showRating ?? true,
      showTagline: mpConfig?.showTagline ?? true,
      messageRequired: mpConfig?.requestMessageRequired ?? false,
      openCategoryItems: openCategoryItems,
      ownerCatLabel: ownerCatLabel,
      pendingRequest: pendingRequest,
    );
  }

  Future<void> _sendRequest(bool messageRequired) async {
    final theme = Theme.of(context);
    if (_selectedCategoryId == null) return;
    final message = _messageController.text.trim();
    if (messageRequired && message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a message before sending.')),
      );
      return;
    }
    setState(() => _sending = true);
    final result = await ref.read(marketplaceNotifierProvider.notifier).sendRequest(
      listing: widget.listing,
      requestedCategoryId: _selectedCategoryId!,
      message: message.isEmpty ? null : message,
    );
    if (mounted) {
      setState(() => _sending = false);
      if (result != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Request sent!'), backgroundColor: theme.colorScheme.primary),
        );
      }
    }
  }
}


// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.listing,
    required this.ownerCatLabel,
    required this.showName,
    required this.showRating,
    required this.showTagline,
  });
  final MarketplaceListing listing;
  final String ownerCatLabel;
  final bool showName, showRating, showTagline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                listing.businessName.avatarInitials,
                style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showName) Text(listing.businessName,
                      style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(ownerCatLabel,
                      style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                  if (showRating && listing.averageRating != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(children: [
                      Icon(Icons.star, size: 14, color: colorScheme.tertiary),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(listing.averageRating!.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurface)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (showTagline && listing.tagline != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(listing.tagline!,
              style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _CategorySlots extends StatelessWidget {
  const _CategorySlots({
    required this.openCategoryItems,
    required this.selectedCategoryId,
    required this.isPendingRequest,
    required this.onSelectCategory,
  });
  final List<_CategoryItem> openCategoryItems;
  final String? selectedCategoryId;
  final bool isPendingRequest;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Open Partnership Slots',
            style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        if (openCategoryItems.isEmpty)
          Text('No open slots at this time.',
              style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant))
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: openCategoryItems.map((item) => FilterChip(
              label: Text(item.label),
              selected: selectedCategoryId == item.id,
              onSelected: isPendingRequest
                  ? null
                  : (selected) => onSelectCategory(selected ? item.id : null),
            )).toList(),
          ),
      ],
    );
  }
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({
    required this.pendingRequest,
    required this.selectedCategoryId,
    required this.showMessageField,
    required this.isSending,
    required this.partnerTerm,
    required this.messageRequired,
    required this.onMessage,
    required this.onShowMessageField,
    required this.onConfirm,
  });
  final PartnershipRequest? pendingRequest;
  final String? selectedCategoryId;
  final bool showMessageField, isSending, messageRequired;
  final String partnerTerm;
  final VoidCallback onMessage, onShowMessageField, onConfirm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (pendingRequest != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
          ),
          child: Text('Request sent — awaiting response',
              style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.secondary, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onMessage,
          icon: const Icon(Icons.message_outlined),
          label: const Text('Message'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!showMessageField)
          FilledButton.icon(
            onPressed: selectedCategoryId == null ? null : onShowMessageField,
            icon: const Icon(Icons.send_outlined),
            label: Text('Send $partnerTerm Request'),
          )
        else
          FilledButton(
            onPressed: isSending ? null : onConfirm,
            child: isSending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Confirm Request'),
          ),
      ],
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.id, required this.label});
  final String id;
  final String label;
}