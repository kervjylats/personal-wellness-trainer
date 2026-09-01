// lib/modules/dashboard/screens/staff_dashboard_screen.dart
//
// FIX: extracted shared RefreshIndicator+ListView scaffold into DashboardBody.
// Was 98% identical to partner_dashboard_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/dashboard/providers/dashboard_provider.dart';
import 'package:personal_wellness_trainer/modules/dashboard/widgets/dashboard_body.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots     = ref.watch(staffDashboardSlotsProvider);
    final jobConfig = ref.watch(activeJobConfigProvider);

    return DashboardBody(
      slots:     slots,
      dashLabel: jobConfig.terminology.dashboard,
      buildSlot: _buildSlot,
    );
  }

  Widget _buildSlot(BuildContext context, String slot) {
    switch (slot) {
      case 'my_activities':
        return WidgetRegistry.build('activity.StaffActivitiesSlot', context);
      case 'assigned_count':
        return WidgetRegistry.build('activity.StaffCountSlot', context);
      default:
        return const SizedBox.shrink();
    }
  }
}
