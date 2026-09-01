// lib/modules/dashboard/screens/client_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';
import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/dashboard/providers/dashboard_provider.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_notifier.dart';
import 'package:personal_wellness_trainer/modules/invites/screens/qr_invite_dialog.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots     = ref.watch(clientDashboardSlotsProvider);
    final jobConfig = ref.watch(activeJobConfigProvider);
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dashLabel = jobConfig.terminology.dashboard;
    final name = authState is AuthAuthenticated ? authState.profile.displayName : '';

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(dashboardRefreshBusProvider.notifier).state++;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(name.isNotEmpty ? 'Hello, $name' : dashLabel, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.md),

          // ── ZONE 1: PRIMARY HOST (OWNER) CARD 👑 ───────────────────────────
          Card(
            color: colorScheme.primaryContainer,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Your Primary Coach',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    jobConfig.appName,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your dedicated space for total wellness.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.onPrimaryContainer.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── VIRAL CLIENT-TO-CLIENT REFERRAL CARD 🎟️ ───────────────────────
          Card(
            color: colorScheme.secondaryContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: BorderSide(color: colorScheme.secondary.withAlpha(50)),
            ),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: colorScheme.onSecondaryContainer),
              title: Text('Invite your Friends!', style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
              subtitle: Text('Invite a friend to join ${jobConfig.appName}. When they sign up, they join under your coach!', style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSecondaryContainer.withAlpha(200))),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => _inviteFriend(context, ref),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── AUXILIARY FEATURE SHORTCUTS GRID 🧭 ─────────────────────────────
          Text('Activity & Features', style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.2,
            children: [
              _FeatureTile(
                label: 'Challenges',
                icon: Icons.emoji_events_outlined,
                color: colorScheme.primary,
                onTap: () => context.goNamed(RouteNames.clientChallenges),
              ),
              _FeatureTile(
                label: 'Homework',
                icon: Icons.assignment_outlined,
                color: colorScheme.secondary,
                onTap: () => context.goNamed(RouteNames.clientNotifications), // Maps to client tasks
              ),
              _FeatureTile(
                label: 'Progress',
                icon: Icons.trending_up_outlined,
                color: colorScheme.tertiary,
                onTap: () => context.goNamed(RouteNames.clientProfile), 
              ),
              _FeatureTile(
                label: 'Loyalty Points',
                icon: Icons.stars_outlined,
                color: colorScheme.error,
                // clientNotifications may not be scoped to client shell;
                // use clientProfile as a safe placeholder.
                onTap: () => context.goNamed(RouteNames.clientProfile),
              ),
              _FeatureTile(
                label: 'Media',
                icon: Icons.perm_media_outlined,
                color: colorScheme.secondary,
                onTap: () => context.goNamed(RouteNames.clientProfile),
              ),
              _FeatureTile(
                label: 'Reviews',
                icon: Icons.rate_review_outlined,
                color: colorScheme.primary,
                // Phase 10: replace with clientReviews when route exists.
                onTap: () => context.goNamed(RouteNames.clientProfile),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Standard dashboard slots (Next Session, Balance, etc.)
          for (final slot in slots) _buildSlot(context, slot),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, String slot) {
    switch (slot) {
      case 'next_activity':
        return WidgetRegistry.build('activity.ClientNextSlot', context);
      case 'my_balance':
        return WidgetRegistry.build('finance.ClientBalanceSlot', context);
      case 'content_preview':
        return WidgetRegistry.build('media.ContentPreviewSlot', context);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _inviteFriend(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(inviteLinkNotifierProvider.notifier).generateLink(targetRole: 'client');
    if (!context.mounted) return;
    if (result is InviteLinkCreated) {
      _showTokenSheet(context, result.link.token);
    }
  }

  void _showTokenSheet(BuildContext context, String token) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mockUrl = 'https://wellpath.app/join?token=$token';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Invite a Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            const Text('Share this link. When they join, they earn you loyalty points and become a client of your coach!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(mockUrl, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showDialog<void>(
                        context: context,
                        builder: (_) => QrInviteDialog(inviteUrl: mockUrl),
                      );
                    },
                    child: const Text('View QR Code'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}