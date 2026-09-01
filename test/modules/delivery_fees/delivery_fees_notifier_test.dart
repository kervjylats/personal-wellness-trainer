// test/modules/delivery_fees/delivery_fees_notifier_test.dart
//
// Tests for DeliveryFeesNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/delivery_fees/delivery_fees_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/delivery_fee_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/delivery_fees/providers/delivery_fees_notifier.dart';

void main() {
  group('DeliveryFeesNotifier', () {
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

    test('owner receives all zones including inactive', () async {
      final container = containerFor('owner');
      final result =
          await container.read(deliveryFeesNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.any((f) => !f.isActive), isTrue);
    });

    test('staff receives only active zones', () async {
      final container = containerFor('staff');
      final result =
          await container.read(deliveryFeesNotifierProvider.future);
      for (final fee in result) {
        expect(fee.isActive, isTrue);
      }
    });

    test('create adds a new zone — list grows by one', () async {
      final container = containerFor('owner');
      final before =
          await container.read(deliveryFeesNotifierProvider.future);

      final created = await container
          .read(deliveryFeesNotifierProvider.notifier)
          .create(
            zoneLabel: 'Test Zone',
            minDistanceKm: 20.0,
            maxDistanceKm: 30.0,
            fee: 12.00,
            currency: r'$',
          );

      expect(created, isA<DeliveryFeeModel>());
      expect(created!.zoneLabel, equals('Test Zone'));

      final after =
          await container.read(deliveryFeesNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('calculateFee returns correct fee for known distance', () async {
      final container = containerFor('owner');
      // Seed zone 'Local' covers 0–5km at \$3.00
      final fee = await container
          .read(deliveryFeesNotifierProvider.notifier)
          .calculateFee(3.0);

      expect(fee, equals(3.00));
    });

    test('calculateFee returns null when no zone covers the distance',
        () async {
      final container = containerFor('owner');
      // Seed has no active zone beyond 15km
      final fee = await container
          .read(deliveryFeesNotifierProvider.notifier)
          .calculateFee(100.0);

      expect(fee, isNull);
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
