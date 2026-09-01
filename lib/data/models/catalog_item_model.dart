// lib/data/models/catalog_item_model.dart
//
// Immutable data record for a product or service listed in the catalog.
// No industry-specific words (no 'product', 'service', 'treatment').
// The industry config terminology key 'catalog' controls the user-facing label.

class CatalogItemModel {
  const CatalogItemModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.categoryTag,
    this.unit,
  });

  final String id;
  final String businessId;
  final String title;
  final String? description;
  final double price;
  final String currency;

  /// Optional grouping tag (e.g. 'cat_1') matching industry config categories.
  final String? categoryTag;

  /// Optional URL for the item's image.
  final String? imageUrl;

  /// Optional unit label (e.g. 'per hour', 'each').
  final String? unit;

  /// When false, hidden from clients and not orderable.
  final bool isActive;

  final DateTime createdAt;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogItemModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? '\$',
      categoryTag: json['category_tag'] as String?,
      imageUrl: json['image_url'] as String?,
      unit: json['unit'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'category_tag': categoryTag,
      'image_url': imageUrl,
      'unit': unit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  CatalogItemModel copyWith({
    String? id,
    String? businessId,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? categoryTag,
    String? imageUrl,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CatalogItemModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      categoryTag: categoryTag ?? this.categoryTag,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
