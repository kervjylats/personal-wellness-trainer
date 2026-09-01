// lib/core/widgets/dev_quick_launch.dart
//
// DEV-ONLY widget — only active when DataConfig.useMockData is true.
//
// Renders a small floating button with Key('dev_quick_launch_btn').
// When tapped it shows a bottom sheet with:
//   • A chip per job type  → Key('dev_job_$jobId')   signs in as owner for that job
//   • A chip per role      → Key('dev_role_$role')   signs in as partner/staff/client
//
// These keys are what integration_test/helpers/robot.dart looks for
// via devSignInAsJob() and devSignInAsRole().
//
// Add to auth_screen.dart Scaffold:
//   floatingActionButton: const DevQuickLaunchButton(),
//
// Do NOT ship in production. Gated behind DataConfig.useMockData.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/dev_tools/qa_console_screen.dart';

// ── Floating button ───────────────────────────────────────────────────────────

class DevQuickLaunchButton extends ConsumerWidget {
  const DevQuickLaunchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DataConfig.useMockData) return const SizedBox.shrink();

    return FloatingActionButton.small(
      key:             const Key('dev_quick_launch_btn'),
      heroTag:         'dev_quick_launch',
      backgroundColor: Colors.deepOrange.shade700,
      tooltip:         'Dev Quick Sign-In',
      onPressed: () => showModalBottomSheet<void>(
        context:           context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _DevLaunchSheet(parentRef: ref),
      ),
      child: const Icon(Icons.developer_mode, color: Colors.white, size: 18),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _DevLaunchSheet extends ConsumerWidget {
  const _DevLaunchSheet({required this.parentRef});

  // parentRef belongs to DevQuickLaunchButton (on auth_screen).
  // We use it for ALL sign-in calls so the ref is always valid,
  // including after Navigator.pop() closes this sheet.
  final WidgetRef parentRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config     = ref.watch(configProvider).valueOrNull;
    final categories = config?.industry.categories ?? [];

    return DraggableScrollableSheet(
      expand:          false,
      initialChildSize: 0.65,
      maxChildSize:    0.90,
      builder: (ctx, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(children: [
              Icon(Icons.developer_mode, color: Colors.deepOrange.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Dev Quick Sign-In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700)),
            ]),
            const SizedBox(height: 4),
            Text('Mock mode only — not available in production',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const Divider(height: 24),

            // ── QA Console entry ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('dev_qa_console_btn'),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Open QA Console (all 4 roles, live)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepOrange.shade700,
                  side: BorderSide(color: Colors.deepOrange.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const QAConsoleScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'See Owner / Partner / Staff / Client side by side — add '
              'something in one panel, watch it appear in the others.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),

            // ── Job type section ──────────────────────────────────────────
            const Text('Sign in as Owner (by job type)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              Text('No categories found in config.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
            else
              Wrap(
                spacing:    8,
                runSpacing: 8,
                children: categories.map((cat) => ActionChip(
                  key:   Key('dev_job_${cat.id}'),
                  label: Text(cat.label, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.deepOrange.shade50,
                  side: BorderSide(color: Colors.deepOrange.shade200),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    parentRef
                        .read(authNotifierProvider.notifier)
                        .devQuickSignIn(jobId: cat.id, jobLabel: cat.label);
                  },
                )).toList(),
              ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── Role section ──────────────────────────────────────────────
            const Text('Sign in as a specific role',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing:    8,
              runSpacing: 8,
              children: [
                // Each _RoleChip is a plain StatelessWidget with a callback
                // that captures parentRef — never its own ConsumerWidget ref,
                // which could be invalidated after the sheet closes.
                _RoleChip(
                  role: 'partner', label: 'Partner', icon: Icons.handshake_outlined,
                  onSignIn: () => parentRef.read(authNotifierProvider.notifier)
                      .devQuickSignIn(jobId: 'partner', jobLabel: 'Partner'),
                ),
                _RoleChip(
                  role: 'staff', label: 'Staff', icon: Icons.badge_outlined,
                  onSignIn: () => parentRef.read(authNotifierProvider.notifier)
                      .devQuickSignIn(jobId: 'staff', jobLabel: 'Staff'),
                ),
                _RoleChip(
                  role: 'client', label: 'Client', icon: Icons.person_outline,
                  onSignIn: () => parentRef.read(authNotifierProvider.notifier)
                      .devQuickSignIn(jobId: 'client', jobLabel: 'Client'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role chip ─────────────────────────────────────────────────────────────────
// Plain StatelessWidget. Receives an onSignIn callback so it uses parentRef
// (from DevQuickLaunchButton) rather than its own ConsumerWidget ref.

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.label,
    required this.icon,
    required this.onSignIn,
  });

  final String       role;
  final String       label;
  final IconData     icon;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      key:             Key('dev_role_$role'),
      avatar:          Icon(icon, size: 16),
      label:           Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue.shade50,
      side:            BorderSide(color: Colors.blue.shade200),
      onPressed: () {
        Navigator.of(context).pop();
        onSignIn();
      },
    );
  }
}
