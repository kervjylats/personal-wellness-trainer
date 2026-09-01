// lib/modules/chat/screens/conversations_list_screen.dart
//
// Shows all conversations for the current user (private, group, community).
// Tapping opens ChatRoomScreen.

import 'package:personal_wellness_trainer/engine/config/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/chat/providers/chat_notifier.dart';

class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConvs = ref.watch(chatNotifierProvider);
    final authState  = ref.watch(authNotifierProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);
    final flags = flagsAsync.valueOrNull;

    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile  = authState.profile;
    final role = AppRole.fromString(profile.role);
    final isOwner  = role.isOwner;
    final canCreateGroup = isOwner || (role.isPartner && (flags?.chatPartnerCanCreateGroup ?? false));

    return Scaffold(
      body: asyncConvs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(
          child: Text(
            'Could not load messages.\n$e',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        data: (convs) {
          if (convs.isEmpty) {
            return _EmptyState(isOwner: isOwner);
          }
          return ListView.separated(
            itemCount:   convs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              return _ConversationTile(
                conversation: convs[i],
                currentUserId: profile.userId,
              );
            },
          );
        },
      ),
      floatingActionButton: canCreateGroup
          ? FloatingActionButton(
              heroTag: 'chat_fab',
              onPressed: () => context.goNamed(
                RouteNames.ownerMessageGroupCreate,
                extra: profile,
              ),
              tooltip: 'New group',
              child: const Icon(Icons.group_add_outlined),
            )
          : null,
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  final ConversationModel conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name    = conversation.displayName(currentUserId);
    final preview = conversation.lastMessageContent ?? 'No messages yet';
    final hasTime = conversation.lastMessageAt != null;
    final timeLabel = hasTime
        ? _formatTime(conversation.lastMessageAt!)
        : '';
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: () {
        final authState = ref.read(authNotifierProvider);
        if (authState is! AuthAuthenticated) return;
        final role = AppRole.fromString(authState.profile.role);
        final routeName = switch (role) {
          AppRole.owner => RouteNames.ownerMessageThread,
          AppRole.partner => RouteNames.partnerMessageThread,
          AppRole.staff => RouteNames.staffMessageThread,
          AppRole.client => RouteNames.clientMessageThread,
        };
        context.goNamed(routeName, extra: conversation);
      },
      leading: CircleAvatar(
        radius: AppSpacing.avatarSizeSm,
        backgroundColor: AppColors.grey200,
        child: conversation.isGroup
            ? const Icon(Icons.group_outlined, color: AppColors.grey600)
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.grey700,
                ),
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: hasUnread
                  ? AppTextStyles.titleLarge
                  : AppTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasTime)
            Text(timeLabel, style: AppTextStyles.caption),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              preview,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: AppSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m';
    if (diff.inDays    < 1)  return '${diff.inHours}h';
    if (diff.inDays    < 7)  return '${diff.inDays}d';
    return AppFormatters.date(dt);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isOwner});
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: AppSpacing.iconSizeXxl,
              color: AppColors.grey300,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('No messages yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isOwner
                  ? 'Go to a team member\'s profile to start a direct chat,\nor tap + to create a group.'
                  : 'Your conversations will appear here.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
