// lib/modules/team/widgets/chat_icon_button.dart
//
// Shared by network_screen.dart and partner_network_screen.dart. Both
// screens used to keep their own copy of this widget in sync by hand —
// see the "FIX: was `if (conv == null) return` with no mounted check"
// comment history in partner_network_screen.dart, which is exactly the
// kind of drift a shared widget avoids going forward.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/data/models/team_member_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/permissions/permissions_engine.dart';
import 'package:personal_wellness_trainer/engine/providers/chat_launcher_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';

class ChatIconButton extends ConsumerWidget {
  const ChatIconButton({
    super.key,
    required this.member,
    this.hideIfMessagingDisabled = false,
  });

  final TeamMemberModel member;

  /// When true, renders nothing if the messaging module isn't enabled
  /// for this job type / not accessible to the current role.
  final bool hideIfMessagingDisabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hideIfMessagingDisabled) {
      final authState = ref.watch(authNotifierProvider);
      if (authState is! AuthAuthenticated) return const SizedBox.shrink();
      final canMessage = ref
          .watch(permissionsEngineProvider)
          .canAccessModule('messaging', authState.profile);
      if (!canMessage) return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.chat_bubble_outline, size: 20),
      color: Theme.of(context).colorScheme.primary,
      tooltip: 'Message ${member.displayName}',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () => unawaited(_openDm(context, ref)),
    );
  }

  Future<void> _openDm(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return;
    final role = AppRole.fromString(authState.profile.role);

    final conv = await ref.read(chatLauncherProvider).openDirect(
          participantId: member.userId,
          participantName: member.displayName,
        );

    if (conv == null || !context.mounted) return;

    final routeName = switch (role) {
      AppRole.owner   => RouteNames.ownerMessageThread,
      AppRole.partner => RouteNames.partnerMessageThread,
      AppRole.staff   => RouteNames.staffMessageThread,
      AppRole.client  => RouteNames.clientMessageThread,
    };
    await context.pushNamed(routeName, extra: conv);
  }
}
