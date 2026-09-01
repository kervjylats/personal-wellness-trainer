// lib/modules/chat/screens/community_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/modules/chat/providers/chat_notifier.dart';
import 'package:personal_wellness_trainer/modules/chat/screens/chat_room_screen.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConv = ref.watch(_communityConversationProvider);

    return asyncConv.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Could not load community feed.\n$e')),
      ),
      data: (conv) => ChatRoomScreen(conversation: conv),
    );
  }
}

final _communityConversationProvider =
    FutureProvider.autoDispose<ConversationModel>((ref) async {
  final notifier = ref.read(chatNotifierProvider.notifier);
  return notifier.getCommunityFeed();
});