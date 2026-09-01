// lib/data/sources/mock/mock_catalog_source.dart
//
// Mock implementation of CatalogRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/catalog_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockCatalogSource with MockSourceMixin implements CatalogRepository {
  static const String _businessId = 'biz_mock_001';

  static final List<CatalogItemModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<CatalogItemModel>> getCatalogItems(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((c) => c.businessId == businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<CatalogItemModel>> getActiveCatalogItems(
      String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((c) => c.businessId == businessId && c.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

  @override
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
  }) async {
    await simulateNetworkDelay();
    final item = CatalogItemModel(
      id: 'cat_mock_${++_idCounter}',
      businessId: businessId,
      title: title,
      description: description,
      price: price,
      currency: currency,
      categoryTag: categoryTag,
      imageUrl: imageUrl,
      unit: unit,
      isActive: isActive,
      createdAt: DateTime.now(),
    );
    _store.add(item);
    return item;
  }

  @override
  Future<CatalogItemModel> updateCatalogItem({
    required String catalogItemId,
    String? title,
    String? description,
    double? price,
    String? categoryTag,
    String? imageUrl,
    String? unit,
    bool? isActive,
  }) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((c) => c.id == catalogItemId);
    if (idx == -1) {
      throw StateError('CatalogItem $catalogItemId not found in mock store');
    }
    final updated = _store[idx].copyWith(
      title: title,
      description: description,
      price: price,
      categoryTag: categoryTag,
      imageUrl: imageUrl,
      unit: unit,
      isActive: isActive,
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteCatalogItem(String catalogItemId) async {
    await simulateNetworkDelay();
    _store.removeWhere((c) => c.id == catalogItemId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<CatalogItemModel> _buildSeedData() {
    final base = DateTime(2025, 5);
    return [
      CatalogItemModel(
        id: 'cat_mock_001',
        businessId: _businessId,
        title: 'Standard Option A',
        description: 'The most popular option.',
        price: 50.00,
        currency: '\$',
        categoryTag: 'cat_1',
        isActive: true,
        createdAt: base.subtract(const Duration(days: 60)),
      ),
      CatalogItemModel(
        id: 'cat_mock_002',
        businessId: _businessId,
        title: 'Premium Option B',
        description: 'Enhanced version with extra features.',
        price: 120.00,
        currency: '\$',
        categoryTag: 'cat_1',
        unit: 'per unit',
        isActive: true,
        createdAt: base.subtract(const Duration(days: 45)),
      ),
      CatalogItemModel(
        id: 'cat_mock_003',
        businessId: _businessId,
        title: 'Add-On C',
        description: 'Optional add-on item.',
        price: 20.00,
        currency: '\$',
        categoryTag: 'cat_2',
        isActive: false,
        createdAt: base.subtract(const Duration(days: 30)),
      ),
    ];
  }
}
