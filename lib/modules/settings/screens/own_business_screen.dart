// lib/modules/settings/screens/own_business_screen.dart
//
// "Start your own business" contact page. P7-10.
// Shown from staff and client Settings — HARDCODED RULE for staff.
// Also accessible from client settings as a subtle link.
// Uses BuyerConfig for contact details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/config/buyer_config.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';

class OwnBusinessScreen extends ConsumerWidget {
  const OwnBusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName =
        ref.watch(configProvider).valueOrNull?.industry.appName ?? 'App Engine';

    return Scaffold(
      appBar: AppBar(title: const Text('Start Your Own Business')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Icon(
            Icons.rocket_launch_outlined,
            size: AppSpacing.iconSizeXxl,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Thinking of starting your own business?',
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Get your own app just like $appName. '
            'Reach out to us and we will help you get started.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _ContactTile(
            icon: Icons.email_outlined,
            title: 'Email us',
            value: BuyerConfig.supportEmail,
          ),
          const _ContactTile(
            icon: Icons.language_outlined,
            title: 'Visit our website',
            value: BuyerConfig.supportWebsite,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _OwnBusinessHint(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _OwnBusinessHint extends StatelessWidget {
  const _OwnBusinessHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Text(
        'Update BuyerConfig.supportEmail and BuyerConfig.supportWebsite '
        'in lib/config/buyer_config.dart with your real contact details.',
        style: AppTextStyles.caption,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: AppTextStyles.titleMedium),
      subtitle: Text(value, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.open_in_new,
          color: AppColors.grey400, size: AppSpacing.iconSize),
      onTap: () {},
    );
  }
}
