// lib/modules/agreements/providers/marketplace_notifier.dart
//
// Riverpod state management for the Partnership Marketplace.
//
// Handles: discoverable toggle, per-category toggles, send/accept/decline requests.
// Accepting a request routes to the existing Phase 4 agreement flow.
//
// Blueprint §18 Hardcoded Rules enforced here (never in the UI):
//   Rule 1: Same-category owners are hidden from each other unless BOTH
//           listings opted in to the same-job peer network.
//   Rule 2: Filled slots auto-locked — openCategories excludes active agreements.
//   Rule 3: Master toggle gates all category toggles.
//   Rule 4: Jobs the viewer already holds an ACTIVE agreement for are
//           excluded from discovery entirely.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/data/repositories/agreements_repository.dart';
import 'package:personal_wellness_trainer/data/repositories/marketplace_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_agreements_source.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_marketplace_source.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_agreements_source.dart';
import 'package:personal_wellness_trainer/data/sources/supabase/supabase_marketplace_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';

final marketplaceActionErrorProvider = StateProvider<String?>((ref) => null);

final _marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  if (DataConfig.useMockData) return MockMarketplaceSource();
  return SupabaseMarketplaceSource();
});

/// Read-only, for Rule 4's covered-jobs set. Deliberately its own instance
/// rather than a watch on agreementsNotifierProvider — see the note in
/// MarketplaceNotifier.build().
final _marketplaceAgreementsRepositoryProvider =
    Provider<AgreementsRepository>((ref) {
  if (DataConfig.useMockData) return MockAgreementsSource();
  return SupabaseAgreementsSource();
});

class MarketplaceState {
  const MarketplaceState({
    this.myListing,
    this.listings = const [],
    this.sentRequests = const [],
    this.receivedRequests = const [],
    this.coveredCategories = const {},
    this.isLoading = false,
  });

  final MarketplaceListing? myListing;
  final List<MarketplaceListing> listings;
  final List<PartnershipRequest> sentRequests;
  final List<PartnershipRequest> receivedRequests;
  final Set<String> coveredCategories;
  final bool isLoading;

  bool get isDiscoverable => myListing?.discoverable ?? false;
  List<String> get openCategories =>
      myListing?.openCategories ?? const [];

  /// Whether this owner opted in to the same-job peer network.
  bool get showsToSameTitle => myListing?.showToSameTitle ?? false;

  /// Jobs this owner already has an ACTIVE agreement for — discovery is
  /// closed in all of them (Rule 4), mirroring the locked slots in Rule 2.
  Set<String> get jobsCoveredByAgreements => coveredCategories;

  int get pendingReceivedCount =>
      receivedRequests.where((r) => r.isPending).length;

  MarketplaceState copyWith({
    MarketplaceListing? myListing,
    List<MarketplaceListing>? listings,
    List<PartnershipRequest>? sentRequests,
    List<PartnershipRequest>? receivedRequests,
    Set<String>? coveredCategories,
    bool? isLoading,
  }) {
    return MarketplaceState(
      myListing: myListing ?? this.myListing,
      listings: listings ?? this.listings,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      coveredCategories: coveredCategories ?? this.coveredCategories,
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

  AgreementsRepository get _agreementsRepository =>
      ref.read(_marketplaceAgreementsRepositoryProvider);

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

    // Read straight from the agreements repository rather than watching
    // agreementsNotifierProvider: watching it here is a Riverpod trap — the
    // provider would have to be declared in `dependencies:` (any watched
    // provider must be), and an AsyncNotifier declaring AND watching another
    // AsyncNotifier deadlocks: its first value never emits. Refreshes are
    // explicit instead (see the invalidate calls after accept/approve).
    final agreements =
        await _agreementsRepository.getAgreements(auth.profile.businessId);
    final covered = _jobsCoveredBy(agreements, auth.profile.userId);

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
        viewerShowsToSameTitle: myListing.showToSameTitle,
        coveredCategories: covered,
      );
    }

    return MarketplaceState(
      myListing: myListing,
      listings: listings,
      sentRequests: sent,
      receivedRequests: received,
      coveredCategories: covered,
    );
  }

  /// Rule 4: every job this owner holds an ACTIVE agreement for.
  ///
  /// An agreement row's `categoryId` is always the OTHER party's job — the
  /// invite flow stores the invitee's category and a marketplace collab
  /// writes two mirrored rows with swapped categories — so a plain map over
  /// the active rows yields exactly "jobs I am already covered for". Pending
  /// ('proposed') rows are deliberately excluded: a deal not yet signed off
  /// shouldn't hide anybody.
  Set<String> _jobsCoveredBy(
      List<AgreementModel> agreements, String userId) {
    return agreements
        .where((a) =>
            a.isActive && (a.ownerUserId == userId || a.partnerUserId == userId))
        .map((a) => a.categoryId)
        .toSet();
  }

  // ── Toggle discoverable ──────────────────────────────────────────────────
  Future<void> toggleDiscoverable() async {
    ref.read(marketplaceActionErrorProvider.notifier).state = null;
    final current = state.valueOrNull;
    if (current == null) return;

    final wasDiscoverable = current.isDiscoverable;
    final newDiscoverable = !wasDiscoverable;

    try {
      final listing = await _upsertListing(
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
    // Your own trade is a valid slot only behind the same-job opt-in
    // (Rule 1). The AvailabilityCard greys it out; enforced here too so the
    // rule can't be bypassed by any other caller.
    if (categoryId == (current.myListing?.ownerCategoryId ?? '') &&
        !current.showsToSameTitle) {
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Turn on "Visible to owners with the same job" before offering your '
          'own trade.';
      return;
    }

    final openCats = List<String>.from(current.openCategories);
    if (openCats.contains(categoryId)) {
      openCats.remove(categoryId);
    } else {
      openCats.add(categoryId);
    }

    try {
      final listing = await _upsertListing(
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

  // ── Same-job peer network (Rule 1) ───────────────────────────────────────
  /// Sets the "visible to owners with the same job" preference. A setter,
  /// not a flip — the UI already shows the current value, and flipping
  /// would make the switch lie whenever a write lands out of order.
  Future<void> setShowToSameTitle(bool value) async {
    ref.read(marketplaceActionErrorProvider.notifier).state = null;
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.showsToSameTitle == value) return;

    final mpConfig = ref.watch(configProvider).valueOrNull
        ?.industry.partnershipMarketplace;
    if (mpConfig != null && !mpConfig.sameTitleVisibilityOwnerCanToggle) {
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Same-job visibility is set by the platform and cannot be changed.';
      return;
    }

    try {
      final listing = await _upsertListing(
        current: current,
        discoverable: current.isDiscoverable,
        openCategories: current.openCategories,
        showToSameTitle: value,
      );
      final listings = await _fetchListings(listing);
      state = AsyncData(
        current.copyWith(myListing: listing, listings: listings),
      );
    } catch (e, st) {
      AppLogger.error('setShowToSameTitle failed', tag: _tag, error: e, stackTrace: st);
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'Could not update same-job visibility. Please try again.';
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

    // The slot must actually be one this owner advertises — the category
    // chips come from listing.openCategories, but that is a UI courtesy, not
    // a guarantee, and an unadvertised slot would create an agreement the
    // other side never agreed to.
    if (!listing.openCategories.contains(requestedCategoryId)) {
      ref.read(marketplaceActionErrorProvider.notifier).state =
          'That owner is not seeking a partner in this category right now.';
      return null;
    }

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

  Future<MarketplaceListing> _upsertListing({
    required MarketplaceState current,
    required bool discoverable,
    required List<String> openCategories,
    bool? showToSameTitle,
  }) async {
    final existing = current.myListing;
    final now = DateTime.now();
    // A brand-new listing starts from the platform's configured default so
    // a buyer can open the same-job network platform-wide without a code
    // change; an existing listing keeps whatever the owner last chose.
    final sameTitle = showToSameTitle ??
        existing?.showToSameTitle ??
        (ref.watch(configProvider).valueOrNull?.industry.partnershipMarketplace
                ?.sameTitleVisibilityDefault ??
            false);
    final listing = existing != null
        ? existing.copyWith(
            discoverable: discoverable,
            openCategories: openCategories,
            showToSameTitle: sameTitle,
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
            showToSameTitle: sameTitle,
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
      viewerShowsToSameTitle: myListing.showToSameTitle,
      coveredCategories: state.valueOrNull?.coveredCategories ?? const {},
    );
  }
}
