// test/modules/notifications/notification_notifier_test.dart
//
// Tests for NotificationNotifier — Blueprint Section 16.
// Verifies notification loading, mark-read, mark-all-read, delete,
// and the derived unread count provider against MockNotificationSource.
// Run with: flutter test test/modules/notifications/notification_notifier_test.dart
//
// NOTE: MockNotificationSource uses a static in-memory store shared across
// test runs within the same process.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_wellness_trainer/data/models/notification_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/notifications/providers/notification_notifier.dart';

void main() {
  // ── Helper ───────────────────────────────────────────────────────────────────

  ProviderContainer ownerContainer() {
    final profile = UserProfile(
      userId: 'usr_owner_001',
      businessId: 'biz_mock_001',
      role: 'owner',
      displayName: 'Test Owner',
      joinedAt: DateTime(2025),
      isActive: true,
    );
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(profile)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ── NotificationNotifier — build ──────────────────────────────────────────────

  group('NotificationNotifier — build', () {
    test('returns a list of NotificationModel', () async {
      final container = ownerContainer();
      final result =
          await container.read(notificationNotifierProvider.future);
      expect(result, isA<List<NotificationModel>>());
    });

    test('unauthenticated user receives empty list', () async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider
              .overrideWith(() => _UnauthenticatedFakeAuth()),
        ],
      );
      addTearDown(container.dispose);
      final result =
          await container.read(notificationNotifierProvider.future);
      expect(result, isEmpty);
    });

    test('mock data contains at least one notification', () async {
      final container = ownerContainer();
      final result =
          await container.read(notificationNotifierProvider.future);
      expect(result, isNotEmpty);
    });
  });

  // ── NotificationNotifier — markRead ──────────────────────────────────────────

  group('NotificationNotifier — markRead', () {
    test('marks a single notification as read', () async {
      final container = ownerContainer();
      final notifs =
          await container.read(notificationNotifierProvider.future);

      // Find the first unread notification.
      final unread = notifs.firstWhere(
        (n) => !n.isRead,
        orElse: () => notifs.first,
      );

      await container
          .read(notificationNotifierProvider.notifier)
          .markRead(unread.id);

      final updated =
          await container.read(notificationNotifierProvider.future);
      final target = updated.firstWhere((n) => n.id == unread.id);
      expect(target.isRead, isTrue);
    });
  });

  // ── NotificationNotifier — markAllRead ───────────────────────────────────────

  group('NotificationNotifier — markAllRead', () {
    test('all notifications become read after markAllRead', () async {
      final container = ownerContainer();

      await container
          .read(notificationNotifierProvider.notifier)
          .markAllRead();

      final notifs =
          await container.read(notificationNotifierProvider.future);
      expect(notifs.every((n) => n.isRead), isTrue);
    });

    test('unreadCount derived provider reaches zero after markAllRead',
        () async {
      final container = ownerContainer();

      await container
          .read(notificationNotifierProvider.notifier)
          .markAllRead();

      final count = container.read(notificationUnreadCountProvider);
      expect(count, equals(0));
    });
  });

  // ── NotificationNotifier — delete ────────────────────────────────────────────

  group('NotificationNotifier — delete', () {
    test('delete removes notification from the list', () async {
      final container = ownerContainer();
      final before =
          await container.read(notificationNotifierProvider.future);
      expect(before, isNotEmpty);

      final target = before.first;

      await container
          .read(notificationNotifierProvider.notifier)
          .delete(target.id);

      final after =
          await container.read(notificationNotifierProvider.future);
      expect(after.any((n) => n.id == target.id), isFalse);
      expect(after.length, equals(before.length - 1));
    });
  });
}

// ── Fake auth helpers ──────────────────────────────────────────────────────────

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}

class _UnauthenticatedFakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthUnauthenticated();
}
