// lib/data/sources/mock/mock_inventory_source.dart
//
// Mock implementation of InventoryRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/inventory_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/inventory_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockInventorySource with MockSourceMixin implements InventoryRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<InventoryItemModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<InventoryItemModel>> getInventoryItems(
      String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((i) => i.businessId == businessId)
        .toList();
  }

  @override
  Future<List<InventoryItemModel>> getLowStockItems(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((i) => i.businessId == businessId && i.isLowStock)
        .toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
  Future<InventoryItemModel> createInventoryItem({
    required String businessId,
    required String catalogItemId,
    required int stockCount,
    int lowStockThreshold = 5,
    String? catalogItemTitle,
  }) async {
    await simulateNetworkDelay();
    final item = InventoryItemModel(
      id: 'inv_mock_${++_idCounter}',
      businessId: businessId,
      catalogItemId: catalogItemId,
      catalogItemTitle: catalogItemTitle,
      stockCount: stockCount,
      reservedCount: 0,
      lowStockThreshold: lowStockThreshold,
      updatedAt: DateTime.now(),
    );
    _store.add(item);
    return item;
  }

  @override
  Future<InventoryItemModel> adjustStock(
      String inventoryItemId, int delta) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((i) => i.id == inventoryItemId);
    if (idx == -1) {
      throw StateError('InventoryItem $inventoryItemId not found in mock store');
    }
    final newCount = (_store[idx].stockCount + delta).clamp(0, 999999);
    final updated = _store[idx].copyWith(
      stockCount: newCount,
      updatedAt: DateTime.now(),
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<InventoryItemModel> setReserved(
      String inventoryItemId, int reservedCount) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((i) => i.id == inventoryItemId);
    if (idx == -1) {
      throw StateError('InventoryItem $inventoryItemId not found in mock store');
    }
    final updated = _store[idx].copyWith(
      reservedCount: reservedCount,
      updatedAt: DateTime.now(),
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<InventoryItemModel> setLowStockThreshold(
    String inventoryItemId,
    int threshold,
  ) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((i) => i.id == inventoryItemId);
    if (idx == -1) {
      throw StateError('InventoryItem $inventoryItemId not found in mock store');
    }
    final updated = _store[idx].copyWith(
      lowStockThreshold: threshold,
      updatedAt: DateTime.now(),
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteInventoryItem(String inventoryItemId) async {
    await simulateNetworkDelay();
    _store.removeWhere((i) => i.id == inventoryItemId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<InventoryItemModel> _buildSeedData() {
    return [
      InventoryItemModel(
        id: 'inv_mock_001',
        businessId: _businessId,
        catalogItemId: 'cat_mock_001',
        catalogItemTitle: 'Standard Option A',
        stockCount: 50,
        reservedCount: 3,
        lowStockThreshold: 5,
        updatedAt: DateTime(2025, 6, 1),
      ),
      InventoryItemModel(
        id: 'inv_mock_002',
        businessId: _businessId,
        catalogItemId: 'cat_mock_002',
        catalogItemTitle: 'Premium Option B',
        stockCount: 4,
        reservedCount: 1,
        lowStockThreshold: 5,
        updatedAt: DateTime(2025, 6, 2),
      ),
    ];
  }
}
