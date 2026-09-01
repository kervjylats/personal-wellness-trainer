// lib/modules/team/screens/partner_network_screen.dart
//
// The partner's view of the business network.
// Shows owner, staff, and fellow clients. Partners cannot see other partners.
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
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/chat_icon_button.dart';

class PartnerNetworkScreen extends ConsumerStatefulWidget {
  const PartnerNetworkScreen({super.key});

  @override
  ConsumerState<PartnerNetworkScreen> createState() =>
      _PartnerNetworkScreenState();
}

class _PartnerNetworkScreenState extends ConsumerState<PartnerNetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (label: 'Owner',  role: 'owner',  icon: Icons.business_outlined),
    (label: 'Staff',  role: 'staff',  icon: Icons.badge_outlined),
    (label: 'Clients',role: 'client', icon: Icons.person_outline),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config       = ref.watch(configProvider).valueOrNull;
    final networkLabel = config?.industry.terminology.network ?? 'Network';
    final membersAsync = ref.watch(teamNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(networkLabel),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(
            icon: Icon(t.icon, size: 18),
            text: t.label,
            iconMargin: const EdgeInsets.only(bottom: 2),
          )).toList(),
          labelStyle: AppTextStyles.labelSmall,
        ),
      ),
      body: membersAsync.when(
        loading: () => const LoadingIndicator(),
        error:   (e, _) => Center(child: Text('$e')),
        data: (all) => TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            final members = all.where((m) => m.role == t.role).toList();
            return _MemberList(
              members:    members,
              emptyLabel: 'No ${t.label.toLowerCase()} yet.',
            );
          }).toList(),
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


