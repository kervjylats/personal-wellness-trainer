import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';

/// Standard separated list used across module list screens (catalog,
/// inventory, reviews, scheduling, delivery fees, reservations, media, …).
///
/// Every one of these screens previously re-declared the same
/// `ListView.separated` with the same padding and gap — this just gives
/// them one shared place to do it.
class AppCardListView<T> extends StatelessWidget {
  const AppCardListView({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) =>
          itemBuilder(context, index, items[index]),
    );
  }
}
