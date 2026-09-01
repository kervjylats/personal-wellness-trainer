// lib/modules/agreements/screens/agreement_detail_screen.dart
// FIX: added `if (!mounted) return;` after `await showDialog` in _end().
// Without it, setState() throws if the widget is disposed while the dialog is open.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';

class AgreementDetailScreen extends ConsumerWidget {
  const AgreementDetailScreen({super.key, required this.agreement});
  final AgreementModel agreement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref
            .watch(agreementsNotifierProvider)
            .valueOrNull
            ?.firstWhere((a) => a.id == agreement.id, orElse: () => agreement) ??
        agreement;

    return Scaffold(
      appBar: AppBar(title: const Text('Agreement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            _StatusBanner(status: live.status),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(title: 'Details'),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: 'Category', value: live.categoryId),
            _InfoRow(label: 'Your commission',     value: AppFormatters.percentage(live.ownerCommissionPct)),
            _InfoRow(label: 'Partner commission',  value: AppFormatters.percentage(live.partnerCommissionPct)),
            _InfoRow(label: 'Proposed',            value: AppFormatters.date(live.proposedAt)),
            if (live.respondedAt != null)
              _InfoRow(label: 'Responded', value: AppFormatters.date(live.respondedAt!)),
            if (live.endedAt != null)
              _InfoRow(label: 'Ended', value: AppFormatters.date(live.endedAt!)),
            if (live.notes != null && live.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const _SectionHeader(title: 'Notes'),
              const SizedBox(height: AppSpacing.xs),
              Text(live.notes!, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xl),
            _AgreementActions(agreement: live),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _AgreementActions extends ConsumerStatefulWidget {
  const _AgreementActions({required this.agreement});
  final AgreementModel agreement;
  @override
  ConsumerState<_AgreementActions> createState() => _AgreementActionsState();
}

class _AgreementActionsState extends ConsumerState<_AgreementActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.agreement;
    if (a.status == 'proposed') {
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : () => _decline(context),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: _busy ? null : () => _approve(context),
            child: const Text('Approve'),
          ),
        ),
      ]);
    }
    if (a.status == 'active') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _busy ? null : () => _end(context),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          child: const Text('End Agreement'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _approve(BuildContext context) => _runAction(
        context,
        () => ref
            .read(agreementsNotifierProvider.notifier)
            .approveAgreement(widget.agreement.id),
      );

  Future<void> _decline(BuildContext context) => _runAction(
        context,
        () => ref
            .read(agreementsNotifierProvider.notifier)
            .declineAgreement(widget.agreement.id),
      );

  Future<void> _end(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Agreement'),
        content: const Text('Are you sure? This will unlock the category slot for both parties.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    // FIX: was missing. setState on a disposed State throws a FlutterError.
    if (!mounted || !context.mounted) return;
    if (confirmed != true) return;
    await _runAction(
      context,
      () => ref
          .read(agreementsNotifierProvider.notifier)
          .endAgreement(widget.agreement.id),
    );
  }

  /// Runs a status-changing notifier call with the shared busy-state /
  /// mounted-check sequence. Every action here (approve/decline/end) used
  /// to repeat this by hand — and a mounted check was once missing from
  /// one copy (see the FIX comment above) before someone caught it.
  /// Consolidating means that class of bug can only be fixed, or
  /// reintroduced, in one place.
  Future<void> _runAction(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && context.mounted) Navigator.of(context).pop();
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _color().withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color().withAlpha(80)),
      ),
      child: Row(children: [
        Icon(_icon(), color: _color()),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.titleSmall.copyWith(color: _color())),
      ]),
    );
  }

  Color    _color() => switch (status) { 'active' => AppColors.success, 'proposed' => AppColors.warning, 'declined' => AppColors.error, _ => AppColors.grey600 };
  IconData _icon()  => switch (status) { 'active' => Icons.check_circle_outline, 'proposed' => Icons.pending_outlined, 'declined' => Icons.cancel_outlined, _ => Icons.info_outline };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: AppTextStyles.titleSmall);
}
