// lib/modules/delivery_fees/screens/delivery_fees_screen.dart
//
// Delivery fee zones management screen.
// Owner: sees and manages all zones. Staff/client: sees active zones.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/currency_text.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/delivery_fee_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/providers/delivery_fees_notifier.dart';

class DeliveryFeesScreen extends ConsumerWidget {
  const DeliveryFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(deliveryFeesNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('delivery_fees');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: role.isOwner
          ? FloatingActionButton(
              onPressed: () {},
              tooltip: 'Add Zone',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(deliveryFeesNotifierProvider),
        child: feesAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load delivery zones.',
            onRetry: () => ref.invalidate(deliveryFeesNotifierProvider),
          ),
          data: (fees) => fees.isEmpty
              ? AppEmptyState(
                  icon: Icons.local_shipping_outlined,
                  headline: 'No $moduleLabel defined',
                  subtext: role.isOwner
                      ? 'Tap + to define your first delivery zone.'
                      : null,
                )
              : _FeeList(fees: fees, role: role, ref: ref),
        ),
      ),
    );
  }
}

class _FeeList extends StatelessWidget {
  const _FeeList({
    required this.fees,
    required this.role,
    required this.ref,
  });
  final List<DeliveryFeeModel> fees;
  final AppRole                role;
  final WidgetRef              ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<DeliveryFeeModel>(
      items: fees,
      itemBuilder: (context, index, fee) =>
          _FeeCard(fee: fee, role: role, ref: ref),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.fee,
    required this.role,
    required this.ref,
  });
  final DeliveryFeeModel fee;
  final AppRole          role;
  final WidgetRef        ref;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: fee.isActive ? 1.0 : 0.5,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.map_outlined,
                color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          title: Text(fee.zoneLabel, style: AppTextStyles.bodyLarge),
          subtitle: Text(
            '${fee.minDistanceKm.toStringAsFixed(1)} – '
            '${fee.maxDistanceKm.toStringAsFixed(1)} km',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
          trailing: CurrencyText(
            amount: fee.fee,
            currencySymbol: fee.currency,
            style: AppTextStyles.bodyLarge
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
