// lib/modules/reservations/screens/reservation_list_screen.dart
//
// Role-aware slot-based entries list screen.
// Owner: sees all. Staff: sees assigned. Client: sees their own.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/reservation_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/reservations/providers/reservations_notifier.dart';

class ReservationListScreen extends ConsumerWidget {
  const ReservationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(reservationsNotifierProvider);
    final authState         = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('reservations');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: role.isOwner || role.isStaff
          ? FloatingActionButton(
              onPressed: () {},
              tooltip: 'New $moduleLabel',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reservationsNotifierProvider),
        child: reservationsAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $moduleLabel.',
            onRetry: () => ref.invalidate(reservationsNotifierProvider),
          ),
          data: (entries) => entries.isEmpty
              ? AppEmptyState(
                  icon: Icons.event_available_outlined,
                  headline: 'No $moduleLabel',
                  subtext: '$moduleLabel will appear here.',
                )
              : _EntryList(entries: entries, role: role, ref: ref),
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.entries,
    required this.role,
    required this.ref,
  });
  final List<ReservationModel> entries;
  final AppRole                role;
  final WidgetRef              ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<ReservationModel>(
      items: entries,
      itemBuilder: (context, index, entry) =>
          _EntryCard(entry: entry, role: role),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.role});
  final ReservationModel entry;
  final AppRole          role;

  @override
  Widget build(BuildContext context) {
    final start = entry.startTime.toLocal();
    final timeLabel =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(entry.status).withValues(alpha: 0.12),
          child: Icon(
            Icons.event_available_outlined,
            size: 20,
            color: _statusColor(entry.status),
          ),
        ),
        title: Text(
          entry.linkedCatalogItemId ?? entry.id,
          style: AppTextStyles.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          timeLabel,
          style:
              AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Text(
          entry.status.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: _statusColor(entry.status),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default:          return AppColors.warning;
    }
  }
}
