// lib/engine/shell/staff_shell.dart
//
// The Staff Shell.
// Finance: not shown by default (owner can toggle can_view_finance per-staff).
// Activity wired: Phase 3.
// Dashboard wired: Phase 6.
//
// Phase 9 fixes:
//   - Tab labels use activeJobConfigProvider (job-specific terminology).
//   - Settings appended as the last nav tab.

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
import 'package:personal_wellness_trainer/modules/chat/screens/community_feed_screen.dart';
import 'package:personal_wellness_trainer/modules/challenges/screens/challenge_list_screen.dart';
import 'package:personal_wellness_trainer/modules/homework/screens/homework_list_screen.dart';
import 'package:personal_wellness_trainer/modules/dashboard/screens/staff_dashboard_screen.dart';
import 'package:personal_wellness_trainer/modules/notifications/providers/notification_notifier.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/settings_screen.dart';
import 'package:personal_wellness_trainer/core/widgets/tab_placeholder.dart';

class StaffShell extends ConsumerStatefulWidget {
  const StaffShell({super.key});

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(activityActionErrorProvider, (_, error) {
      if (error != null && mounted) {
        context.showSnackBar(error, isError: true);
        ref.read(activityActionErrorProvider.notifier).state = null;
      }
    });

    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile     = authState.profile;
    final configAsync = ref.watch(configProvider);
    final jobConfig   = ref.watch(activeJobConfigProvider);

    return configAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Configuration error: $e'))),
      data: (_) {
        final engine  = ref.read(permissionsEngineProvider);
        final tabIds  = engine.getAccessibleTabIds(profile);
        final navTabs = _resolveNavTabs(tabIds, jobConfig);
        final clampedIndex = _selectedIndex.clamp(0, navTabs.length - 1);

        return Scaffold(
          appBar: AppBar(
            // Job-specific staff title (e.g. "Instructor").
            title: Text(jobConfig.terminology.staff),
            actions: [
              IconButton(
                icon: Badge(
                  label: Text(
                    '${ref.watch(notificationUnreadCountProvider)}',
                  ),
                  isLabelVisible:
                      ref.watch(notificationUnreadCountProvider) > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.goNamed(RouteNames.staffNotifications),
                tooltip: 'Notifications',
              ),
            ],
          ),
          body: IndexedStack(
            index: clampedIndex,
            children: navTabs.map(_tabBody).toList(),
          ),
          bottomNavigationBar: navTabs.length > 1
              ? NavigationBar(
                  selectedIndex: clampedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  destinations: navTabs
                      .map((tab) => NavigationDestination(
                            icon: Icon(navTabIconFromString(tab.icon)),
                            selectedIcon: Icon(navTabIconFromString(tab.icon)),
                            label: tab.label,
                          ))
                      .toList(),
                )
              : null,
        );
      },
    );
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
      case 'dashboard': return const StaffDashboardScreen();
      case 'activity':  return const ActivityHubScreen();
      case 'community': return const CommunityFeedScreen();
      case 'challenges': return const ChallengeListScreen();
      case 'homework':   return const HomeworkListScreen();
      case 'settings':  return const SettingsScreen();
      default:          return TabPlaceholder(label: tab.label);
    }
  }
}

// TabPlaceholder is now in lib/core/widgets/tab_placeholder.dart

