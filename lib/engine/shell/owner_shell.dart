import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/extensions/context_extensions.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/core/utils/icon_lookup.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/activity/screens/activity_hub_screen.dart';
import 'package:personal_wellness_trainer/modules/dashboard/screens/owner_dashboard_screen.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/screens/owner_finance_screen.dart';
import 'package:personal_wellness_trainer/modules/team/providers/team_notifier.dart';
import 'package:personal_wellness_trainer/modules/team/screens/network_screen.dart';
import 'package:personal_wellness_trainer/modules/notifications/providers/notification_notifier.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/settings_screen.dart';
import 'package:personal_wellness_trainer/core/widgets/tab_placeholder.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(financeActionErrorProvider,
        (_, error) => _handleActionError(context, financeActionErrorProvider, error));
    ref.listen<String?>(activityActionErrorProvider,
        (_, error) => _handleActionError(context, activityActionErrorProvider, error));
    ref.listen<String?>(teamActionErrorProvider,
        (_, error) => _handleActionError(context, teamActionErrorProvider, error));

    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile     = authState.profile;
    final configAsync = ref.watch(configProvider);
    final jobConfig   = ref.watch(activeJobConfigProvider);

    return configAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Configuration error: $e')),
      ),
      data: (_) {
        final engine  = ref.read(permissionsEngineProvider);
        final tabIds  = engine.getAccessibleTabIds(profile);
        final navTabs = _resolveNavTabs(tabIds, jobConfig);
        final clampedIndex = _selectedIndex.clamp(0, navTabs.length - 1);

        return Scaffold(
          appBar: _OwnerAppBar(
            onNotificationsTap: () =>
                context.goNamed(RouteNames.ownerNotifications),
            onChatsTap: () => context.goNamed(RouteNames.ownerMessageList),
          ),
          body: IndexedStack(
            index: clampedIndex,
            children: navTabs.map(_tabBody).toList(),
          ),
          bottomNavigationBar: navTabs.length > 1
              ? _OwnerNavBar(
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

  /// Surfaces a provider-level action error (finance/activity/team) as a
  /// snackbar, then clears the provider so the same error can't re-fire
  /// on the next rebuild. The three `ref.listen` calls above used to each
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

  List<NavTab> _resolveNavTabs(List<String> tabIds, IndustryConfig industry) {
    final configTabs = {for (final t in industry.navigation.tabs) t.id: t};
    final tabs = tabIds
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
      case 'dashboard':  return const OwnerDashboardScreen();
      case 'activity':   return const ActivityHubScreen();
      case 'finance':    return const OwnerFinanceScreen();
      case 'network':    return const NetworkScreen();
      case 'settings':   return const SettingsScreen();
      default:           return TabPlaceholder(label: tab.label);
    }
  }
}

// ── App bar ────────────────────────────────────────────────────────────────

class _OwnerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _OwnerAppBar({
    required this.onNotificationsTap,
    required this.onChatsTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onChatsTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationUnreadCountProvider);

    final authState = ref.watch(authNotifierProvider);
    final canMessage = authState is AuthAuthenticated &&
        ref
            .watch(permissionsEngineProvider)
            .canAccessModule('messaging', authState.profile);

    return AppBar(
      title: const SizedBox.shrink(),
      actions: [
        if (canMessage)
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            onPressed: onChatsTap,
            tooltip: 'Chats',
          ),
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

class _OwnerNavBar extends StatelessWidget {
  const _OwnerNavBar({
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
                // Stable key independent of display label/terminology
                // ('Sessions', 'Classes', 'Appointments' etc. all
                // vary by job type). integration_test/helpers/robot.dart
                // uses 'nav_activity_tab' to reliably reach
                // ActivityHubScreen regardless of terminology.
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

// TabPlaceholder is now in lib/core/widgets/tab_placeholder.dart

