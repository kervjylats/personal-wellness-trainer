// lib/modules/homework/screens/homework_list_screen.dart
import 'package:personal_wellness_trainer/engine/config/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/core/widgets/primary_button.dart';
import 'package:personal_wellness_trainer/data/models/homework_model.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/homework/providers/homework_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';

class HomeworkListScreen extends ConsumerWidget {
  const HomeworkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);
    final flags = flagsAsync.valueOrNull;

    final role = authState is AuthAuthenticated
        ? AppRole.fromString(authState.profile.role)
        : AppRole.client;
    final canAssign = role.isOwner || (role.isPartner && (flags?.homeworkPartnerCanAssign ?? false));

    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      floatingActionButton: canAssign
          ? FloatingActionButton(
              onPressed: () => _showAssignDialog(context, ref),
              tooltip: 'Assign Homework',
              child: const Icon(Icons.add),
            )
          : null,
      body: role == AppRole.client
          ? _ClientHomeworkView()
          : const _CoachHomeworkView(),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authNotifierProvider);
    final myUserId = auth is AuthAuthenticated ? auth.profile.userId : '';
    final isOwner = auth is AuthAuthenticated && auth.profile.role == 'owner';
    final teamAsync = ref.read(teamNotifierProvider);
    // Clients are scoped to whoever directly owns them (primaryPartnerId),
    // mirroring NetworkScreen: an Owner assigns across the whole business
    // roster, a Partner only to their own clients. The old code listed
    // business-wide clients for everyone (TESTING_ISSUES_LOG #1).
    final clients = teamAsync.valueOrNull
            ?.where((m) =>
                m.role == 'client' && (isOwner || m.primaryPartnerId == myUserId))
            .toList() ??
        [];

    showDialog<void>(
      context: context,
      builder: (_) => _AssignHomeworkDialog(ref: ref, clients: clients),
    );
  }
}

class _AssignHomeworkDialog extends StatefulWidget {
  const _AssignHomeworkDialog({required this.ref, required this.clients});
  final WidgetRef ref;
  final List<TeamMemberModel> clients;

  @override
  State<_AssignHomeworkDialog> createState() => _AssignHomeworkDialogState();
}

class _AssignHomeworkDialogState extends State<_AssignHomeworkDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String? _selectedClientId;
  String? _selectedClientName;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _selectedClientId == null) return;

    setState(() => _isSaving = true);
    await widget.ref.read(homeworkNotifierProvider.notifier).assign(
          assignedToUserId: _selectedClientId!,
          assignedToUserName: _selectedClientName!,
          title: title,
          description: _descCtrl.text.trim(),
        );
    // The coach view watches businessHomeworkNotifierProvider, and
    // HomeworkNotifier (dependencies: [authNotifierProvider]) cannot
    // invalidate providers outside its dependency set — this screen-side
    // ref does the cross-provider refresh (Riverpod assertion, same
    // constraint as the notification bell).
    widget.ref.invalidate(businessHomeworkNotifierProvider);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Homework'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.clients.isEmpty)
            const Text(
              'No clients to assign to yet — invite a client first.',
              style: AppTextStyles.caption,
            )
          else
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Client'),
              items: widget.clients
                  .map((c) => DropdownMenuItem(
                        value: c.userId,
                        child: Text(c.displayName),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClientId = val;
                  _selectedClientName =
                      widget.clients.firstWhere((c) => c.userId == val).displayName;
                });
              },
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}

class _ClientHomeworkView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(homeworkNotifierProvider);
    return homeworkAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => const Center(
        child: Text('Could not load homework.', style: AppTextStyles.bodyMedium),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No homework yet.', style: AppTextStyles.bodyMedium),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final hw = items[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  hw.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: hw.isCompleted ? AppColors.success : AppColors.grey400,
                ),
                title: Text(hw.title, style: AppTextStyles.titleMedium),
                subtitle: hw.description.isNotEmpty
                    ? Text(hw.description, style: AppTextStyles.caption)
                    : null,
                trailing: hw.isCompleted
                    ? const Text('Done', style: TextStyle(color: AppColors.success))
                    : TextButton(
                        onPressed: () =>
                            ref.read(homeworkNotifierProvider.notifier).markCompleted(hw.id),
                        child: const Text('Mark Done'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CoachHomeworkView extends ConsumerWidget {
  const _CoachHomeworkView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeworkAsync = ref.watch(businessHomeworkNotifierProvider);
    return homeworkAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => const Center(
        child: Text('Could not load homework.', style: AppTextStyles.bodyMedium),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(
            icon: Icons.assignment_outlined,
            headline: 'No homework assigned yet.',
            subtext: 'Assignments for every client show up here.',
          );
        }
        // Rows arrive newest-first business-wide; group them under a
        // client-name header so a coach can scan per-client progress.
        final byClient = <String, List<HomeworkModel>>{};
        for (final hw in items) {
          byClient.putIfAbsent(hw.assignedToUserName, () => []).add(hw);
        }
        final children = <Widget>[];
        byClient.forEach((clientName, homework) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                clientName,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
          children.addAll(homework.map((hw) => _HomeworkCard(hw: hw)));
        });
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(businessHomeworkNotifierProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingH,
              vertical: AppSpacing.xs,
            ),
            children: children,
          ),
        );
      },
    );
  }
}

class _HomeworkCard extends ConsumerWidget {
  const _HomeworkCard({required this.hw});
  final HomeworkModel hw;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          hw.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: hw.isCompleted ? AppColors.success : AppColors.grey400,
        ),
        title: Text(hw.title, style: AppTextStyles.titleMedium),
        subtitle: hw.description.isNotEmpty
            ? Text(hw.description, style: AppTextStyles.caption)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hw.isCompleted)
              const Text('Done', style: TextStyle(color: AppColors.success)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete homework',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This homework will be removed for the client. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Delete',
            isDestructive: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(businessHomeworkNotifierProvider.notifier).delete(hw.id);
            },
          ),
        ],
      ),
    );
  }
}