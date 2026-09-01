// lib/modules/chat/screens/chat_room_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/modules/chat/providers/message_notifier.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversation});

  final ConversationModel conversation;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController       _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;
    _inputController.clear();

    await ref
        .read(messageNotifierProvider(widget.conversation.id).notifier)
        .sendMessage(content: content);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _showAttachmentPicker(BuildContext context) {
    if (!mounted) return;
    final config = ref.read(configProvider).valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final attachmentModules =
        config?.industry.messagingSettings?.attachments ?? [];

    final options = <_AttachmentOption>[
      _AttachmentOption(
        moduleId: 'photo',
        label: 'Photo / Video',
        icon: Icons.photo_outlined,
        color: colorScheme.primary,
      ),
      _AttachmentOption(
        moduleId: 'document',
        label: 'Document',
        icon: Icons.insert_drive_file_outlined,
        color: colorScheme.secondary,
      ),
      _AttachmentOption(
        moduleId: 'audio',
        label: 'Audio',
        icon: Icons.mic_outlined,
        color: colorScheme.tertiary,
      ),
      if (attachmentModules.contains('gps'))
        _AttachmentOption(
          moduleId: 'gps',
          label: 'Location',
          icon: Icons.location_on_outlined,
          color: colorScheme.secondary,
        ),
      if (attachmentModules.contains('activity'))
        _AttachmentOption(
          moduleId: 'activity',
          label: 'Activity',
          icon: Icons.event_note_outlined,
          color: colorScheme.error,
        ),
      if (attachmentModules.contains('catalog'))
        _AttachmentOption(
          moduleId: 'catalog',
          label: 'Product',
          icon: Icons.storefront_outlined,
          color: colorScheme.primary,
        ),
      if (attachmentModules.contains('media'))
        _AttachmentOption(
          moduleId: 'media',
          label: 'Media File',
          icon: Icons.perm_media_outlined,
          color: colorScheme.tertiary,
        ),
    ];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AttachmentPicker(options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final profile       = authState.profile;
    final asyncMessages = ref.watch(
      messageNotifierProvider(widget.conversation.id),
    );
    final conversationName =
        widget.conversation.displayName(profile.userId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen(
      messageNotifierProvider(widget.conversation.id),
      (_, __) => _scrollToBottom(),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversationName, style: AppTextStyles.titleLarge),
            if (widget.conversation.isGroup)
              Text(
                '${widget.conversation.participantIds.length} members',
                style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _MessageArea(
              asyncMessages:  asyncMessages,
              scrollController: _scrollController,
              userId:         profile.userId,
              isGroup:        widget.conversation.isGroup,
            ),
          ),
          _MessageInputBar(
            inputController: _inputController,
            onSend:          _sendMessage,
            onAttach:        () => _showAttachmentPicker(context),
          ),
        ],
      ),
    );
  }
}


// ── Message area ──────────────────────────────────────────────────────────────

class _MessageArea extends StatelessWidget {
  const _MessageArea({
    required this.asyncMessages,
    required this.scrollController,
    required this.userId,
    required this.isGroup,
  });

  final AsyncValue<List<dynamic>> asyncMessages;
  final ScrollController scrollController;
  final String userId;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return asyncMessages.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Could not load messages.\n$e',
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet.\nSay hello!',
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final msg      = messages[i];
            final isMe     = msg.senderId == userId;
            final showName = !isMe && isGroup &&
                (i == 0 || messages[i - 1].senderId != msg.senderId);
            return _MessageBubble(message: msg, isMe: isMe, showName: showName);
          },
        );
      },
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.inputController,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController inputController;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm, AppSpacing.sm, AppSpacing.sm,
        AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom / 2,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_outlined),
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Attach',
            onPressed: onAttach,
          ),
          Expanded(
            child: TextField(
              controller: inputController,
              minLines: 1, maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Send',
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showName,
  });

  final dynamic message;
  final bool isMe;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // M3 Standard Bubble colors: PrimaryContainer for sender, SurfaceContainer for recipient
    final bgColor = isMe
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    final textStyle = AppTextStyles.bodyMedium.copyWith(
      color: isMe ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
    );

    final alignment = isMe
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (showName)
            Padding(
              padding: const EdgeInsets.only(
                left:   AppSpacing.xs,
                bottom: AppSpacing.xs / 2,
              ),
              child: Text(
                message.senderName as String,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical:   AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Text(
              message.content as String,
              style: textStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top:   AppSpacing.xs / 2,
              left:  AppSpacing.xs,
              right: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize:      MainAxisSize.min,
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.time(message.createdAt as DateTime),
                  style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (isMe) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    (message.isRead as bool)
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size:  AppSpacing.iconSizeSm,
                    color: (message.isRead as bool)
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withAlpha(120),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Removed duplicate _formatTime — use AppFormatters.time() from core/utils/formatters.dart
}

class _AttachmentOption {
  const _AttachmentOption({
    required this.moduleId,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String moduleId;
  final String label;
  final IconData icon;
  final Color color;
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({required this.options});
  final List<_AttachmentOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: options.length,
            itemBuilder: (context, i) {
              final opt = options[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${opt.label} — coming in Phase 10'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: opt.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(opt.icon, color: opt.color, size: 26),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      opt.label,
                      style: AppTextStyles.caption.copyWith(color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}