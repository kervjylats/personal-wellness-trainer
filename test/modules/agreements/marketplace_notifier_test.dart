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
import 'package:personal_wellness_trainer/data/sources/mock/mock_agreements_source.dart';
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

  setUp(() {
    MockMarketplaceSource.resetForTesting();
    MockAgreementsSource.resetForTesting();
  });

  /// Puts an extra discoverable listing into the mock store so the
  /// same-job / covered-job gates have something to hide or reveal.
  Future<void> seedListing({
    required String ownerUserId,
    required String categoryId,
    required bool sameTitle,
    String? businessName,
  }) async {
    await MockMarketplaceSource().upsertListing(
      MarketplaceListing(
        id: '',
        platformId: 'platform_$ownerUserId',
        ownerUserId: ownerUserId,
        businessId: 'biz_$ownerUserId',
        businessName: businessName ?? 'Peer $categoryId',
        ownerCategoryId: categoryId,
        discoverable: true,
        openCategories: const ['yoga_studio'],
        showToSameTitle: sameTitle,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// The viewer as an open, same-job-aware shop: discoverable, opted in to
  /// the peer network, with `openSlots` as their open slots.
  ///
  /// The notifier is re-read from the container between every step: each
  /// mutation rebuilds the provider, and Riverpod refuses calls on an
  /// element whose dependencies changed underneath it. The UI never hits
  /// this because it reads the notifier fresh on every tap.
  Future<void> openShop(
    ProviderContainer container, {
    List<String> openSlots = const ['yoga_studio'],
  }) async {
    await container.read(marketplaceNotifierProvider.future);
    await container
        .read(marketplaceNotifierProvider.notifier)
        .toggleDiscoverable();
    await container.read(marketplaceNotifierProvider.future);
    await container
        .read(marketplaceNotifierProvider.notifier)
        .setShowToSameTitle(true);
    await container.read(marketplaceNotifierProvider.future);
    for (final slot in openSlots) {
      await container.read(marketplaceNotifierProvider.notifier).toggleCategory(
          categoryId: slot, lockedByAgreement: false);
      await container.read(marketplaceNotifierProvider.future);
    }
  }

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

  group('Rule 1 — same-job opt-in', () {
    test('a same-job peer appears once BOTH sides have opted in', () async {
      await seedListing(
        ownerUserId: 'usr_peer_yoga',
        categoryId: 'yoga_studio',
        sameTitle: true,
      );
      final container = ownerContainer(categoryId: 'yoga_studio');
      await openShop(container, openSlots: const ['yoga_studio']);

      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.showsToSameTitle, isTrue);
      expect(state.listings.map((l) => l.ownerUserId),
          contains('usr_peer_yoga'));
    });

    test('mutual consent: viewer opted in but peer opted out stays hidden',
        () async {
      await seedListing(
        ownerUserId: 'usr_peer_yoga',
        categoryId: 'yoga_studio',
        sameTitle: false,
      );
      final container = ownerContainer(categoryId: 'yoga_studio');
      await openShop(container, openSlots: const ['yoga_studio']);

      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.showsToSameTitle, isTrue);
      expect(state.listings.map((l) => l.ownerUserId),
          isNot(contains('usr_peer_yoga')));
    });

    test('a viewer who has not opted in cannot even open their own trade '
        'slot', () async {
      await seedListing(
        ownerUserId: 'usr_peer_yoga',
        categoryId: 'yoga_studio',
        sameTitle: true,
      );
      final container = ownerContainer(categoryId: 'yoga_studio');
      await container.read(marketplaceNotifierProvider.future);
      await container
          .read(marketplaceNotifierProvider.notifier)
          .toggleDiscoverable();
      await container.read(marketplaceNotifierProvider.future);
      await container.read(marketplaceNotifierProvider.notifier).toggleCategory(
          categoryId: 'yoga_studio', lockedByAgreement: false);

      final state = await container.read(marketplaceNotifierProvider.future);
      expect(state.showsToSameTitle, isFalse);
      expect(state.openCategories, isNot(contains('yoga_studio')));
      expect(state.listings.map((l) => l.ownerUserId),
          isNot(contains('usr_peer_yoga')));
      expect(container.read(marketplaceActionErrorProvider), isNotNull);
    });

    test('setShowToSameTitle is idempotent, not a flip', () async {
      final container = ownerContainer();
      await container.read(marketplaceNotifierProvider.future);

      await container
          .read(marketplaceNotifierProvider.notifier)
          .setShowToSameTitle(true);
      expect((await container.read(marketplaceNotifierProvider.future))
          .showsToSameTitle, isTrue);
      await container
          .read(marketplaceNotifierProvider.notifier)
          .setShowToSameTitle(true);
      expect((await container.read(marketplaceNotifierProvider.future))
          .showsToSameTitle, isTrue);
      await container
          .read(marketplaceNotifierProvider.notifier)
          .setShowToSameTitle(false);
      expect((await container.read(marketplaceNotifierProvider.future))
          .showsToSameTitle, isFalse);
    });
  });

  group('Rule 4 — jobs already covered by an active agreement', () {
    test('an active agreement closes discovery in that job', () async {
      final container = ownerContainer(categoryId: 'yoga_studio');
      await openShop(container, openSlots: const ['pilates_studio']);

      // Visible first: 'Core Pilates' (pilates_studio) matches the open slot.
      final before = await container.read(marketplaceNotifierProvider.future);
      expect(before.listings.map((l) => l.ownerCategoryId),
          contains('pilates_studio'));

      // Sign an ACTIVE agreement for that same job.
      final agreements = MockAgreementsSource();
      final proposed = await agreements.proposeAgreement(
        businessId: 'biz_mock_001',
        ownerUserId: 'usr_owner_001',
        partnerUserId: 'usr_partner_900',
        partnerBusinessId: 'biz_mock_001',
        categoryId: 'pilates_studio',
        ownerCommissionPct: 20,
        partnerCommissionPct: 80,
      );
      await agreements.approveAgreement(
          agreementId: proposed.id, businessId: 'biz_mock_001');

      container.invalidate(marketplaceNotifierProvider);
      final after = await container.read(marketplaceNotifierProvider.future);
      expect(after.jobsCoveredByAgreements, contains('pilates_studio'));
      expect(after.listings.map((l) => l.ownerCategoryId),
          isNot(contains('pilates_studio')));
    });

    test('a pending proposal does NOT close discovery', () async {
      final container = ownerContainer(categoryId: 'yoga_studio');
      await openShop(container, openSlots: const ['meditation_teacher']);

      final before = await container.read(marketplaceNotifierProvider.future);
      expect(before.listings.map((l) => l.ownerCategoryId),
          contains('meditation_teacher'));

      await MockAgreementsSource().proposeAgreement(
        businessId: 'biz_mock_001',
        ownerUserId: 'usr_owner_001',
        partnerUserId: 'usr_partner_901',
        partnerBusinessId: 'biz_mock_001',
        categoryId: 'meditation_teacher',
        ownerCommissionPct: 20,
        partnerCommissionPct: 80,
      );

      container.invalidate(marketplaceNotifierProvider);
      final after = await container.read(marketplaceNotifierProvider.future);
      expect(after.jobsCoveredByAgreements,
          isNot(contains('meditation_teacher')));
      expect(after.listings.map((l) => l.ownerCategoryId),
          contains('meditation_teacher'));
    });

    test('the seeded active agreement counts, the seeded pending one does '
        'not', () async {
      final container = ownerContainer();
      final state = await container.read(marketplaceNotifierProvider.future);
      // agr_mock_001 — active, categoryId 'cat_2'
      // agr_mock_002 — proposed, categoryId 'cat_3'
      expect(state.jobsCoveredByAgreements, contains('cat_2'));
      expect(state.jobsCoveredByAgreements, isNot(contains('cat_3')));
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

    test('a category the owner is not advertising is rejected', () async {
      final container = ownerContainer(categoryId: 'yoga_studio');
      final notifier = container.read(marketplaceNotifierProvider.notifier);
      await container.read(marketplaceNotifierProvider.future);

      final result = await notifier.sendRequest(
        listing: MarketplaceListing(
          id: 'mkt_test_99',
          platformId: 'plat_99',
          ownerUserId: 'usr_owner_ext_999',
          businessId: 'biz_test_999',
          businessName: 'Quiet Co',
          ownerCategoryId: 'pilates_studio',
          discoverable: true,
          openCategories: const ['yoga_studio'],
          updatedAt: DateTime.now(),
        ),
        requestedCategoryId: 'reiki_practitioner',
      );
      expect(result, isNull);
      expect(container.read(marketplaceActionErrorProvider),
          contains('not seeking a partner'));
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