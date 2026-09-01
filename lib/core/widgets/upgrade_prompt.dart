// lib/core/widgets/upgrade_prompt.dart
//
// The "Upgrade to Pro" call-to-action widget.
//
// ⚠️ HARDCODED ENGINE RULE — THIS WIDGET IS ALWAYS SHOWN IN THE PARTNER SHELL.
//     It cannot be hidden, disabled, or removed by any config value, owner
//     toggle, or developer decision. This is part of the engine's iron core.
//     See Blueprint Section 5 — Partner Shell Permanent Rules.

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';

class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    required this.onUpgradeTap,
    this.buttonLabel = 'Upgrade to Pro',
    this.subtitle = 'Start Your Own Business — full owner access, your brand',
    this.compact = false,
  });

  final VoidCallback onUpgradeTap;
  final String buttonLabel;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactBanner(
            onUpgradeTap: onUpgradeTap,
            buttonLabel: buttonLabel,
          )
        : _FullCard(
            onUpgradeTap: onUpgradeTap,
            buttonLabel: buttonLabel,
            subtitle: subtitle,
          );
  }
}

/// Full card variant. Prominent, used on the partner dashboard.
class _FullCard extends StatelessWidget {
  const _FullCard({
    required this.onUpgradeTap,
    required this.buttonLabel,
    required this.subtitle,
  });

  final VoidCallback onUpgradeTap;
  final String buttonLabel;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingH,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onUpgradeTap,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.upgradePromptRadius),
        ),
        child: Ink(
          decoration: BoxDecoration(
            // Uses M3 Tertiary Container for high-visibility promotional content
            color: colorScheme.tertiaryContainer,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppSpacing.upgradePromptRadius),
            ),
            border: Border.fromBorderSide(
              BorderSide(color: colorScheme.tertiary.withAlpha(80)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.upgradePromptPaddingH,
              vertical: AppSpacing.upgradePromptPaddingV,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  color: colorScheme.onTertiaryContainer,
                  size: AppSpacing.iconSizeLg,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: AppTextStyles.upgradeTitle.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTextStyles.upgradeSubtitle.copyWith(
                          color: colorScheme.onTertiaryContainer.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: const Key('upgrade_prompt_cta'),
                  onPressed: onUpgradeTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onTertiaryContainer,
                    foregroundColor: colorScheme.tertiaryContainer,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: AppTextStyles.upgradeButtonLabel.copyWith(
                      color: colorScheme.tertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim persistent banner variant. Always visible at the top of partner tabs.
class _CompactBanner extends StatelessWidget {
  const _CompactBanner({
    required this.onUpgradeTap,
    required this.buttonLabel,
  });

  final VoidCallback onUpgradeTap;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ColoredBox(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.star_outline_rounded,
              color: colorScheme.onTertiaryContainer,
              size: AppSpacing.iconSizeSm,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                buttonLabel,
                style: AppTextStyles.upgradeSubtitle.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onUpgradeTap,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onTertiaryContainer,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Get it →',
                style: AppTextStyles.upgradeSubtitle.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}