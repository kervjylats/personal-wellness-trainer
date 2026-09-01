// lib/modules/agreements/providers/marketplace_notifier.dart
//
// Riverpod state management for the Partnership Marketplace.
//
// Handles: discoverable toggle, per-category toggles, send/accept/decline requests.
// Accepting a request routes to the existing Phase 4 agreement flow.
//
// Blueprint §18 Hardcoded Rules enforced here (never in the UI):
//   Rule 1: Same-category owners NEVER appear in each other's results.
//   Rule 2: Filled slots auto-locked — openCategories excludes active agreements.
//   Rule 3: Master toggle gates all category toggles.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/data/repositories/marketplace_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_marketplace_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final marketplaceActionErrorProvider = StateProvider<String?>((ref) => null);

final _marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  if (DataConfig.useMockData) return MockMarketplaceSource();
  throw UnimplementedError('Supabase marketplace source — Phase 10 only.');
});

class MarketplaceState {
  const MarketplaceState({
    this.myListing,
    this.listings = const [],
    this.sentRequests = const [],
    this.receivedRequests = const [],
    this.isLoading = false,
  });

  final MarketplaceListing? myListing;
  final List<MarketplaceListing> listings;
  final List<PartnershipRequest> sentRequests;
  final List<PartnershipRequest> receivedRequests;
  final bool isLoading;

  bool get isDiscoverable => myListing?.discoverable ?? false;
  List<String> get openCategories =>
      myListing?.openCategories ?? const [];
  int get pendingReceivedCount =>
      receivedRequests.where((r) => r.isPending).length;

  MarketplaceState copyWith({
    MarketplaceListing? myListing,
    List<MarketplaceListing>? listings,
    List<PartnershipRequest>? sentRequests,
    List<PartnershipRequest>? receivedRequests,
    bool? isLoading,
  }) {
    return MarketplaceState(
      myListing: myListing ?? this.myListing,
      listings: listings ?? this.listings,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final marketplaceNotifierProvider =
    AsyncNotifierProvider<MarketplaceNotifier, MarketplaceState>(
  MarketplaceNotifier.new,
  dependencies: [authNotifierProvider],
);

class MarketplaceNotifier extends AsyncNotifier<MarketplaceState> {
  static const String _tag = 'MarketplaceNotifier';

  MarketplaceRepository get _repo =>
      ref.read(_marketplaceRepositoryProvider);

  AuthAuthenticated get _auth {
    final auth = ref.read(authNotifierProvider);
    if (auth is AuthAuthenticated) return auth;
    throw StateError('MarketplaceNotifier accessed without authenticated user.');
  }

  String get _ownerUserId => _auth.profile.userId;
  String get _businessId => _auth.profile.businessId;
  String get _businessName =>
      _auth.profile.businessName ?? _auth.profile.displayName;
  String get _ownerCategoryId => _auth.profile.categoryId ?? '';

  @override
  Future<MarketplaceState> build() async {
    final auth = ref.watch(authNotifierProvider);
    if (auth is! AuthAuthenticated) return const MarketplaceState();

    final myListing = await _repo.getMyListing(auth.profile.userId);
    final sent = await _repo.getSentRequests(auth.profile.userId);
    final received = await _repo.getReceivedRequests(auth.profile.userId);

    List<MarketplaceListing> listings = const [];
    if (myListing != null &&
        myListing.discoverable &&
        myListing.openCategories.isNotEmpty) {
      listings = await _repo.getDiscoverableListings(
        viewerOwnerUserId: auth.profile.userId,
        viewerCategoryId: myListing.ownerCategoryId,
        desiredCategories: myListing.openCategories,
      );
    }

    return MarketplaceState(
      myListing: myListing,
      listings: listings,
      sentRequests: sent,
      receivedRequests: received,
    );
  }

  // ── Toggle discoverable ──────────────────────────────────────────────────
  Future<void> toggleDiscoverable() async {
    ref.read(marketplaceActionErrorProvider.notifier).state = null;
    final current = state.valueOrNull;
    if (current == null) return;

    final wasDiscoverable = current.isDiscoverable;
    final newDiscoverable = !wasDiscoverable;

    try {
      final listing = await _upsertWithDiscoverable(
        current: current,
        discoverable: newDiscoverable,
        openCategories:
            newDiscoverable ? current.openCategories : const [],
      );

      List<MarketplaceListing> listings = current.listings;
      if (newDiscoverable && listing.openCategories.isNotEmpty) {
        listings = await _fetchListings(listing);
      } else if (!newDiscoverable) {
        listings = const [];
      }

      state = AsyncData(
        current.copyWith(myListing: listing, listings: listings),
      );
    } catch (e, st) {
      AppLogger.error('toggleDiscoverable failed', tag: _tag, error: e, stackTrace: st);
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Could not update availability. Please try again.';
    }
  }

  // ── Toggle category ──────────────────────────────────────────────────────
  Future<void> toggleCategory({
    required String categoryId,
    required bool lockedByAgreement,
  }) async {
    ref.read(marketplaceActionErrorProvider.notifier).state = null;
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.isDiscoverable) return;
    if (lockedByAgreement) return;

    final openCats = List<String>.from(current.openCategories);
    if (openCats.contains(categoryId)) {
      openCats.remove(categoryId);
    } else {
      openCats.add(categoryId);
    }

    try {
      final listing = await _upsertWithDiscoverable(
        current: current,
        discoverable: true,
        openCategories: openCats,
      );
      final listings = await _fetchListings(listing);
      state = AsyncData(
        current.copyWith(myListing: listing, listings: listings),
      );
    } catch (e, st) {
      AppLogger.error('toggleCategory failed', tag: _tag, error: e, stackTrace: st);
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Could not update category availability. Please try again.';
    }
  }

  // ── Send request ─────────────────────────────────────────────────────────
  Future<PartnershipRequest?> sendRequest({
    required MarketplaceListing listing,
    required String requestedCategoryId,
    String? message,
  }) async {
    ref.read(marketplaceActionErrorProvider.notifier).state = null;
    final current = state.valueOrNull;
    if (current == null) return null;

    final alreadySent = current.sentRequests.any(
      (r) =>
          r.receiverOwnerUserId == listing.ownerUserId &&
          r.receiverCategoryId == requestedCategoryId &&
          r.isPending,
    );
    if (alreadySent) {
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'A pending request to this owner already exists.';
      return null;
    }

    try {
      final request = await _repo.sendRequest(
        senderOwnerUserId: _ownerUserId,
        receiverOwnerUserId: listing.ownerUserId,
        senderBusinessId: _businessId,
        senderBusinessName: _businessName,
        senderCategoryId: _ownerCategoryId,
        receiverCategoryId: requestedCategoryId,
        message: message,
      );
      state = AsyncData(
        current.copyWith(
          sentRequests: [request, ...current.sentRequests],
        ),
      );
      return request;
    } catch (e, st) {
      AppLogger.error('sendRequest failed', tag: _tag, error: e, stackTrace: st);
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Could not send request. Please try again.';
      return null;
    }
  }

  // ── Accept / decline ─────────────────────────────────────────────────────
  Future<PartnershipRequest?> acceptRequest(String requestId) async {
    return _respondToRequest(requestId: requestId, newStatus: 'accepted');
  }

  Future<bool> declineRequest(String requestId) async {
    final result =
        await _respondToRequest(requestId: requestId, newStatus: 'declined');
    return result != null;
  }

  // ── Private helpers ──────────────────────────────────────────────────────
  Future<PartnershipRequest?> _respondToRequest({
    required String requestId,
    required String newStatus,
  }) async {
    ref.read(marketplaceActionErrorProvider.notifier).state = null;
    final current = state.valueOrNull;
    if (current == null) return null;

    try {
      final updated = await _repo.respondToRequest(
        requestId: requestId,
        newStatus: newStatus,
      );

      final updatedList = [
        for (final r in current.receivedRequests)
          if (r.id == requestId) updated else r,
      ];

      state = AsyncData(current.copyWith(receivedRequests: updatedList));
      return updated;
    } catch (e, st) {
      AppLogger.error('respondToRequest failed', tag: _tag, error: e, stackTrace: st);
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Could not respond to request. Please try again.';
      return null;
    }
  }

  Future<MarketplaceListing> _upsertWithDiscoverable({
    required MarketplaceState current,
    required bool discoverable,
    required List<String> openCategories,
  }) async {
    final existing = current.myListing;
    final now = DateTime.now();
    final listing = existing != null
        ? existing.copyWith(
            discoverable: discoverable,
            openCategories: openCategories,
            updatedAt: now,
          )
        : MarketplaceListing(
            id: '',
            platformId: 'platform_${_ownerUserId.hashCode.abs()}',
            ownerUserId: _ownerUserId,
            businessId: _businessId,
            businessName: _businessName,
            ownerCategoryId: _ownerCategoryId,
            discoverable: discoverable,
            openCategories: openCategories,
            updatedAt: now,
          );
    return _repo.upsertListing(listing);
  }

  Future<List<MarketplaceListing>> _fetchListings(
      MarketplaceListing myListing) async {
    if (!myListing.discoverable || myListing.openCategories.isEmpty) {
      return const [];
    }
    return _repo.getDiscoverableListings(
      viewerOwnerUserId: _ownerUserId,
      viewerCategoryId: myListing.ownerCategoryId,
      desiredCategories: myListing.openCategories,
    );
  }
}
