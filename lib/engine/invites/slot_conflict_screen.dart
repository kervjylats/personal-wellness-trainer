// lib/engine/invites/slot_conflict_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';

class SlotConflictScreen extends ConsumerStatefulWidget {
  const SlotConflictScreen({
    super.key,
    required this.categoryId,
    required this.businessId,
  });

  final String categoryId;
  final String businessId;

  @override
  ConsumerState<SlotConflictScreen> createState() => _SlotConflictScreenState();
}

class _SlotConflictScreenState extends ConsumerState<SlotConflictScreen> {
  bool _generatingClientLink = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];
    final categoryLabel = categories
        .where((c) => c.id == widget.categoryId)
        .map((c) => c.label)
        .firstOrNull ?? widget.categoryId;

    final upgradeLabel = config?.industry.upgrade.buttonLabel ?? 'Upgrade to Pro';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Category Unavailable'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.screenPaddingV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConflictHeader(categoryLabel: categoryLabel),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.xl),
              _OptionCard(
                icon: Icons.rocket_launch_outlined,
                iconColor: colorScheme.primary,
                title: upgradeLabel,
                subtitle:
                    'Launch your own platform. Invite unlimited partners '
                    'in any category — including $categoryLabel.',
                child: PrimaryButton(
                  label: upgradeLabel,
                  onPressed: () {}, 
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _OptionCard(
                icon: Icons.person_add_outlined,
                iconColor: colorScheme.secondary,
                title: 'Invite as client instead',
                subtitle:
                    'They join this platform as a client and can use '
                    'services here, but not operate as a partner.',
                child: PrimaryButton(
                  label: 'Generate Client Invite Link',
                  isLoading: _generatingClientLink,
                  onPressed: _generatingClientLink
                      ? null
                      : () => _generateClientLink(),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateClientLink() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    setState(() => _generatingClientLink = true);

    final result = await ref.read(inviteLinkNotifierProvider.notifier).generateLink(
          targetRole: 'client',
          label: 'Client invite (slot conflict redirect)',
        );

    if (!mounted) return;
    setState(() => _generatingClientLink = false);

    if (result is InviteLinkCreated) {
      _showLinkSheet(result.link.token);
    } else if (result is InviteLinkError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  void _showLinkSheet(String token) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const mockUrl = 'https://YOUR_DOMAIN_HERE/join?token=\$token';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Client Invite Link', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              ),
              child: Text(
                mockUrl,
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Share this link with the person you want to invite. '
              'They can join as a client on this platform.',
              style: AppTextStyles.labelSmall
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Done',
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}


// ── Conflict header ───────────────────────────────────────────────────────────

class _ConflictHeader extends StatelessWidget {
  const _ConflictHeader({required this.categoryLabel});
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(Icons.lock_outline, size: AppSpacing.iconSizeXxl, color: colorScheme.error),
        const SizedBox(height: AppSpacing.md),
        Text(
          '$categoryLabel slot is taken',
          style: AppTextStyles.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'This platform already has a partner in the $categoryLabel '
          'category. Only one partner per category is allowed per platform.',
          style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: AppSpacing.iconSize),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: AppTextStyles.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}