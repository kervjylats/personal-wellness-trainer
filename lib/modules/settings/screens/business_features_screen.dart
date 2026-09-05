// lib/modules/settings/screens/business_features_screen.dart
//
// Owner-only. Lets the business owner turn the Partnership system on/off
// in three independent layers:
//   1. Partners at all — can this business have Partners, invited or
//      otherwise? Off = simplest possible shell (Owner + Staff + Clients).
//   2. Marketplace — can Partners (once Pro) discover and partner with
//      OTHER independent businesses? Only matters if (1) is on.
//   3. Agreements/Deals — can commission splits be proposed at all?
//      Only matters if (1) is on.
//
// Turning (1) off disables (2) and (3) automatically in the UI (they're
// meaningless without Partners), but their stored values aren't touched —
// flipping Partners back on restores whatever Marketplace/Agreements were
// set to before, rather than forcing the Owner to redo everything.
//
// See businessFeaturesProvider for how every other screen reads these
// flags, and AuthNotifier.updateBusinessFeatures for how a change here
// gets persisted and pushed out to the rest of the business's team roster.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/providers/business_features_provider.dart';

class BusinessFeaturesScreen extends ConsumerWidget {
  const BusinessFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(businessFeaturesProvider);
    final notifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Features')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Turn parts of the Partnership system on or off for this '
            'business. Changes apply immediately for everyone.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _FeatureSwitchTile(
            icon: Icons.handshake_outlined,
            title: 'Partners',
            subtitle: 'Allow this business to invite and work with Partners '
                'at all. Turning this off hides the Partners tab entirely — '
                'Owner, Staff, and Clients still work as normal.',
            value: features.partnersEnabled,
            onChanged: (v) => notifier.updateBusinessFeatures(
              partnersEnabled: v,
            ),
          ),
          const Divider(height: AppSpacing.xl),
          _FeatureSwitchTile(
            icon: Icons.travel_explore_outlined,
            title: 'Marketplace (Discoverable Partnerships)',
            subtitle: 'Let Pro Partners discover and partner with other '
                'independent businesses on the platform, separate from '
                'partners this business invited directly.',
            value: features.partnersEnabled && features.marketplaceEnabled,
            onChanged: features.partnersEnabled
                ? (v) => notifier.updateBusinessFeatures(
                      marketplaceEnabled: v,
                    )
                : null,
          ),
          const Divider(height: AppSpacing.xl),
          _FeatureSwitchTile(
            icon: Icons.receipt_long_outlined,
            title: 'Agreements & Deals',
            subtitle: 'Allow commission-split deals to be proposed between '
                'this Owner and their Partners.',
            value: features.partnersEnabled && features.agreementsEnabled,
            onChanged: features.partnersEnabled
                ? (v) => notifier.updateBusinessFeatures(
                      agreementsEnabled: v,
                    )
                : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _FeatureSwitchTile extends StatelessWidget {
  const _FeatureSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onChanged == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isDisabled
              ? colorScheme.onSurfaceVariant.withAlpha(120)
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDisabled
                      ? colorScheme.onSurfaceVariant.withAlpha(120)
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
