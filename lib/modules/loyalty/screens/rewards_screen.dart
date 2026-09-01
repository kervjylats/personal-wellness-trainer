// lib/modules/loyalty/screens/rewards_screen.dart
// FIX: 3 TextEditingControllers (titleCtrl, descCtrl, costCtrl) were created
// inside _showCreateDialog() closure and never disposed — leaked on every open.
// Extracted to _CreateRewardDialog StatefulWidget that owns and disposes them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/modules/loyalty/providers/rewards_notifier.dart';

class RewardsManageScreen extends ConsumerWidget {
  const RewardsManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Rewards')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _CreateRewardDialog(ref: ref),
        ),
        tooltip: 'New Reward',
        child: const Icon(Icons.add),
      ),
      body: rewardsAsync.when(
        loading: () => const LoadingIndicator(),
        error:   (e, _) => const Center(child: Text('Could not load rewards.')),
        data: (rewards) {
          if (rewards.isEmpty) {
            return const Center(
              child: Text('No rewards yet. Tap + to create one.', style: AppTextStyles.bodyMedium),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final r = rewards[index];
              return Card(
                child: ListTile(
                  title:    Text(r.title, style: AppTextStyles.titleMedium),
                  subtitle: Text('Cost: ${r.pointsCost} points', style: AppTextStyles.caption),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => ref.read(rewardsNotifierProvider.notifier).delete(r.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Dialog — owns and disposes its controllers ────────────────────────────────

class _CreateRewardDialog extends StatefulWidget {
  const _CreateRewardDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateRewardDialog> createState() => _CreateRewardDialogState();
}

class _CreateRewardDialogState extends State<_CreateRewardDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _costCtrl  = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final cost  = int.tryParse(_costCtrl.text) ?? 0;
    if (title.isEmpty || cost <= 0) return;

    setState(() => _submitting = true);
    await widget.ref.read(rewardsNotifierProvider.notifier).create(
      title:       title,
      description: _descCtrl.text.trim(),
      pointsCost:  cost,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New Reward'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title'), autofocus: true),
        const SizedBox(height: 8),
        TextField(controller: _descCtrl,  decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 8),
        TextField(controller: _costCtrl,  decoration: const InputDecoration(labelText: 'Points Cost'),
            keyboardType: TextInputType.number),
      ],
    ),
    actions: [
      TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Create'),
      ),
    ],
  );
}
