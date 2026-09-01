// lib/engine/providers/chat_launcher_provider.dart
//
// Engine-level bridge for opening a direct conversation from anywhere
// in the app without violating the cross-module import rule.
//
// Problem: team/ screens need to trigger a DM — but team/ cannot import
// messaging/ directly (Blueprint §14: no cross-module imports).
//
// Solution: this provider lives in engine/ (neutral ground), wraps the
// MessagingRepository directly, and can be safely imported by any module.
//
// Usage:
//   final launcher = ref.read(chatLauncherProvider);
//   final conv = await launcher.openDirect(
//     participantId: member.userId,
//     participantName: member.displayName,
//   );
//   if (conv != null && context.mounted) context.pushNamed(routeName, extra: conv);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/repositories/messaging_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_messaging_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

// ── Internal repository provider ──────────────────────────────────────────────

final _messagingRepoProvider = Provider<MessagingRepository>((ref) {
  if (DataConfig.useMockData) return MockMessagingSource();
  throw UnimplementedError('SupabaseMessagingSource — Phase 10');
});

// ── Chat launcher provider ────────────────────────────────────────────────────

final chatLauncherProvider = Provider<ChatLauncher>((ref) {
  return ChatLauncher(ref);
});

class ChatLauncher {
  ChatLauncher(this._ref);

  final Ref _ref;
  static const String _tag = 'ChatLauncher';

  MessagingRepository get _repo => _ref.read(_messagingRepoProvider);

  /// Gets or creates a direct conversation with [participantId].
  /// Returns null if the user is not authenticated or the operation fails.
  Future<ConversationModel?> openDirect({
    required String participantId,
    required String participantName,
  }) async {
    final auth = _ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return null;

    final profile = auth.profile;
    try {
      return await _repo.getOrCreateDirectConversation(
        businessId: profile.businessId,
        userAId: profile.userId,
        userAName: profile.displayName,
        userBId: participantId,
        userBName: participantName,
      );
    } catch (e, st) {
      AppLogger.error(
        'ChatLauncher.openDirect failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
