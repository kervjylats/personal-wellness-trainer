// lib/data/repositories/catalog_repository.dart
//
// Abstract interface for all catalog item data operations.
// CatalogNotifier talks ONLY to this interface.
// Mock: MockCatalogSource (Phases 1–9). Real: SupabaseCatalogSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';

abstract class CatalogRepository {
  /// Returns all catalog items for a business, newest first.
  Future<List<CatalogItemModel>> getCatalogItems(String businessId);

  /// Returns only active catalog items. Used for client-facing browsing.
  Future<List<CatalogItemModel>> getActiveCatalogItems(String businessId);

  /// Creates a new catalog item. Returns the created record.
  Future<CatalogItemModel> createCatalogItem({
    required String businessId,
    required String title,
    required double price,
    required String currency,
    String? description,
    String? categoryTag,
    String? imageUrl,
    String? unit,
    bool isActive = true,
  });

  /// Updates an existing catalog item. Returns the updated record.
  Future<CatalogItemModel> updateCatalogItem({
    required String catalogItemId,
    String? title,
    String? description,
    double? price,
    String? categoryTag,
    String? imageUrl,
    String? unit,
    bool? isActive,
  });

  /// Permanently deletes a catalog item.
  Future<void> deleteCatalogItem(String catalogItemId);
}
