// test/modules/inventory/inventory_notifier_test.dart
//
// Tests for InventoryNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/inventory/inventory_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/inventory_item_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/inventory/providers/inventory_notifier.dart';

void main() {
  group('InventoryNotifier', () {
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
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(profile),
          ),
          buildConfigProvider.overrideWithValue(fakeEngineConfig.build),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build returns inventory list', () async {
      final container = ownerContainer();
      final result = await container.read(inventoryNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<InventoryItemModel>());
    });

    test('seed data has at least one low-stock item', () async {
      final container = ownerContainer();
      final result = await container.read(inventoryNotifierProvider.future);
      expect(result.any((i) => i.isLowStock), isTrue);
    });

    test('adjustStock increases stockCount by delta', () async {
      final container = ownerContainer();
      final items = await container.read(inventoryNotifierProvider.future);
      final target = items.first;
      final originalCount = target.stockCount;

      final success = await container
          .read(inventoryNotifierProvider.notifier)
          .adjustStock(target.id, 10);

      expect(success, isTrue);

      final after = await container.read(inventoryNotifierProvider.future);
      final updated = after.firstWhere((i) => i.id == target.id);
      expect(updated.stockCount, equals(originalCount + 10));
    });

    test('adjustStock never goes below zero', () async {
      final container = ownerContainer();
      final items = await container.read(inventoryNotifierProvider.future);
      final target = items.first;

      await container
          .read(inventoryNotifierProvider.notifier)
          .adjustStock(target.id, -99999);

      final after = await container.read(inventoryNotifierProvider.future);
      final updated = after.firstWhere((i) => i.id == target.id);
      expect(updated.stockCount, greaterThanOrEqualTo(0));
    });

    test('availableCount computed correctly', () async {
      final container = ownerContainer();
      final items = await container.read(inventoryNotifierProvider.future);
      for (final item in items) {
        expect(
          item.availableCount,
          equals(item.stockCount - item.reservedCount),
        );
      }
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
