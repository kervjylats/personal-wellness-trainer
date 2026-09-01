// lib/modules/scheduling/screens/schedule_screen.dart
//
// Role-aware schedule screen.
// Owner: sees all slots. Staff: their own slots. Client: available slots only.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider so the
// AppBar title shows the job-specific term (e.g. "Schedule" for yoga/pilates).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/schedule_slot_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/scheduling/providers/scheduling_notifier.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(schedulingNotifierProvider);
    final authState  = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('scheduling');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: role.isOwner || role.isStaff
          ? FloatingActionButton(
              onPressed: () {},
              tooltip: 'Add Slot',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(schedulingNotifierProvider),
        child: slotsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $moduleLabel.',
            onRetry: () => ref.invalidate(schedulingNotifierProvider),
          ),
          data: (slots) => slots.isEmpty
              ? AppEmptyState(
                  icon: Icons.calendar_today_outlined,
                  headline: 'No slots in $moduleLabel',
                  subtext: 'Slots will appear here once added.',
                )
              : _SlotList(slots: slots, role: role, ref: ref),
        ),
      ),
    );
  }
}

class _SlotList extends StatelessWidget {
  const _SlotList({
    required this.slots,
    required this.role,
    required this.ref,
  });
  final List<ScheduleSlotModel> slots;
  final AppRole                 role;
  final WidgetRef               ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<ScheduleSlotModel>(
      items: slots,
      itemBuilder: (context, index, slot) =>
          _SlotCard(slot: slot, role: role, ref: ref),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.role,
    required this.ref,
  });
  final ScheduleSlotModel slot;
  final AppRole           role;
  final WidgetRef         ref;

  @override
  Widget build(BuildContext context) {
    final start = slot.startTime.toLocal();
    final end   = slot.endTime.toLocal();
    final timeLabel =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
        ' – '
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: slot.isAvailable
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.textSecondary.withValues(alpha: 0.15),
          child: Icon(
            slot.isAvailable ? Icons.check : Icons.block,
            color: slot.isAvailable
                ? AppColors.success
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(timeLabel, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          slot.isAvailable ? 'Available' : 'Unavailable',
          style: AppTextStyles.labelSmall.copyWith(
            color: slot.isAvailable
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        ),
        trailing: (role.isOwner || role.isStaff)
            ? Switch(
                value: slot.isAvailable,
                onChanged: (val) async {
                  await ref
                      .read(schedulingNotifierProvider.notifier)
                      .setAvailability(slot.id, isAvailable: val);
                },
              )
            : null,
      ),
    );
  }
}
