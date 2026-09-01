// test/modules/activity/activity_notifier_test.dart
//
// Tests for ActivityNotifier — Blueprint Section 16.
// Verifies role-aware loading and all CRUD mutations against the mock source.
// Run with: flutter test test/modules/activity/activity_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/activity_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/activity/providers/activity_notifier.dart';

void main() {
  group('ActivityNotifier', () {
    // ── Helper ─────────────────────────────────────────────────────────────────

    ProviderContainer containerFor(String role) {
      final profile = UserProfile(
        userId: 'usr_${role}_001',
        businessId: 'biz_mock_001',
        role: role,
        displayName: 'Test $role',
        joinedAt: DateTime(2025),
        isActive: true,
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(profile),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    // ── Build tests ────────────────────────────────────────────────────────────

    test('owner receives the full activity list', () async {
      final container = containerFor('owner');
      final result = await container.read(activityNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<ActivityModel>());
    });

    test('staff receives only activities assigned to them', () async {
      final container = containerFor('staff');
      final result = await container.read(activityNotifierProvider.future);
      for (final a in result) {
        expect(a.assignedToUserId, equals('usr_staff_001'));
      }
    });

    test('client receives only their own activities', () async {
      final container = containerFor('client');
      final result = await container.read(activityNotifierProvider.future);
      for (final a in result) {
        expect(a.clientUserId, equals('usr_client_001'));
      }
    });

    test('partner receives an empty list', () async {
      final container = containerFor('partner');
      final result = await container.read(activityNotifierProvider.future);
      expect(result, isEmpty);
    });

    // ── Mutation tests ─────────────────────────────────────────────────────────

    test('create adds a new activity — list grows by one', () async {
      final container = containerFor('owner');
      final before = await container.read(activityNotifierProvider.future);

      final created = await container
          .read(activityNotifierProvider.notifier)
          .create(fields: {'service_type': 'Test', 'amount': 50.0});

      expect(created, isA<ActivityModel>());
      expect(created!.status, equals('pending'));

      final after = await container.read(activityNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('updateStatus changes the status of an activity', () async {
      final container = containerFor('owner');
      final activities = await container.read(activityNotifierProvider.future);
      final target = activities.first;

      final success = await container
          .read(activityNotifierProvider.notifier)
          .updateStatus(target.id, 'completed');

      expect(success, isTrue);

      final after = await container.read(activityNotifierProvider.future);
      final updated = after.firstWhere((a) => a.id == target.id);
      expect(updated.status, equals('completed'));
    });

    test('delete removes the activity from the list', () async {
      final container = containerFor('owner');
      final activities = await container.read(activityNotifierProvider.future);
      final target = activities.first;

      final success = await container
          .read(activityNotifierProvider.notifier)
          .delete(target.id);

      expect(success, isTrue);

      final after = await container.read(activityNotifierProvider.future);
      expect(after.any((a) => a.id == target.id), isFalse);
    });

    test('updateActivity changes the field values of an activity', () async {
      final container = containerFor('owner');
      final activities = await container.read(activityNotifierProvider.future);
      final target = activities.first;

      final updated = await container
          .read(activityNotifierProvider.notifier)
          .updateActivity(
            activityId: target.id,
            fields: {'service_type': 'Updated Service', 'amount': 99.0},
          );

      expect(updated, isA<ActivityModel>());
      expect(updated!.fields['service_type'], equals('Updated Service'));

      final after = await container.read(activityNotifierProvider.future);
      final fromList = after.firstWhere((a) => a.id == target.id);
      expect(fromList.fields['service_type'], equals('Updated Service'));
    });
  });
}

// ── Fake auth notifier ────────────────────────────────────────────────────────
// AuthNotifier extends Notifier<AuthState> — build() is synchronous.

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() {
    return AuthAuthenticated(profile: _profile);
  }
}
