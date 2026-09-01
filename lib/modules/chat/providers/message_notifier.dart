// lib/modules/chat/providers/message_notifier.dart
//
// Manages messages for a single conversation. Family provider keyed by conversationId.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/message_model.dart';
import 'package:personal_wellness_trainer/data/repositories/messaging_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_messaging_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final _messagingRepoProvider = Provider<MessagingRepository>((ref) {
  if (DataConfig.useMockData) return MockMessagingSource();
  throw UnimplementedError('SupabaseMessagingSource — Phase 10');
});

final messageNotifierProvider = AsyncNotifierProvider.family<
    MessageNotifier, List<MessageModel>, String>(
  MessageNotifier.new,
);

class MessageNotifier
    extends FamilyAsyncNotifier<List<MessageModel>, String> {
  static const String _tag = 'MessageNotifier';

  MessagingRepository get _repo => ref.read(_messagingRepoProvider);

  @override
  Future<List<MessageModel>> build(String arg) async {
    return _repo.getMessages(arg);
  }

  Future<void> sendMessage({
    required String content,
    String? attachmentId,
    String? attachmentType,
  }) async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return;

    final profile = auth.profile;
    try {
      await _repo.sendMessage(
        conversationId: arg,
        senderId: profile.userId,
        senderName: profile.displayName,
        senderRole: profile.role,
        content: content,
        attachmentId: attachmentId,
        attachmentType: attachmentType,
      );
      ref.invalidateSelf();
    } catch (e, st) {
      AppLogger.error(
        'sendMessage failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }
}