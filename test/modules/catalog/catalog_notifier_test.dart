// test/modules/catalog/catalog_notifier_test.dart
//
// Tests for CatalogNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/catalog/catalog_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/catalog/providers/catalog_notifier.dart';

void main() {
  group('CatalogNotifier', () {
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

    test('owner receives all catalog items including inactive', () async {
      final container = containerFor('owner');
      final result = await container.read(catalogNotifierProvider.future);
      expect(result, isNotEmpty);
      // Seed data has an inactive item — owner should see it.
      expect(result.any((c) => !c.isActive), isTrue);
    });

    test('client receives only active catalog items', () async {
      final container = containerFor('client');
      final result = await container.read(catalogNotifierProvider.future);
      for (final item in result) {
        expect(item.isActive, isTrue);
      }
    });

    test('create adds a new item — list grows by one', () async {
      final container = containerFor('owner');
      final before = await container.read(catalogNotifierProvider.future);

      final created = await container
          .read(catalogNotifierProvider.notifier)
          .create(
            title: 'New Item',
            price: 75.00,
            currency: r'$',
          );

      expect(created, isA<CatalogItemModel>());
      expect(created!.title, equals('New Item'));

      final after = await container.read(catalogNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('edit changes the price of a catalog item', () async {
      final container = containerFor('owner');
      final items = await container.read(catalogNotifierProvider.future);
      final target = items.first;

      final updated = await container
          .read(catalogNotifierProvider.notifier)
          .edit(catalogItemId: target.id, price: 999.00);

      expect(updated, isA<CatalogItemModel>());
      expect(updated!.price, equals(999.00));
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
