// lib/engine/shell/client_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/extensions/context_extensions.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/activity/screens/activity_hub_screen.dart';
import 'package:personal_wellness_trainer/modules/dashboard/screens/client_dashboard_screen.dart';
import 'package:personal_wellness_trainer/modules/discover/screens/discover_screen.dart';
import 'package:personal_wellness_trainer/modules/team/screens/client_network_screen.dart';
import 'package:personal_wellness_trainer/modules/finance/providers/finance_action_error_provider.dart';
import 'package:personal_wellness_trainer/modules/finance/screens/client_payments_screen.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/modules/notifications/providers/notification_notifier.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/settings_screen.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key});

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(financeActionErrorProvider, (_, error) {
      if (error != null && mounted) {
        context.showSnackBar(error, isError: true);
        ref.read(financeActionErrorProvider.notifier).state = null;
      }
    });
    ref.listen<String?>(activityActionErrorProvider, (_, error) {
      if (error != null && mounted) {
        context.showSnackBar(error, isError: true);
        ref.read(activityActionErrorProvider.notifier).state = null;
      }
    });

    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final configAsync = ref.watch(configProvider);
    final jobConfig = ref.watch(activeJobConfigProvider);

    return configAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Configuration error: $e'))),
      data: (_) {
        final visibleTabs = [
          const _ClientTab(id: 'dashboard', icon: Icons.home_outlined, label: 'Home'),
          _ClientTab(id: 'activity', icon: Icons.event_note_outlined, label: jobConfig.terminology.activities),
          const _ClientTab(id: 'discover', icon: Icons.explore_outlined, label: 'Partners'),
          const _ClientTab(id: 'network', icon: Icons.people_outline, label: 'Network'),
          const _ClientTab(id: 'finance', icon: Icons.payments_outlined, label: 'Payments'), // ◄ Fixed: Hardcoded to Payments!
          const _ClientTab(id: 'settings', icon: Icons.settings_outlined, label: 'Settings'),
        ];

        final clampedIndex = _selectedIndex.clamp(0, visibleTabs.length - 1);
        return Scaffold(
          appBar: AppBar(
            title: Text(jobConfig.appName),
            actions: [
              IconButton(
                icon: Badge(
                  label: Text('${ref.watch(notificationUnreadCountProvider)}'),
                  isLabelVisible: ref.watch(notificationUnreadCountProvider) > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.goNamed(RouteNames.clientNotifications),
                tooltip: 'Notifications',
              ),
            ],
          ),
          body: IndexedStack(
            index: clampedIndex,
            children: visibleTabs.map((tab) => _tabBody(tab.id)).toList(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: clampedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: visibleTabs
                .map((tab) => NavigationDestination(
                      key: tab.id == 'activity'
                          ? const ValueKey('nav_activity_tab')
                          : null,
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.icon),
                      label: tab.label,
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _tabBody(String tabId) {
    switch (tabId) {
      case 'dashboard': return const ClientDashboardScreen();
      case 'activity':  return const ActivityHubScreen();
      case 'discover':  return const DiscoverScreen();
      case 'network':   return const ClientNetworkScreen();
      case 'finance':   return const ClientPaymentsScreen();
      case 'settings':  return const SettingsScreen();
      default:          return const SizedBox.shrink();
    }
  }
}

class _ClientTab {
  const _ClientTab({required this.id, required this.icon, required this.label});
  final String id;
  final IconData icon;
  final String label;
}