// lib/modules/notifications/providers/notification_notifier.dart
//
// NotificationNotifier — manages the list of all notifications for the
//   authenticated user. Optimistic UI: state is updated immediately on
//   markRead / markAllRead / delete before the repository call completes.
//
// notificationUnreadCountProvider — derived provider used by all shells
//   to drive the notification bell badge without extra logic.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/notification_model.dart';
import 'package:personal_wellness_trainer/data/repositories/notification_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_notification_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

// ── Internal repository provider ──────────────────────────────────────────────

final _notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  if (DataConfig.useMockData) return MockNotificationSource();
  throw UnimplementedError('SupabaseNotificationSource — Phase 10');
});

// ── Notifications list provider ───────────────────────────────────────────────

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(
  NotificationNotifier.new,
  dependencies: [authNotifierProvider],
);

/// Derived provider — used by all shells for the notification bell badge.
/// Returns 0 when the notifier is loading or has no data.
final notificationUnreadCountProvider = Provider<int>(
  (ref) {
    return ref
            .watch(notificationNotifierProvider)
            .valueOrNull
            ?.where((n) => !n.isRead)
            .length ??
        0;
  },
  // See lib/dev_tools/qa_console_screen.dart — same Riverpod scoping rule.
  dependencies: [notificationNotifierProvider],
);

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  static const String _tag = 'NotificationNotifier';

  NotificationRepository get _repo =>
      ref.read(_notificationRepositoryProvider);

  @override
  Future<List<NotificationModel>> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return const [];
    final notifs = await _repo.getNotifications(
      auth.profile.businessId,
      auth.profile.userId,
    );
    AppLogger.info('${notifs.length} notifications loaded', tag: _tag);
    return notifs;
  }

  /// Mark a single notification as read — optimistic: state updates
  /// immediately; rolls back on repository failure.
  Future<void> markRead(String notificationId) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current
            .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
            .toList(),
      );
    }
    try {
      await _repo.markRead(notificationId);
    } catch (e, st) {
      AppLogger.error('markRead failed', tag: _tag, error: e, stackTrace: st);
      ref.invalidateSelf();
    }
  }

  /// Mark all notifications as read — optimistic update.
  Future<void> markAllRead() async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return;

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
    }
    try {
      await _repo.markAllRead(auth.profile.businessId, auth.profile.userId);
    } catch (e, st) {
      AppLogger.error(
        'markAllRead failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      ref.invalidateSelf();
    }
  }

  /// Delete a notification — optimistic: removed from list immediately.
  Future<void> delete(String notificationId) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.where((n) => n.id != notificationId).toList(),
      );
    }
    try {
      await _repo.deleteNotification(notificationId);
    } catch (e, st) {
      AppLogger.error('delete failed', tag: _tag, error: e, stackTrace: st);
      ref.invalidateSelf();
    }
  }
}

