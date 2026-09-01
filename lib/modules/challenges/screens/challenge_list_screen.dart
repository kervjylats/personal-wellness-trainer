// lib/modules/challenges/screens/challenge_list_screen.dart
//
// FIX — TextEditingController memory leaks in _showCreateDialog:
//
//   The original code created three TextEditingControllers (titleCtrl,
//   descCtrl, daysCtrl) inside a plain function closure. Because they were
//   never disposed, every time the dialog opened it leaked three controllers
//   into the heap permanently. The only way to collect them would be to hot-
//   restart the app.
//
//   Fix: extracted the dialog content into a private StatefulWidget
//   (_CreateChallengeDialog) that owns and disposes the controllers correctly
//   in its dispose() method. The public API is unchanged — _showCreateDialog
//   still calls showDialog, it just passes the new widget as the builder.
//
//   Secondary fix: the original `if (ctx.mounted) nav.pop()` was correct but
//   redundant — the dialog's own BuildContext (ctx) is always mounted when the
//   FilledButton callback fires synchronously after the await. The nav variable
//   pattern is kept for clarity.

import 'package:personal_wellness_trainer/engine/config/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/challenges/providers/challenges_notifier.dart';

class ChallengeListScreen extends ConsumerWidget {
  const ChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);
    final flags = flagsAsync.valueOrNull;

    final role = authState is AuthAuthenticated
        ? AppRole.fromString(authState.profile.role)
        : AppRole.client;
    final canCreate = role.isOwner ||
        (role.isPartner && (flags?.challengesPartnerCanCreate ?? false));

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context, ref),
              tooltip: 'New Challenge',
              child: const Icon(Icons.add),
            )
          : null,
      body: challengesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Text(
            'Could not load challenges.\n$e',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (challenges) {
          if (challenges.isEmpty) {
            return const Center(
              child: Text('No challenges yet.', style: AppTextStyles.bodyMedium),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final c = challenges[index];
              return Card(
                child: ListTile(
                  title: Text(c.title, style: AppTextStyles.titleMedium),
                  subtitle: Text(
                    '${c.durationDays} days • ${c.description}',
                    style: AppTextStyles.caption,
                  ),
                  onTap: () => context.pushNamed(
                    'challenge-detail',
                    extra: c,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      // FIX: replaced the inline builder (which created 3 unDisposed
      // TextEditingControllers on every open) with a StatefulWidget that
      // owns and disposes the controllers correctly.
      builder: (ctx) => _CreateChallengeDialog(ref: ref),
    );
  }
}

// ── Dialog widget — owns and disposes its own controllers ─────────────────────

class _CreateChallengeDialog extends StatefulWidget {
  const _CreateChallengeDialog({required this.ref});

  /// The WidgetRef from the parent ConsumerWidget. Safe to pass down because
  /// Riverpod's Ref outlives any individual widget rebuild.
  final WidgetRef ref;

  @override
  State<_CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<_CreateChallengeDialog> {
  // FIX: controllers are now owned by a State and disposed in dispose().
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _daysCtrl  = TextEditingController(text: '7');

  bool _isSubmitting = false;

  @override
  void dispose() {
    // This is the critical fix — these three were never called in the original.
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc  = _descCtrl.text.trim();
    final days  = int.tryParse(_daysCtrl.text) ?? 7;

    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);

    await widget.ref
        .read(challengesNotifierProvider.notifier)
        .create(
          title: title,
          description: desc,
          durationDays: days,
        );

    // Guard: widget may have been disposed if the user popped the dialog
    // during the async call (unlikely here but correct practice).
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Challenge'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _daysCtrl,
            decoration: const InputDecoration(labelText: 'Duration (days)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
