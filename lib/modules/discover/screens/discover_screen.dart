import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/currency_text.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/providers/chat_launcher_provider.dart';
import 'package:personal_wellness_trainer/modules/discover/providers/partner_offers_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/invite_dialog.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final partnerOffersAsync = ref.watch(partnerOffersProvider);
    final teamAsync = ref.watch(teamNotifierProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnerOffersProvider);
          ref.invalidate(teamNotifierProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
          children: [
            const SizedBox(height: AppSpacing.md),

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
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // ── Network ──────────────────────────────────────────────────────
            const Text('Network', style: AppTextStyles.headlineSmall),
            teamAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text('Could not load contacts.', style: AppTextStyles.bodyMedium),
              ),
              data: (members) {
                final owners = members.where((m) => m.role == 'owner').toList();
                final partners = members.where((m) => m.role == 'partner').toList();
                // Staff only visible if owner enabled 'client_can_message' for that staff
                final visibleStaff = members
                    .where((m) =>
                        m.role == 'staff' &&
                        m.featureToggles['client_can_message'] == true)
                    .toList();

                if (owners.isEmpty && partners.isEmpty && visibleStaff.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text('No contacts yet.', style: AppTextStyles.bodyMedium),
                  );
                }

                return Column(
                  children: [
                    if (owners.isNotEmpty) ...[
                      _SectionLabel(label: 'Owner', count: owners.length),
                      ...owners.map((m) => _ContactTile(member: m)),
                    ],
                    if (partners.isNotEmpty) ...[
                      _SectionLabel(label: 'Partners', count: partners.length),
                      ...partners.map((m) => _ContactTile(member: m)),
                    ],
                    if (visibleStaff.isNotEmpty) ...[
                      _SectionLabel(label: 'Staff', count: visibleStaff.length),
                      ...visibleStaff.map((m) => _ContactTile(member: m)),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const InviteDialog(role: 'client'),
        ),
        tooltip: 'Invite a friend',
        child: const Icon(Icons.person_add_outlined),
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
// ── Network: section label ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        '$label ($count)',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Network: contact tile ─────────────────────────────────────────────────────

class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.member});
  final TeamMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = member.displayName.avatarInitials;

    final roleColor = switch (member.role) {
      'owner'   => Theme.of(context).colorScheme.primary,
      'partner' => AppColors.rolePartner,
      'staff'   => AppColors.roleStaff,
      _         => AppColors.grey400,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: AppTextStyles.titleSmall.copyWith(color: roleColor),
          ),
        ),
        title: Text(member.displayName, style: AppTextStyles.bodyMedium),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _roleLabel(member.role),
                style: AppTextStyles.caption.copyWith(color: roleColor),
              ),
            ),
            if (member.email != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  member.email!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 20),
          color: Theme.of(context).colorScheme.primary,
          tooltip: 'Message ${member.displayName}',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => unawaited(_openDm(context, ref)),
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'owner'   => 'Owner',
        'partner' => 'Partner',
        'staff'   => 'Staff',
        _         => role,
      };

  Future<void> _openDm(BuildContext context, WidgetRef ref) async {
    final conv = await ref.read(chatLauncherProvider).openDirect(
          participantId: member.userId,
          participantName: member.displayName,
        );
    if (conv == null || !context.mounted) return;
    // Chat thread navigation via GoRouter is wired in Phase 10.
    // Conversation record is created here so unread count already tracks.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation with ${member.displayName} started.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
