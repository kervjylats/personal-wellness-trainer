// lib/data/sources/mock/mock_marketplace_source.dart
//
// Mock data source for the Partnership Marketplace (Phase 4b).
//
// Simulates cross-business discovery — the ONLY source in the mock layer that
// intentionally shows data from "other businesses" (different platform_ids).
// This is by design: Blueprint §18 uses platform_id for cross-tenant visibility.
//
// ⚠️  ZERO industry-specific words.
//     No 'gym', 'trainer', 'driver', 'salon', 'restaurant', etc.
//     All category references come from config IDs (yoga_studio, pilates_studio, …).
//
// Filtering rules enforced here (Blueprint §18 Hardcoded Rules):
//   Rule 1: Same-category owners NEVER appear in each other's results.
//   Rule 2: Filled category slots (active agreement exists) are auto-locked.
//   Rule 3: Only discoverable owners with openCategories are listed.
//
// Compatibility checking is NOT done here — done in MarketplaceNotifier
// before any request is sent, keeping this source dumb.
//
// Seed data: 5 mock "other owners" on the platform, each with different
// ownerCategoryId values, so the filtering rules are exercised.

import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/data/repositories/marketplace_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockMarketplaceSource with MockSourceMixin implements MarketplaceRepository {
  static List<MarketplaceListing> _listings = _buildSeedListings();
  static List<PartnershipRequest> _requests = _buildSeedRequests();
  static int _listingIdCounter = 100;
  static int _requestIdCounter = 100;

  static void resetForTesting() {
    _listings = _buildSeedListings();
    _requests = _buildSeedRequests();
    _listingIdCounter = 100;
    _requestIdCounter = 100;
  }

  @override
  Future<MarketplaceListing?> getMyListing(String ownerUserId) async {
    await simulateNetworkDelay();
    try {
      return _listings.firstWhere((l) => l.ownerUserId == ownerUserId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MarketplaceListing> upsertListing(MarketplaceListing listing) async {
    await simulateNetworkDelay();

    final index = _listings.indexWhere(
      (l) => l.ownerUserId == listing.ownerUserId,
    );

    if (index == -1) {
      _listingIdCounter++;
      final newListing = listing.copyWith(
        id: 'mkt_mock_${_listingIdCounter.toString().padLeft(3, '0')}',
        updatedAt: DateTime.now(),
      );
      _listings.add(newListing);
      return newListing;
    } else {
      final updated = listing.copyWith(updatedAt: DateTime.now());
      _listings[index] = updated;
      return updated;
    }
  }

  @override
  Future<List<MarketplaceListing>> getDiscoverableListings({
    required String viewerOwnerUserId,
    required String viewerCategoryId,
    required List<String> desiredCategories,
  }) async {
    await simulateNetworkDelay();

    return _listings.where((listing) {
      if (listing.ownerUserId == viewerOwnerUserId) return false;
      if (listing.ownerCategoryId == viewerCategoryId) return false;
      if (!listing.discoverable) return false;
      if (desiredCategories.isEmpty) return false;
      if (!desiredCategories.contains(listing.ownerCategoryId)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<PartnershipRequest>> getSentRequests(
      String senderOwnerUserId) async {
    await simulateNetworkDelay();
    return _requests
        .where((r) => r.senderOwnerUserId == senderOwnerUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<PartnershipRequest>> getReceivedRequests(
      String receiverOwnerUserId) async {
    await simulateNetworkDelay();
    return _requests
        .where((r) => r.receiverOwnerUserId == receiverOwnerUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<PartnershipRequest> sendRequest({
    required String senderOwnerUserId,
    required String receiverOwnerUserId,
    required String senderBusinessId,
    required String senderBusinessName,
    required String senderCategoryId,
    required String receiverCategoryId,
    String? message,
  }) async {
    await simulateNetworkDelay();

    _requestIdCounter++;
    final request = PartnershipRequest(
      id: 'req_mock_${_requestIdCounter.toString().padLeft(3, '0')}',
      senderOwnerUserId: senderOwnerUserId,
      receiverOwnerUserId: receiverOwnerUserId,
      senderBusinessId: senderBusinessId,
      senderBusinessName: senderBusinessName,
      senderCategoryId: senderCategoryId,
      receiverCategoryId: receiverCategoryId,
      status: 'pending',
      createdAt: DateTime.now(),
      message: message,
    );
    _requests.add(request);
    return request;
  }

  @override
  Future<PartnershipRequest> respondToRequest({
    required String requestId,
    required String newStatus,
  }) async {
    await simulateNetworkDelay();

    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) throw Exception('Request $requestId not found');

    final updated = _requests[index].copyWith(
      status: newStatus,
      respondedAt: DateTime.now(),
    );
    _requests[index] = updated;
    return updated;
  }

  static List<MarketplaceListing> _buildSeedListings() {
    final now = DateTime.now();
    return [
      // Viewer's own listing — discoverable OFF by default
      MarketplaceListing(
        id: 'mkt_mock_001',
        platformId: 'platform_001',
        ownerUserId: 'usr_owner_001',
        businessId: 'biz_mock_001',
        businessName: 'Main Test Studio',
        ownerCategoryId: 'yoga_studio',
        discoverable: false,
        openCategories: const [],
        updatedAt: now.subtract(const Duration(days: 30)),
        tagline: 'Professional yoga classes for all levels.',
      ),
      // Pilates studio, discoverable, open for yoga and meditation
      MarketplaceListing(
        id: 'mkt_mock_002',
        platformId: 'platform_002',
        ownerUserId: 'usr_owner_ext_001',
        businessId: 'biz_ext_001',
        businessName: 'Core Pilates',
        ownerCategoryId: 'pilates_studio',
        discoverable: true,
        openCategories: const ['yoga_studio', 'meditation_teacher'],
        updatedAt: now.subtract(const Duration(days: 2)),
        tagline: 'Strengthen your core, lengthen your spine.',
        averageRating: 4.7,
      ),
      // Meditation teacher, discoverable, open for yoga and reiki
      MarketplaceListing(
        id: 'mkt_mock_003',
        platformId: 'platform_003',
        ownerUserId: 'usr_owner_ext_002',
        businessId: 'biz_ext_002',
        businessName: 'Mindful Moments',
        ownerCategoryId: 'meditation_teacher',
        discoverable: true,
        openCategories: const ['yoga_studio', 'reiki_practitioner'],
        updatedAt: now.subtract(const Duration(days: 5)),
        tagline: 'Guided meditations for inner peace.',
        averageRating: 4.2,
      ),
      // Nutritionist, discoverable OFF
      MarketplaceListing(
        id: 'mkt_mock_004',
        platformId: 'platform_004',
        ownerUserId: 'usr_owner_ext_003',
        businessId: 'biz_ext_003',
        businessName: 'Nourish With Care',
        ownerCategoryId: 'nutritionist',
        discoverable: false,
        openCategories: const ['yoga_studio'],
        updatedAt: now.subtract(const Duration(days: 10)),
        tagline: 'Personalised meal plans and nutrition coaching.',
      ),
      // Gym coach, discoverable, open for strength coach
      MarketplaceListing(
        id: 'mkt_mock_005',
        platformId: 'platform_005',
        ownerUserId: 'usr_owner_ext_004',
        businessId: 'biz_ext_004',
        businessName: 'Iron Forge Gym',
        ownerCategoryId: 'gym_coach',
        discoverable: true,
        openCategories: const ['strength_coach', 'yoga_studio'],
        updatedAt: now.subtract(const Duration(days: 1)),
        tagline: 'Transform your body, transform your life.',
        averageRating: 4.9,
      ),
    ];
  }

  static List<PartnershipRequest> _buildSeedRequests() {
    return [
      PartnershipRequest(
        id: 'req_mock_001',
        senderOwnerUserId: 'usr_owner_ext_001',
        receiverOwnerUserId: 'usr_owner_001',
        senderBusinessId: 'biz_ext_001',
        senderBusinessName: 'Core Pilates',
        senderCategoryId: 'pilates_studio',
        receiverCategoryId: 'yoga_studio',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        message: 'Hi — we think a partnership would be fantastic!',
      ),
    ];
  }
}