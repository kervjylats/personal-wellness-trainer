// lib/modules/progress/screens/progress_screen.dart
// FIX: 4 TextEditingControllers (photoCtrl, weightCtrl, fatCtrl, notesCtrl)
// were created inside _showAddDialog() closure and never disposed.
// Extracted to _AddProgressDialog StatefulWidget that owns and disposes them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/progress_entry_model.dart';
import 'package:personal_wellness_trainer/modules/progress/providers/progress_notifier.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(progressNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _AddProgressDialog(ref: ref),
        ),
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        loading: () => const LoadingIndicator(),
        error:   (e, _) => const Center(
          child: Text('Could not load progress.', style: AppTextStyles.bodyMedium),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('No entries yet. Tap + to add your first!', style: AppTextStyles.bodyMedium),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: entries.length,
            itemBuilder: (context, index) => _ProgressCard(entry: entries[index]),
          );
        },
      ),
    );
  }
}

// ── Dialog — owns and disposes its controllers ────────────────────────────────

class _AddProgressDialog extends StatefulWidget {
  const _AddProgressDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddProgressDialog> createState() => _AddProgressDialogState();
}

class _AddProgressDialogState extends State<_AddProgressDialog> {
  final _photoCtrl  = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fatCtrl    = TextEditingController();
  final _notesCtrl  = TextEditingController();
  bool _submitting  = false;

  @override
  void dispose() {
    _photoCtrl.dispose();
    _weightCtrl.dispose();
    _fatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final photos  = _photoCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final metrics = <String, double>{};
    final w = double.tryParse(_weightCtrl.text);
    final f = double.tryParse(_fatCtrl.text);
    if (w != null) metrics['weight']   = w;
    if (f != null) metrics['body_fat'] = f;
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    await widget.ref.read(progressNotifierProvider.notifier).addEntry(
      photoUrls: photos,
      metrics:   metrics,
      notes:     notes,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Log Progress'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _photoCtrl,
              decoration: const InputDecoration(labelText: 'Photo URLs (comma separated)')),
          const SizedBox(height: 8),
          TextField(controller: _weightCtrl,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: _fatCtrl,
              decoration: const InputDecoration(labelText: 'Body Fat %'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes')),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Save'),
      ),
    ],
  );
}

// ── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.entry});
  final ProgressEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final dateStr = '${entry.date.day}/${entry.date.month}/${entry.date.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.grey600),
              const SizedBox(width: AppSpacing.xs),
              Text(dateStr, style: AppTextStyles.labelLarge),
              const Spacer(),
              if (entry.notes != null)
                Flexible(child: Text(entry.notes!, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
            ]),
            if (entry.metrics.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: entry.metrics.entries.map((e) => Chip(
                  label: Text('${e.key}: ${e.value}', style: AppTextStyles.labelSmall),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(20),
                )).toList(),
              ),
            ],
            if (entry.photoUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('${entry.photoUrls.length} photo(s)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey600)),
            ],
          ],
        ),
      ),
    );
  }
}
