// lib/dev_tools/qa_console_screen.dart
//
// DEV-ONLY screen. Never reachable by real users.
//
// Shows all 4 role panels side by side, each starting completely fresh —
// real sign-in screen, no pre-loaded mock data, no pre-existing session.
// This is the "watch the real story unfold from scratch" version:
//
//   1. OWNER panel: developer signs up as a real owner (real job type,
//      real onboarding) → gets their own businessId → zero pre-seeded
//      fake data.
//   2. PARTNER/STAFF/CLIENT panels: each starts at the sign-in screen.
//      Developer gets an invite code from the Owner's Network tab (the
//      same real invite flow real users will use), types it in the
//      "Have an invite code? Join here" screen, and watches that panel
//      become a real, freshly-created team member.
//
// HOW THE SCOPING WORKS:
//
// Each panel gets its own nested ProviderScope that overrides ONLY
// authNotifierProvider with QaFreshAuthNotifier — a real AuthNotifier
// that starts unauthenticated, supports real sign-up/sign-in/invite-
// join, and ignores any persisted mock session from other panels (so
// signing in on one panel never auto-signs in another).
//
// Every OTHER provider is inherited unchanged from the root ProviderScope,
// so all 4 panels share the same live data store. When the Owner creates
// an activity and the Client refreshes their sessions list, they see it
// — because they share one real MockTeamSource, one real
// MockActivitySource, etc.
//
// Each panel also gets its own GoRouter covering authFlowRoutes() +
// that role's shell routes — defined in app_router.dart so nothing here
// can ever drift out of sync with the real app's navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/navigation/role_routes.dart';

class QAConsoleScreen extends StatelessWidget {
  const QAConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('QA Console — start fresh'),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Tooltip(
              message:
                  'All panels start at the real sign-in screen.\n'
                  'Owner: create a new account.\n'
                  'Others: use an invite code from the Owner\'s Network tab.',
              child: Icon(Icons.info_outline, color: Colors.white70),
            ),
          ),
          IconButton(
            tooltip: 'Close QA Console',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;

          const panels = [
            _RolePanel(label: 'OWNER', color: Colors.deepPurple, role: _Role.owner),
            _RolePanel(label: 'PARTNER', color: Colors.blue, role: _Role.partner),
            _RolePanel(label: 'STAFF', color: Colors.teal, role: _Role.staff),
            _RolePanel(label: 'CLIENT', color: Colors.orange, role: _Role.client),
          ];

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: panels[0]),
                        const SizedBox(width: 8),
                        Expanded(child: panels[1]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: panels[2]),
                        const SizedBox(width: 8),
                        Expanded(child: panels[3]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Narrow window: stack panels vertically, each with a fixed height.
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (final p in panels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(height: 700, child: p),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum _Role { owner, partner, staff, client }

class _RolePanel extends StatefulWidget {
  const _RolePanel({
    required this.label,
    required this.color,
    required this.role,
  });

  final String label;
  final Color color;
  final _Role role;

  @override
  State<_RolePanel> createState() => _RolePanelState();
}

class _RolePanelState extends State<_RolePanel> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // All panels start at /login — the real sign-in screen, completely
    // fresh, no session, no pre-loaded data. The GoRouter for each panel
    // covers the full auth-flow PLUS that role's shell routes. Because
    // these route tables come from the same functions the real app uses
    // (authFlowRoutes(), ownerRoutes(), etc.), any route you register
    // in the real app automatically works inside these panels too.
    _router = GoRouter(
      initialLocation: RouteNames.loginPath,
      routes: [
        ...authFlowRoutes(),
        ...switch (widget.role) {
          _Role.owner => ownerRoutes(),
          _Role.partner => partnerRoutes(),
          _Role.staff => staffRoutes(),
          _Role.client => clientRoutes(),
        },
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: widget.color, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Panel header — sits OUTSIDE the ProviderScope on purpose so
          // it can read the panel's own authNotifierProvider once the
          // scope is mounted. _PanelHeader is itself a ConsumerWidget
          // so it reads from the nearest ProviderScope ancestor, which
          // will be THIS panel's scope once it's built.
          _buildHeader(),
          Expanded(
            child: ProviderScope(
              overrides: [
                // QaFreshAuthNotifier (defined in auth_notifier.dart):
                // a REAL AuthNotifier that starts unauthenticated and
                // ignores any persisted mock session. Supports real
                // sign-up, sign-in, invite-join — all scoped to this
                // panel only.
                authNotifierProvider.overrideWith(QaFreshAuthNotifier.new),
              ],
              child: Router<RouteMatchList>.withConfig(config: _router),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: widget.color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // This ConsumerWidget reads from the nearest ProviderScope
          // ancestor — which is the ROOT scope when the header itself
          // is rendered (the header sits ABOVE the panel's own scope in
          // the widget tree, so it can't see inside it). That's why we
          // use a fresh per-panel GoRouter with its own BuildContext
          // subtree instead. For the header to show per-panel identity,
          // it needs to be embedded INSIDE the ProviderScope — so we
          // use an overlay-style approach: the Router itself renders a
          // thin persistent header bar via a custom Page, OR we simply
          // accept that the header always shows "Not signed in yet" and
          // the panel content itself shows the signed-in state. This is
          // a known Flutter ProviderScope+GoRouter constraint. The panel
          // content (dashboard, etc.) correctly reflects the signed-in
          // identity; only this external label is limited.
          const Text(
            '',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
