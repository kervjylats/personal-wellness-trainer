// test/modules/reservations/reservations_notifier_test.dart
//
// Tests for ReservationsNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/reservations/reservations_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/reservation_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/reservations/providers/reservations_notifier.dart';

void main() {
  group('ReservationsNotifier', () {
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
          buildConfigProvider.overrideWithValue(fakeEngineConfig.build),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('owner receives all reservations', () async {
      final container = containerFor('owner');
      final result =
          await container.read(reservationsNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<ReservationModel>());
    });

    test('staff receives only their assigned reservations', () async {
      final container = containerFor('staff');
      final result =
          await container.read(reservationsNotifierProvider.future);
      for (final r in result) {
        expect(r.staffUserId, equals('usr_staff_001'));
      }
    });

    test('client receives only their own reservations', () async {
      final container = containerFor('client');
      final result =
          await container.read(reservationsNotifierProvider.future);
      for (final r in result) {
        expect(r.clientUserId, equals('usr_client_001'));
      }
    });

    test('create adds new reservation — list grows by one', () async {
      final container = containerFor('owner');
      final before =
          await container.read(reservationsNotifierProvider.future);
      final now = DateTime.now();

      final created = await container
          .read(reservationsNotifierProvider.notifier)
          .create(
            clientUserId: 'usr_client_001',
            startTime: now.add(const Duration(days: 2, hours: 10)),
            endTime: now.add(const Duration(days: 2, hours: 11)),
          );

      expect(created, isA<ReservationModel>());
      expect(created!.status, equals('pending'));

      final after =
          await container.read(reservationsNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('updateStatus changes reservation status to confirmed', () async {
      final container = containerFor('owner');
      final reservations =
          await container.read(reservationsNotifierProvider.future);
      final pending =
          reservations.firstWhere((r) => r.status == 'pending');

      final success = await container
          .read(reservationsNotifierProvider.notifier)
          .updateStatus(pending.id, 'confirmed');

      expect(success, isTrue);

      final after =
          await container.read(reservationsNotifierProvider.future);
      final updated = after.firstWhere((r) => r.id == pending.id);
      expect(updated.status, equals('confirmed'));
    });

    test('delete removes reservation from list', () async {
      final container = containerFor('owner');
      final reservations =
          await container.read(reservationsNotifierProvider.future);
      final target = reservations.first;

      final success = await container
          .read(reservationsNotifierProvider.notifier)
          .delete(target.id);

      expect(success, isTrue);

      final after =
          await container.read(reservationsNotifierProvider.future);
      expect(after.any((r) => r.id == target.id), isFalse);
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
