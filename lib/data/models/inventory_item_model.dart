// lib/data/models/inventory_item_model.dart
//
// Immutable data record tracking stock levels for a catalog item.
// One InventoryItemModel per CatalogItemModel (linked via catalogItemId).
// No industry-specific words.

class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.businessId,
    required this.catalogItemId,
    required this.stockCount,
    required this.reservedCount,
    required this.lowStockThreshold,
    required this.updatedAt,
    this.catalogItemTitle,
  });

  final String id;
  final String businessId;

  /// Foreign key to CatalogItemModel.id.
  final String catalogItemId;

  /// Optional denormalised title for display without a catalog join.
  final String? catalogItemTitle;

  /// Total units currently in stock (before reservation).
  final int stockCount;

  /// Units held by pending orders.
  final int reservedCount;

  /// If availableCount falls to or below this value, show low-stock warning.
  final int lowStockThreshold;

  final DateTime updatedAt;

  /// Computed: stockCount - reservedCount
  int get availableCount => stockCount - reservedCount;

  /// True when availableCount is at or below the threshold.
  bool get isLowStock => availableCount <= lowStockThreshold;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      catalogItemId: json['catalog_item_id'] as String,
      catalogItemTitle: json['catalog_item_title'] as String?,
      stockCount: json['stock_count'] as int,
      reservedCount: json['reserved_count'] as int? ?? 0,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 5,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'catalog_item_id': catalogItemId,
      'catalog_item_title': catalogItemTitle,
      'stock_count': stockCount,
      'reserved_count': reservedCount,
      'low_stock_threshold': lowStockThreshold,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  InventoryItemModel copyWith({
    String? id,
    String? businessId,
    String? catalogItemId,
    String? catalogItemTitle,
    int? stockCount,
    int? reservedCount,
    int? lowStockThreshold,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      catalogItemTitle: catalogItemTitle ?? this.catalogItemTitle,
      stockCount: stockCount ?? this.stockCount,
      reservedCount: reservedCount ?? this.reservedCount,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
