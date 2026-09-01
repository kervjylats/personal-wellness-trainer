// lib/modules/discover/providers/partner_offers_provider.dart
//
// Cross-tenant reads for the client-facing "From Our Partners" section.
// Everything else in the app reads only the CURRENT user's own
// business_id — this file is the one deliberate exception, mirroring
// MarketplaceListing's role as "the only table designed for cross-tenant
// visibility" (see marketplace_listing.dart). An AgreementModel's
// partnerBusinessId is what makes this safe and well-scoped: a client
// only ever sees a specific OTHER business's catalog, filtered to the
// exact category their own coach has an active agreement for — never a
// general cross-tenant browse.
//
// In Phase 10, getActiveCatalogItems(partnerBusinessId) becomes a real
// Supabase call — this needs its own RLS policy allowing a read (never a
// write) of another tenant's catalog, scoped the same way.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/data/models/agreement_model.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_catalog_source.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_marketplace_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/modules/agreements/providers/agreements_notifier.dart';

/// One partner business's offer: the agreement that grants access, that
/// business's name (for display and commission records), and their
/// catalog items matching the agreed category.
class PartnerOffer {
  const PartnerOffer({
    required this.agreement,
    required this.partnerBusinessName,
    required this.items,
  });
  final AgreementModel agreement;
  final String partnerBusinessName;
  final List<CatalogItemModel> items;
}

/// Active agreements belonging to the current user's own business,
/// each resolved to the partner business's name and matching catalog
/// items.
///
/// Works for both Owner and Client: an agreement is always scoped to
/// businessId, and a client's own businessId already equals their
/// coach's — so this naturally shows "my coach's partner offers"
/// without needing a separate client-specific agreements provider.
final partnerOffersProvider = FutureProvider.autoDispose<List<PartnerOffer>>(
  (ref) async {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final agreements = await ref.watch(agreementsNotifierProvider.future);
    final active = agreements.where((a) => a.isActive).toList();
    if (active.isEmpty) return [];

    final catalogRepo = DataConfig.useMockData
        ? MockCatalogSource()
        : throw UnimplementedError(
            'SupabaseCatalogSource not yet wired (Phase 10 only).');
    final marketplaceRepo = DataConfig.useMockData
        ? MockMarketplaceSource()
        : throw UnimplementedError(
            'SupabaseMarketplaceSource not yet wired (Phase 10 only).');

    final offers = <PartnerOffer>[];
    for (final agreement in active) {
      final partnerItems =
          await catalogRepo.getActiveCatalogItems(agreement.partnerBusinessId);
      final matching = partnerItems
          .where((item) => item.categoryTag == agreement.categoryId)
          .toList();
      if (matching.isEmpty) continue;

      final listing = await marketplaceRepo.getMyListing(
        agreement.partnerUserId,
      );
      offers.add(PartnerOffer(
        agreement: agreement,
        partnerBusinessName: listing?.businessName ?? 'Partner business',
        items: matching,
      ));
    }
    return offers;
  },
);
