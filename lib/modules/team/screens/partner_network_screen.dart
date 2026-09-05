// lib/modules/team/screens/partner_network_screen.dart
//
// The partner's view of the business network.
//
// A Partner (invited personally by an Owner, not yet upgraded to Pro) has
// exactly one Owner — whoever invited them. That relationship is shown as
// a small info card at the top of the screen, not as a browsable tab (a
// list of one doesn't need a tab).
//
// Below it: the Partner's OWN clients only — i.e. clients whose
// primaryPartnerId is this Partner's userId. A client invited through this
// Partner belongs to the Partner, not to the Owner who invited the
// Partner — ownership is per-direct-inviter, not shared with the Owner,
// even while the Partner hasn't upgraded to Pro yet. See
// mock_team_source.dart's _resolveClientOwnerId for how that chain
// resolves on signup (including client-invites-client referrals).
//
// Partners cannot see Staff or other Partners — those stay scoped to the
// Owner's side of the business.
//
// FIX 1: _MemberTile avatar now uses member.displayName.avatarInitials
//         from string_extensions.dart instead of manually extracting [0].
// FIX 2 (historical): the old local _ChatIconButton._openDm here guarded
//         against a missing mounted check that network_screen.dart's copy
//         already had. Both local copies have since been replaced by the
//         single shared ChatIconButton widget (team/widgets/chat_icon_button.dart)
//         so this class of bug can't recur from copies drifting apart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/chat_icon_button.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/invite_dialog.dart';

class PartnerNetworkScreen extends ConsumerWidget {
  const PartnerNetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config       = ref.watch(configProvider).valueOrNull;
    final networkLabel = config?.industry.terminology.network ?? 'Network';
    final membersAsync = ref.watch(teamNotifierProvider);
    final authState     = ref.watch(authNotifierProvider);
    final myUserId =
        authState is AuthAuthenticated ? authState.profile.userId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(networkLabel),
        automaticallyImplyLeading: false,
      ),
      body: membersAsync.when(
        loading: () => const LoadingIndicator(),
        error:   (e, _) => Center(child: Text('$e')),
        data: (all) {
          final owner = _findOwner(all);
          final myClients = all
              .where((m) => m.role == 'client' && m.primaryPartnerId == myUserId)
              .toList();

          return Column(
            children: [
              if (owner != null) _OwnerCard(owner: owner),
              Expanded(
                child: _MemberList(
                  members:    myClients,
                  emptyLabel: 'No clients yet.',
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const InviteDialog(role: 'client'),
        ),
        tooltip: 'Invite a client',
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  TeamMemberModel? _findOwner(List<TeamMemberModel> all) {
    for (final m in all) {
      if (m.role == 'owner') return m;
    }
    return null;
  }
}

// ── Owner card (non-tab — a Partner only ever has one Owner) ────────────────────

class _OwnerCard extends ConsumerWidget {
  const _OwnerCard({required this.owner});
  final TeamMemberModel owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  owner.displayName.avatarInitials,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Owner', style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    )),
                    Text(owner.displayName, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              ChatIconButton(member: owner),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Member list ───────────────────────────────────────────────────────────────

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members, required this.emptyLabel});
  final List<TeamMemberModel> members;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Text(emptyLabel,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _MemberTile(member: members[i]),
    );
  }
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});
  final TeamMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          // FIX: was `member.displayName[0].toUpperCase()` — crashes on empty name.
          // Now uses .avatarInitials which safely returns '?' for empty strings.
          member.displayName.avatarInitials,
          style: AppTextStyles.titleSmall.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title:    Text(member.displayName, style: AppTextStyles.bodyMedium),
      subtitle: member.email != null
          ? Text(member.email!, style: AppTextStyles.caption)
          : null,
      trailing: ChatIconButton(member: member),
    );
  }
}
