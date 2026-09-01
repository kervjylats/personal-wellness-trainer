// test/modules/agreements/marketplace_notifier_test.dart
//
// Tests for MarketplaceNotifier — Phase 4b Partnership Marketplace.
//
// Always call `await container.read(marketplaceNotifierProvider.future)`
// before any notifier method call.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_marketplace_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/marketplace_notifier.dart';
import '../../helpers/fake_config.dart';

void main() {
  ProviderContainer ownerContainer({String categoryId = 'yoga_studio'}) {
    final profile = UserProfile(
      userId: 'usr_owner_001',
      businessId: 'biz_mock_001',
      role: 'owner',
      displayName: 'Test Owner',
      joinedAt: DateTime(2025),
      isActive: true,
      categoryId: categoryId,
    );
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(profile)),
        ...fakeEngineOverrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(MockMarketplaceSource.resetForTesting);

  group('MarketplaceNotifier — build', () {
    test('loads state for authenticated owner', () async {
      final container = ownerContainer();
      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.myListing, isNotNull);
    });

    test('seed listing starts with discoverable OFF', () async {
      final container = ownerContainer();
      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.isDiscoverable, isFalse);
    });

    test('has one pending received request', () async {
      final container = ownerContainer();
      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.receivedRequests.where((r) => r.isPending).length, 1);
    });
  });

  group('Rule 1 — same‑category filtering', () {
    test('same category never appears in discovery', () async {
      final container = ownerContainer(categoryId: 'yoga_studio');
      final notifier = container.read(marketplaceNotifierProvider.notifier);
      await container.read(marketplaceNotifierProvider.future);
      await notifier.toggleDiscoverable();
      await container.read(marketplaceNotifierProvider.future);
      await notifier.toggleCategory(
          categoryId: 'pilates_studio', lockedByAgreement: false);
      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.listings.isNotEmpty, true);
      for (final listing in state.listings) {
        expect(listing.ownerCategoryId, isNot('yoga_studio'));
      }
    });
  });

  group('Partnership Requests', () {
    test('sending a request is successful', () async {
      final container = ownerContainer(categoryId: 'yoga_studio');
      final notifier = container.read(marketplaceNotifierProvider.notifier);
      await container.read(marketplaceNotifierProvider.future);

      final result = await notifier.sendRequest(
        listing: MarketplaceListing(
          id: 'mkt_test_98',
          platformId: 'plat_98',
          ownerUserId: 'usr_owner_ext_998',
          businessId: 'biz_test_998',
          businessName: 'Compatible Co',
          ownerCategoryId: 'pilates_studio',
          discoverable: true,
          openCategories: const ['yoga_studio'],
          updatedAt: DateTime.now(),
        ),
        requestedCategoryId: 'yoga_studio',
      );
      expect(result, isA<PartnershipRequest>());
    });
  });

  group('Accept / decline', () {
    test('accept returns accepted request', () async {
      final container = ownerContainer();
      final notifier = container.read(marketplaceNotifierProvider.notifier);
      final state = await container.read(marketplaceNotifierProvider.future);
      final pending =
          state.receivedRequests.firstWhere((r) => r.isPending);
      final accepted = await notifier.acceptRequest(pending.id);
      expect(accepted!.isAccepted, isTrue);
    });

    test('decline updates status', () async {
      final container = ownerContainer();
      final notifier = container.read(marketplaceNotifierProvider.notifier);
      final state = await container.read(marketplaceNotifierProvider.future);
      final pending =
          state.receivedRequests.firstWhere((r) => r.isPending);
      final ok = await notifier.declineRequest(pending.id);
      expect(ok, isTrue);
      final after = await container.read(marketplaceNotifierProvider.future);
      final updated =
          after.receivedRequests.firstWhere((r) => r.id == pending.id);
      expect(updated.isDeclined, isTrue);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._profile);
  final UserProfile _profile;
  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}