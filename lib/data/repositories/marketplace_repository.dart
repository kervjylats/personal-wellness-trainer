// lib/data/repositories/marketplace_repository.dart
//
// Abstract interface for all marketplace data operations.
// MockMarketplaceSource implements this for Phases 1–9.
// SupabaseMarketplaceSource will implement it in Phase 10.
//
// The marketplace notifier talks ONLY to this interface — never to a
// concrete source directly. This is the Repository pattern (Blueprint §13).
//
// Note on RLS (Phase 10):
//   marketplace_listings: cross-tenant reads allowed by platform_id.
//     Writes only by listing's own owner.
//   partnership_requests: sender and receiver can read their own requests.

import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';

abstract class MarketplaceRepository {
  Future<MarketplaceListing?> getMyListing(String ownerUserId);

  Future<MarketplaceListing> upsertListing(MarketplaceListing listing);

  Future<List<MarketplaceListing>> getDiscoverableListings({
    required String viewerOwnerUserId,
    required String viewerCategoryId,
    required List<String> desiredCategories,
  });

  Future<List<PartnershipRequest>> getSentRequests(String senderOwnerUserId);

  Future<List<PartnershipRequest>> getReceivedRequests(
    String receiverOwnerUserId,
  );

  Future<PartnershipRequest> sendRequest({
    required String senderOwnerUserId,
    required String receiverOwnerUserId,
    required String senderBusinessId,
    required String senderBusinessName,
    required String senderCategoryId,
    required String receiverCategoryId,
    String? message,
  });

  Future<PartnershipRequest> respondToRequest({
    required String requestId,
    required String newStatus,
  });
}

class DuplicateMarketplaceRequestException implements Exception {
  const DuplicateMarketplaceRequestException(this.receiverOwnerUserId);
  final String receiverOwnerUserId;

  @override
  String toString() =>
      'DuplicateMarketplaceRequestException: a request to '
      '"$receiverOwnerUserId" already exists.';
}