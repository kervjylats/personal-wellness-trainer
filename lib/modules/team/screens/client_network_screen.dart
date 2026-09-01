// lib/modules/team/screens/client_network_screen.dart
//
// Client's Network tab.
// Clients can see and message:
//   - The Owner (always)
//   - All of the Owner's Partners (always — they serve the same clients)
//   - Staff (only if the staff member's featureToggles['client_can_message'] == true)
//
// Chat icon on every tile opens a direct conversation. The + FAB invites
// another client to join the same coach — shares the same InviteDialog
// used by network_screen.dart, since generateLink() already scopes
// itself correctly to whichever business the current user belongs to.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/providers/chat_launcher_provider.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/invite_dialog.dart';

class ClientNetworkScreen extends ConsumerWidget {
  const ClientNetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final asyncAll = ref.watch(teamNotifierProvider);

    return Scaffold(
      body: asyncAll.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(
          message: 'Could not load contacts.',
          onRetry: () => ref.invalidate(teamNotifierProvider),
        ),
        data: (members) {
          final owners = members.where((m) => m.role == 'owner').toList();
          final partners = members.where((m) => m.role == 'partner').toList();

          // Staff only visible if owner enabled 'client_can_message' for that staff
          final visibleStaff = members
              .where((m) =>
                  m.role == 'staff' &&
                  m.featureToggles['client_can_message'] == true)
              .toList();

          final allContacts = [...owners, ...partners, ...visibleStaff];

          if (allContacts.isEmpty) {
            return const Center(
              child: Text(
                'No contacts yet.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: [
              if (owners.isNotEmpty) ...[
                _SectionLabel(label: 'Owner', count: owners.length),
                ...owners.map((m) => _ContactTile(member: m)),
              ],
              if (partners.isNotEmpty) ...[
                _SectionLabel(label: 'Partners', count: partners.length),
                ...partners.map((m) => _ContactTile(member: m)),
              ],
              if (visibleStaff.isNotEmpty) ...[
                _SectionLabel(label: 'Staff', count: visibleStaff.length),
                ...visibleStaff.map((m) => _ContactTile(member: m)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const InviteDialog(role: 'client'),
        ),
        tooltip: 'Invite a friend',
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPaddingH,
        right: AppSpacing.screenPaddingH,
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        '$label ($count)',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Contact tile ──────────────────────────────────────────────────────────────

class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.member});
  final TeamMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = member.displayName.avatarInitials;

    final roleColor = switch (member.role) {
      'owner'   => Theme.of(context).colorScheme.primary,
      'partner' => AppColors.rolePartner,
      'staff'   => AppColors.roleStaff,
      _         => AppColors.grey400,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: roleColor.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: AppTextStyles.titleSmall.copyWith(color: roleColor),
        ),
      ),
      title: Text(member.displayName, style: AppTextStyles.bodyMedium),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _roleLabel(member.role),
              style: AppTextStyles.caption.copyWith(color: roleColor),
            ),
          ),
          if (member.email != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                member.email!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        color: Theme.of(context).colorScheme.primary,
        tooltip: 'Message ${member.displayName}',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () => unawaited(_openDm(context, ref)),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'owner'   => 'Owner',
        'partner' => 'Partner',
        'staff'   => 'Staff',
        _         => role,
      };

  Future<void> _openDm(BuildContext context, WidgetRef ref) async {
    final conv = await ref.read(chatLauncherProvider).openDirect(
          participantId: member.userId,
          participantName: member.displayName,
        );
    if (conv == null || !context.mounted) return;
    // Chat thread navigation via GoRouter is wired in Phase 10.
    // Conversation record is created here so unread count already tracks.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation with ${member.displayName} started.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
