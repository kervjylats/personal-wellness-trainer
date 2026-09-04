// lib/modules/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/upgrade_prompt.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);
    final config = ref.watch(configProvider).valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Text('Settings', style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.xxl),

          // ── UPGRADE PROMPT (Partners only — Owners already have full access) ─
          if (role.isPartner) ...[
            if (config != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: UpgradePrompt(
                  compact: false,
                  buttonLabel: config.industry.upgrade.buttonLabel,
                  subtitle: config.industry.upgrade.subtitle,
                  onUpgradeTap: () => _showMockCheckoutDialog(context, ref, config),
                ),
              ),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Account Section ────────────────────────────────────────────────
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Edit your name and contact details',
            onTap: () => context.goNamed(_profileRouteName(role)),
          ),

          // ── Branding Section (always unlocked for owners) ────────────────────
          if (role.isOwner) ...[
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Branding & Design',
              subtitle: 'Customize brand colors and app terminology',
              onTap: () => context.goNamed(RouteNames.ownerBranding),
              isLocked: false,
            ),
          ],

          // ── Staff own business banner ──────────────────────────────────────
          if (role.isStaff) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _OwnBusinessBanner(
              onTap: () => context.goNamed(RouteNames.ownBusiness),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Client dynamic settings ────────────────────────────────────────
          if (role.isConsumerOnly) ...[
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'Get your own app',
              subtitle: 'Learn about starting your own platform',
              onTap: () => context.goNamed(RouteNames.ownBusiness),
            ),
          ],

          _SettingsTile(
            icon: Icons.support_outlined,
            title: 'Help & Support',
            subtitle: config?.industry.appName,
            onTap: () {},
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // ── Sign Out ──────────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            isDestructive: true,
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  String _profileRouteName(AppRole role) {
    if (role.isOwner) return RouteNames.ownerProfile;
    if (role.isPartner) return RouteNames.partnerProfile;
    if (role.isStaff) return RouteNames.staffProfile;
    return RouteNames.clientProfile;
  }

  void _showMockCheckoutDialog(BuildContext context, WidgetRef ref, dynamic config) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upgradeLabel = config.industry.upgrade.buttonLabel as String;

    showDialog<void>(
      context: context,
      builder: (ctx) => _MockCheckoutDialog(
        ref: ref,
        upgradeLabel: upgradeLabel,
        primaryColor: colorScheme.primary,
        onSuccess: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Subscription Active! Premium features unlocked.'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        },
      ),
    );
  }
}

// ── CONSOLIDATED DIALOG ──────────────────────────────────────────────────────

class _MockCheckoutDialog extends StatefulWidget {
  const _MockCheckoutDialog({
    required this.ref,
    required this.upgradeLabel,
    required this.primaryColor,
    required this.onSuccess,
  });

  final WidgetRef ref;
  final String upgradeLabel;
  final Color primaryColor;
  final VoidCallback onSuccess;

  @override
  State<_MockCheckoutDialog> createState() => _MockCheckoutDialogState();
}

class _MockCheckoutDialogState extends State<_MockCheckoutDialog> {
  bool _isUpgrading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.credit_card_rounded, color: widget.primaryColor),
          const SizedBox(width: AppSpacing.sm),
          const Text('Mock Billing Portal'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.upgradeLabel,
            style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This simulates an external subscription purchase (Stripe/LemonSqueezy checkout URL).',
            style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpgrading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUpgrading
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  setState(() => _isUpgrading = true);
                  
                  await widget.ref.read(authNotifierProvider.notifier).upgradeToPremium();
                  
                  if (mounted) {
                    navigator.pop();
                    widget.onSuccess();
                  }
                },
          child: _isUpgrading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simulate \$49/mo Payment'),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTextStyles.titleSmall.copyWith(color: theme.colorScheme.onSurface)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.isLocked = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final Color color = isDestructive 
        ? colorScheme.error 
        : isLocked 
            ? colorScheme.onSurfaceVariant.withAlpha(120) 
            : colorScheme.onSurface;

    return ProfileTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      color: color,
      isLocked: isLocked,
    );
  }
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    required this.isLocked,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(color: color),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant))
          : null,
      trailing: Icon(
        isLocked ? Icons.lock_outline_rounded : Icons.chevron_right,
        color: colorScheme.onSurfaceVariant.withAlpha(120),
        size: AppSpacing.iconSize,
      ),
      onTap: onTap,
    );
  }
}

class _OwnBusinessBanner extends StatelessWidget {
  const _OwnBusinessBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thinking of starting your own business?',
                    style: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Contact us to learn how to get your own platform.',
                    style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}