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
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/transaction_notifier.dart';

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
            _InfoRow(label: 'Associate commission', value: AppFormatters.percentage(live.partnerCommissionPct)),
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
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : () => _recordPayment(context),
              child: const Text('Record payment'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy ? null : () => _end(context),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              child: const Text('End Agreement'),
            ),
          ),
        ],
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

  /// Charge → split → (later, Mark paid on the finance screen) — the
  /// owner-side entry point for the mock payment flow. Stays on this
  /// screen on success (unlike _runAction, which pops).
  Future<void> _recordPayment(BuildContext context) async {
    final jobConfig = ref.read(activeJobConfigProvider);
    // Captured before the first await so the snackbar never touches a
    // context across an async gap (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);
    final form = await showDialog<_PaymentForm>(
      context: context,
      builder: (_) => _RecordPaymentDialog(
        currency: jobConfig.payment.currencyDefault,
      ),
    );
    if (form == null || !mounted) return;

    setState(() => _busy = true);
    final ok =
        await ref.read(transactionNotifierProvider.notifier).recordAgreementPayment(
              agreement: widget.agreement,
              amount: form.amount,
              currencySymbol: jobConfig.payment.currencyDefault,
              description: form.description,
              payerLabel: form.payer,
              method: form.method,
            );
    if (!mounted) return;
    setState(() => _busy = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Payment recorded — the split is now on both ledgers.'
            : 'Could not record the payment. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
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

// ── Record payment dialog ─────────────────────────────────────────────────────

class _PaymentForm {
  const _PaymentForm({
    required this.amount,
    required this.description,
    required this.payer,
    required this.method,
  });
  final double amount;
  final String description;
  final String payer;
  final String method; // 'card' | 'bank' | 'cash'
}

class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({required this.currency});
  final String currency;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController(text: 'Session payment');
  final _payer = TextEditingController(text: 'Client');
  String _method = 'card';
  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _payer.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter an amount greater than 0');
      return;
    }
    Navigator.of(context).pop(_PaymentForm(
      amount: amount,
      description: _description.text.trim().isEmpty
          ? 'Payment'
          : _description.text.trim(),
      payer: _payer.text.trim().isEmpty ? 'Client' : _payer.text.trim(),
      method: _method,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g. 120.00',
                prefixText: '${widget.currency} ',
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _payer,
              decoration: const InputDecoration(labelText: 'Payer name'),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Payment method',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey600)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: const Text('Card •••• 4242'),
                  selected: _method == 'card',
                  onSelected: (_) => setState(() => _method = 'card'),
                ),
                ChoiceChip(
                  label: const Text('Bank transfer'),
                  selected: _method == 'bank',
                  onSelected: (_) => setState(() => _method = 'bank'),
                ),
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _method == 'cash',
                  onSelected: (_) => setState(() => _method = 'cash'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
