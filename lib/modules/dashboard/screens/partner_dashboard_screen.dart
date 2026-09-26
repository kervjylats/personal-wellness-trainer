// lib/modules/dashboard/screens/partner_dashboard_screen.dart
//
// FIX: extracted shared RefreshIndicator+ListView scaffold into DashboardBody.
// Was 98% identical to staff_dashboard_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/widgets/upgrade_prompt.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/dashboard/providers/dashboard_provider.dart';
import 'package:personal_wellness_trainer/modules/dashboard/widgets/dashboard_body.dart';

class PartnerDashboardScreen extends ConsumerWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots     = ref.watch(partnerDashboardSlotsProvider);
    final jobConfig = ref.watch(activeJobConfigProvider);

    return DashboardBody(
      slots:      slots,
      dashLabel:  jobConfig.terminology.dashboard,
      buildSlot:  (ctx, slot) => _buildSlot(ctx, ref, slot, jobConfig),
    );
  }

  Widget _buildSlot(BuildContext context, WidgetRef ref, String slot, dynamic jobConfig) {
    switch (slot) {
      case 'my_earnings':
        return WidgetRegistry.build('finance.PartnerEarningsSlot', context);
      case 'active_deals':
        return WidgetRegistry.build('agreements.PartnerDealsSlot', context);
      case 'upgrade_cta':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: UpgradePrompt(
            compact: false,
            buttonLabel: jobConfig.upgrade.buttonLabel as String,
            onUpgradeTap: () => ref.read(authNotifierProvider.notifier).launchOwnBusiness(),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
