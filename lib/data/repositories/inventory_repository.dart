// lib/data/repositories/inventory_repository.dart
//
// Abstract interface for inventory stock operations.
// InventoryNotifier talks ONLY to this interface.
// Mock: MockInventorySource (Phases 1–9). Real: SupabaseInventorySource (Phase 10).

import 'package:personal_wellness_trainer/data/models/inventory_item_model.dart';

abstract class InventoryRepository {
  /// Returns all inventory records for a business.
  Future<List<InventoryItemModel>> getInventoryItems(String businessId);

  /// Returns inventory records where stock is at or below the low-stock threshold.
  Future<List<InventoryItemModel>> getLowStockItems(String businessId);

  /// Creates an inventory record for a catalog item.
  Future<InventoryItemModel> createInventoryItem({
    required String businessId,
    required String catalogItemId,
    required int stockCount,
    int lowStockThreshold = 5,
    String? catalogItemTitle,
  });

  /// Adjusts the stock count by delta (positive = add, negative = remove).
  /// Returns the updated record.
  Future<InventoryItemModel> adjustStock(String inventoryItemId, int delta);

  /// Sets the reserved count on a record.
  Future<InventoryItemModel> setReserved(String inventoryItemId, int reservedCount);

  /// Updates the low-stock threshold.
  Future<InventoryItemModel> setLowStockThreshold(
    String inventoryItemId,
    int threshold,
  );

  /// Permanently deletes an inventory record.
  Future<void> deleteInventoryItem(String inventoryItemId);
}
