// lib/modules/catalog/screens/catalog_list_screen.dart
//
// Role-aware catalog screen.
// Owner: sees all items (active + inactive). Client: sees active only.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/currency_text.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/catalog/providers/catalog_notifier.dart';
class CatalogListScreen extends ConsumerWidget {
  const CatalogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogNotifierProvider);
    final authState    = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('catalog');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: role.isOwner
          ? FloatingActionButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _CreateCatalogItemDialog(
                  moduleLabel: moduleLabel,
                  currencyDefault: jobConfig.payment.currencyDefault,
                ),
              ),
              tooltip: 'Add Item',
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(catalogNotifierProvider),
        child: catalogAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $moduleLabel.',
            onRetry: () => ref.invalidate(catalogNotifierProvider),
          ),
          data: (items) => items.isEmpty
              ? AppEmptyState(
                  icon: Icons.storefront_outlined,
                  headline: '$moduleLabel is empty',
                  subtext:
                      role.isOwner ? 'Tap + to add your first item.' : null,
                )
              : _CatalogList(items: items, role: role, ref: ref),
        ),
      ),
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.items,
    required this.role,
    required this.ref,
  });
  final List<CatalogItemModel> items;
  final AppRole                role;
  final WidgetRef              ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<CatalogItemModel>(
      items: items,
      itemBuilder: (context, index, item) =>
          _CatalogCard(item: item, role: role, ref: ref),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.role,
    required this.ref,
  });
  final CatalogItemModel item;
  final AppRole          role;
  final WidgetRef        ref;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isActive ? 1.0 : 0.5,
      child: Card(
        child: ListTile(
          title: Text(item.title, style: AppTextStyles.bodyLarge),
          subtitle: item.description != null
              ? Text(
                  item.description!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyText(
                amount: item.price,
                currencySymbol: item.currency,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              if (!item.isActive)
                Text(
                  'Inactive',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create item dialog ───────────────────────────────────────────────────────
//
// Replaces the FAB's previous empty onPressed: () {} placeholder. A simple
// dialog (rather than a separate pushed screen) is appropriate here since
// catalog items only need title/description/price — far simpler than
// activities, which have many dynamic, job-specific fields.

class _CreateCatalogItemDialog extends ConsumerStatefulWidget {
  const _CreateCatalogItemDialog({
    required this.moduleLabel,
    required this.currencyDefault,
  });

  final String moduleLabel;
  final String currencyDefault;

  @override
  ConsumerState<_CreateCatalogItemDialog> createState() =>
      _CreateCatalogItemDialogState();
}

class _CreateCatalogItemDialogState
    extends ConsumerState<_CreateCatalogItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final created = await ref.read(catalogNotifierProvider.notifier).create(
          title: _titleController.text.trim(),
          price: price,
          currency: widget.currencyDefault,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (created != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New ${widget.moduleLabel} Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: widget.currencyDefault,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
