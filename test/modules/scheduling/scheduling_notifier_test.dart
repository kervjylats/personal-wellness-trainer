// test/modules/scheduling/scheduling_notifier_test.dart
//
// Tests for SchedulingNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/scheduling/scheduling_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/schedule_slot_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/scheduling/providers/scheduling_notifier.dart';

void main() {
  group('SchedulingNotifier', () {
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

    test('owner receives all slots', () async {
      final container = containerFor('owner');
      final result = await container.read(schedulingNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<ScheduleSlotModel>());
    });

    test('client receives only available slots', () async {
      final container = containerFor('client');
      final result = await container.read(schedulingNotifierProvider.future);
      for (final slot in result) {
        expect(slot.isAvailable, isTrue);
      }
    });

    test('staff receives only their own slots', () async {
      final container = containerFor('staff');
      final result = await container.read(schedulingNotifierProvider.future);
      for (final slot in result) {
        expect(slot.staffUserId, equals('usr_staff_001'));
      }
    });

    test('setAvailability toggles a slot correctly', () async {
      final container = containerFor('owner');
      final slots = await container.read(schedulingNotifierProvider.future);
      final available = slots.firstWhere((s) => s.isAvailable);

      final success = await container
          .read(schedulingNotifierProvider.notifier)
          .setAvailability(available.id, isAvailable: false);

      expect(success, isTrue);

      final after = await container.read(schedulingNotifierProvider.future);
      final updated = after.firstWhere((s) => s.id == available.id);
      expect(updated.isAvailable, isFalse);
    });

    test('createSlot adds a new slot — list grows by one', () async {
      final container = containerFor('owner');
      final before = await container.read(schedulingNotifierProvider.future);
      final now = DateTime.now();

      final created = await container
          .read(schedulingNotifierProvider.notifier)
          .createSlot(
            staffUserId: 'usr_staff_001',
            startTime: now.add(const Duration(hours: 2)),
            endTime: now.add(const Duration(hours: 3)),
          );

      expect(created, isA<ScheduleSlotModel>());
      expect(created!.isAvailable, isTrue);

      final after = await container.read(schedulingNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
