// lib/engine/shell/partner_shell.dart
//
// The Partner Shell. Permanent rules always wired.
// Finance wired: Phase 2 (partner earnings view).
// Activity wired: Phase 3.
// Dashboard wired: Phase 6.
//
// ⚠️ HARDCODED RULES — never removable:
//   1. Upgrade to Pro prompt always visible.
//   2. Locked features visible but grayed, never hidden.
//   3. Owner Control Panel: never shown.
//   4. Full Finance: never shown.
//   5. Dashboard is always Tab 1.
//
// Phase 9 fixes:
//   - Tab labels use activeJobConfigProvider (job-specific terminology).
//   - Settings appended as the last nav tab — was in _tabBody but unreachable.

import 'package:personal_wellness_trainer/engine/config/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/modules/team/screens/partner_network_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/extensions/context_extensions.dart';
import 'package:personal_wellness_trainer/core/widgets/tab_placeholder.dart';
import 'package:personal_wellness_trainer/core/widgets/upgrade_prompt.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/core/utils/icon_lookup.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/activity/screens/activity_hub_screen.dart';
import 'package:personal_wellness_trainer/modules/chat/screens/community_feed_screen.dart';
import 'package:personal_wellness_trainer/modules/challenges/screens/challenge_list_screen.dart';
import 'package:personal_wellness_trainer/modules/homework/screens/homework_list_screen.dart';
import 'package:personal_wellness_trainer/modules/dashboard/screens/partner_dashboard_screen.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/screens/partner_finance_screen.dart';
import 'package:personal_wellness_trainer/modules/notifications/providers/notification_notifier.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/settings_screen.dart';

class PartnerShell extends ConsumerStatefulWidget {
  const PartnerShell({super.key});

  @override
  ConsumerState<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends ConsumerState<PartnerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(financeActionErrorProvider,
        (_, error) => _handleActionError(context, financeActionErrorProvider, error));
    ref.listen<String?>(activityActionErrorProvider,
        (_, error) => _handleActionError(context, activityActionErrorProvider, error));

    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile     = authState.profile;
    final configAsync = ref.watch(configProvider);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);
    final flags = flagsAsync.valueOrNull;

    return configAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Configuration error: $e'))),
      data: (_) {
        final engine  = ref.read(permissionsEngineProvider);
        final tabIds  = engine.getAccessibleTabIds(profile);
        final navTabs = _resolveNavTabs(tabIds, jobConfig, flags);
        final clampedIndex = _selectedIndex.clamp(0, navTabs.length - 1);

        return Scaffold(
          appBar: _PartnerAppBar(
            profile: profile,
            jobConfig: jobConfig,
            onNotificationsTap: () =>
                context.goNamed(RouteNames.partnerNotifications),
          ),
          body: Column(
            children: [
              // HARDCODED RULE: Upgrade banner always at top of every tab.
              UpgradePrompt(
                compact: true,
                buttonLabel: jobConfig.upgrade.buttonLabel,
                onUpgradeTap: _handleUpgradeTap,
              ),
              Expanded(
                child: IndexedStack(
                  index: clampedIndex,
                  children: navTabs.map(_tabBody).toList(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: navTabs.length > 1
              ? _PartnerNavBar(
                  navTabs: navTabs,
                  selectedIndex: clampedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                )
              : null,
        );
      },
    );
  }

  /// Surfaces a provider-level action error (finance/activity) as a
  /// snackbar, then clears the provider so the same error can't re-fire
  /// on the next rebuild. The two `ref.listen` calls above used to each
  /// repeat this four-line body inline.
  void _handleActionError(
    BuildContext context,
    StateProvider<String?> provider,
    String? error,
  ) {
    if (error != null && mounted) {
      context.showSnackBar(error, isError: true);
      ref.read(provider.notifier).state = null;
    }
  }

  List<NavTab> _resolveNavTabs(List<String> tabIds, IndustryConfig industry, FeatureFlags? flags) {
    final filteredIds = flags == null ? tabIds : tabIds.where((id) {
      switch (id) {
        case 'community':   return flags.communityFeedShowInPartnerShell;
        case 'challenges':  return flags.challengesShowInPartnerShell;
        case 'homework':    return flags.homeworkShowInPartnerShell;
        default:            return true;
      }
    }).toList();

    final configTabs = {for (final t in industry.navigation.tabs) t.id: t};
    final tabs = filteredIds
        .where((id) => id != 'settings')
        .map((id) {
          final base = configTabs[id] ??
              NavTab(
                id: id,
                icon: 'circle_outlined',
                label: industry.terminology.labelFor(id),
              );
          if (id == 'activity') {
            return NavTab(
              id: base.id,
              icon: base.icon,
              label: industry.terminology.activities,
            );
          }
          if (id == 'community') {
            return const NavTab(
              id: 'community',
              icon: 'chat_bubble_outline',
              label: 'Community',
            );
          }
          if (id == 'challenges') {
            return const NavTab(
              id: 'challenges',
              icon: 'emoji_events',
              label: 'Challenges',
            );
          }
          if (id == 'homework') {
            return const NavTab(
              id: 'homework',
              icon: 'assignment',
              label: 'Homework',
            );
          }
          // Explicit override for 'network', mirroring the owner shell's
          // equivalent tab (tested & confirmed as 'Network' by 02_02).
          // Without this, id=='network' falls through to
          // industry.terminology.labelFor('network'), which resolves to
          // the PARTNER terminology word (e.g. 'Partners') since that's
          // literally what this tab is about for a partner — but that
          // means the persistent NavigationBar destination always reads
          // 'Partners', which is always hit-testable (NavigationBar shows
          // every destination regardless of which tab is selected) and
          // incorrectly satisfies "no Partners tab should be visible"
          // checks. PartnerNetworkScreen itself (the tab body) only ever
          // shows Owner/Staff/Clients sub-tabs — 'Network' is the
          // accurate, generic label for it.
          if (id == 'network') {
            return const NavTab(
              id: 'network',
              icon: 'people_outline',
              label: 'Network',
            );
          }
          return base;
        })
        .toList();

    tabs.add(const NavTab(
      id: 'settings',
      icon: 'settings_outlined',
      label: 'Settings',
    ));

    return tabs;
  }

  Widget _tabBody(NavTab tab) {
    switch (tab.id) {
      case 'dashboard': return const PartnerDashboardScreen();
      case 'activity':  return const ActivityHubScreen();
      case 'finance':   return const PartnerFinanceScreen();
      case 'network':   return const PartnerNetworkScreen();
      case 'community': return const CommunityFeedScreen();
      case 'challenges': return const ChallengeListScreen();
      case 'homework':   return const HomeworkListScreen();
      case 'settings':  return const SettingsScreen();
      default:          return TabPlaceholder(label: tab.label);
    }
  }

  void _handleUpgradeTap() {
    // Navigate to the buyer's contact page (OwnBusinessScreen) so the
    // partner can request to be upgraded to an owner account.
    context.pushNamed(RouteNames.ownBusiness);
  }
}

// ── App bar ────────────────────────────────────────────────────────────────

class _PartnerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _PartnerAppBar({
    required this.profile,
    required this.jobConfig,
    required this.onNotificationsTap,
  });

  final UserProfile profile;
  final IndustryConfig jobConfig;
  final VoidCallback onNotificationsTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationUnreadCountProvider);
    return AppBar(
      // Show the partner's own business name rather than the role term
      // itself. jobConfig.terminology.partner (e.g. "Partners") used to
      // be the title here — always visible on every tab via this
      // persistent AppBar — which collided with tests checking that a
      // partner has no "browse other partners" feature. The business
      // name is also more useful context for the user than seeing their
      // own role repeated as the page title.
      title: Text(
        (profile.businessName?.isNotEmpty ?? false)
            ? profile.businessName!
            : jobConfig.terminology.partner,
      ),
      actions: [
        IconButton(
          icon: Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: onNotificationsTap,
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

// ── Bottom navigation ────────────────────────────────────────────────────────

class _PartnerNavBar extends StatelessWidget {
  const _PartnerNavBar({
    required this.navTabs,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavTab> navTabs;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: navTabs
          .map((tab) => NavigationDestination(
                key: tab.id == 'activity'
                    ? const ValueKey('nav_activity_tab')
                    : null,
                icon: Icon(navTabIconFromString(tab.icon)),
                selectedIcon: Icon(navTabIconFromString(tab.icon)),
                label: tab.label,
              ))
          .toList(),
    );
  }
}

