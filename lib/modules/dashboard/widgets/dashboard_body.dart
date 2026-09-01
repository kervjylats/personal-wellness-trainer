// lib/modules/dashboard/widgets/dashboard_body.dart
//
// Shared dashboard scaffold used by PartnerDashboardScreen and
// StaffDashboardScreen. Both were 98% identical — same RefreshIndicator,
// same ListView structure, same dashLabel heading. Extracted here.
//
// Each dashboard passes its own slot list and buildSlot function,
// keeping all business logic in the screen layer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/engine/providers/dashboard_refresh_bus.dart';

class DashboardBody extends ConsumerWidget {
  const DashboardBody({
    super.key,
    required this.slots,
    required this.dashLabel,
    required this.buildSlot,
  });

  /// The ordered list of slot IDs to render (from the dashboard provider).
  final List<String> slots;

  /// The localised label for this dashboard (from activeJobConfigProvider).
  final String dashLabel;

  /// Maps a slot ID to its widget. Implemented by each dashboard screen.
  final Widget Function(BuildContext context, String slot) buildSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(dashboardRefreshBusProvider.notifier).state++;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(dashLabel, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          for (final slot in slots) buildSlot(context, slot),
        ],
      ),
    );
  }
}
