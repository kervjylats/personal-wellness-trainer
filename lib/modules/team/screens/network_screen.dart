// lib/modules/team/screens/network_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/providers/business_features_provider.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/chat_icon_button.dart';
import 'package:personal_wellness_trainer/modules/team/widgets/invite_dialog.dart';
import 'package:personal_wellness_trainer/engine/providers/module_error_bus.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<_TabDef> _tabs = [
    _TabDef(label: 'Partners', role: 'partner', icon: Icons.handshake_outlined),
    _TabDef(label: 'Staff',    role: 'staff',   icon: Icons.badge_outlined),
    _TabDef(label: 'Clients',  role: 'client',  icon: Icons.person_outline),
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
    ref.listen<String?>(teamActionErrorProvider, (_, error) {
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        ref.read(teamActionErrorProvider.notifier).state = null;
      }
    });

    ref.listen<String?>(agreementActionErrorProvider, (_, error) {
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        ref.read(agreementActionErrorProvider.notifier).state = null;
      }
    });

    final config       = ref.watch(configProvider).valueOrNull;
    final networkLabel = config?.industry.terminology.network ?? 'Network';

    return Scaffold(
      appBar: AppBar(
        title: Text(networkLabel),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs
              .map((t) => Tab(
                    icon: Icon(t.icon, size: 18),
                    text: t.label,
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ))
              .toList(),
          labelStyle: AppTextStyles.labelSmall,
          isScrollable: false,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _MemberTab(role: t.role)).toList(),
      ),
      floatingActionButton: _tabs[_tabController.index].role == 'partner' &&
              !ref.watch(businessFeaturesProvider).partnersEnabled
          ? null
          : FloatingActionButton(
              onPressed: () => _showInviteDialog(
                context,
                _tabs[_tabController.index].role,
              ),
              tooltip: 'Invite',
              child: const Icon(Icons.person_add_outlined),
            ),
    );
  }

  void _showInviteDialog(BuildContext context, String role) {
    unawaited(showDialog<void>(
      context: context,
      builder: (_) => InviteDialog(role: role),
    ));
  }
}

// ── Member tab ────────────────────────────────────────────────────────────────

class _MemberTab extends ConsumerWidget {
  const _MemberTab({required this.role});
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final myUserId =
        authState is AuthAuthenticated ? authState.profile.userId : null;

    return membersAsync.when(
      loading: () => const LoadingIndicator(),
      error:   (e, _) => ErrorDisplay(
        message: 'Could not load members.',
        onRetry: () => ref.invalidate(teamNotifierProvider),
      ),
      data: (all) {
        final features = ref.watch(businessFeaturesProvider);

        // Partnerships turned off for this business entirely — show why,
        // not an empty list that looks like a bug. Existing partners (if
        // any predate the toggle flip) still function elsewhere; this just
        // stops presenting the tab as if new ones can be added here.
        if (role == 'partner' && !features.partnersEnabled) {
          return const AppEmptyState(
            icon: Icons.handshake_outlined,
            headline: 'Partnerships are turned off',
            subtext: 'This business has the Partnership system disabled.',
          );
        }

        // Clients are scoped to whoever directly owns them (primaryPartnerId).
        // A client invited through a Partner belongs to that Partner, not
        // to this Owner — even though both currently share one businessId.
        // Partners/Staff tabs stay business-wide (unchanged).
        final members = role == 'client'
            ? all
                .where((m) =>
                    m.role == 'client' && m.primaryPartnerId == myUserId)
                .toList()
            : all.where((m) => m.role == role).toList();
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(teamNotifierProvider),
          child: Column(
            children: [
              if (role == 'partner' && features.marketplaceEnabled)
                const _DiscoverPartnersBanner(),
              if (role == 'partner' &&
                  features.agreementsEnabled &&
                  members.isNotEmpty)
                const _ProposeDealBanner(),
              Expanded(
                child: members.isEmpty
                    ? _EmptyTab(role: role)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPaddingH,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: members.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, i) =>
                            _MemberTile(member: members[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Discover partners banner (Partners tab only) ─────────────────────────────

class _DiscoverPartnersBanner extends StatelessWidget {
  const _DiscoverPartnersBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        0,
      ),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: () => context.pushNamed(RouteNames.ownerMarketplace),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover new partners',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Browse other businesses and request a partnership.',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Propose a deal banner (Partners tab, only when there's ≥1 partner) ──────────

class _ProposeDealBanner extends StatelessWidget {
  const _ProposeDealBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.md,
        AppSpacing.screenPaddingH,
        0,
      ),
      child: Material(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: () => context.pushNamed(RouteNames.ownerAgreementCreate),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.handshake_outlined, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Propose a deal',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Set a commission split with one of your partners.',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: colorScheme.onSecondaryContainer),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});
  final TeamMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            member.displayName.avatarInitials,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(member.displayName, style: AppTextStyles.bodyMedium),
        subtitle: member.categoryId != null
            ? Consumer(
                builder: (context, ref, _) {
                  final cats = ref
                          .watch(configProvider)
                          .valueOrNull
                          ?.industry
                          .categories ??
                      [];
                  final label = cats
                          .where((c) => c.id == member.categoryId)
                          .map((c) => c.label)
                          .firstOrNull ??
                      member.categoryId!;
                  return Text('Category: $label',
                      style: AppTextStyles.labelSmall);
                },
              )
            : member.email != null
                ? Text(member.email!, style: AppTextStyles.labelSmall)
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!member.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactive',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.grey600),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            ChatIconButton(member: member, hideIfMessagingDisabled: true),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          final authState = ref.read(authNotifierProvider);
          if (authState is! AuthAuthenticated) return;
          final role = AppRole.fromString(authState.profile.role);
          final name = switch (role) {
            AppRole.owner   => RouteNames.ownerMemberDetail,
            AppRole.partner => RouteNames.partnerMemberDetail,
            AppRole.staff   => RouteNames.staffMemberDetail,
            AppRole.client  => RouteNames.clientMemberDetail,
          };
          context.pushNamed(name, extra: member);
        },
      ),
    );
  }
}

// ── Empty tab ─────────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final config = _tabConfig(role);
    return AppEmptyState(
      icon: config.$1,
      headline: config.$2,
      subtext: 'Tap + to send an invite.',
    );
  }

  static (IconData, String) _tabConfig(String role) => switch (role) {
        'partner' => (Icons.handshake_outlined, 'No partners yet'),
        'staff'   => (Icons.badge_outlined,     'No staff members yet'),
        _         => (Icons.person_outline,     'No clients yet'),
      };
}

// ── Tab definition ────────────────────────────────────────────────────────────

class _TabDef {
  const _TabDef({required this.label, required this.role, required this.icon});
  final String  label;
  final String  role;
  final IconData icon;
}