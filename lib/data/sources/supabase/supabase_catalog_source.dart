// lib/data/sources/supabase/supabase_catalog_source.dart
//
// Real Supabase implementation of CatalogRepository. getActiveCatalogItems()
// is the one cross-tenant read here — see schema.sql's catalog_items table
// comment for the RLS policy backing it (mirrors marketplace_listings'
// same "active agreement" clause). Everything else is scoped to the
// caller's own business only.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/catalog_repository.dart';

class SupabaseCatalogSource implements CatalogRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<CatalogItemModel>> getCatalogItems(String businessId) async {
    final rows = await _db
        .from('catalog_items')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => CatalogItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CatalogItemModel>> getActiveCatalogItems(
    String businessId,
  ) async {
    // Works for both "my own active items" and "a partner business's
    // active items" — RLS resolves which rows are actually visible
    // (own business, or an active-agreement partner's), this query
    // itself doesn't need to know which case it is.
    final rows = await _db
        .from('catalog_items')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => CatalogItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

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
    final row = await _db.from('catalog_items').insert({
      'business_id': businessId,
      'title': title,
      'price': price,
      'currency': currency,
      'is_active': isActive,
      if (description != null) 'description': description,
      if (categoryTag != null) 'category_tag': categoryTag,
      if (imageUrl != null) 'image_url': imageUrl,
      if (unit != null) 'unit': unit,
    }).select().single();

    return CatalogItemModel.fromJson(row);
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
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (categoryTag != null) updates['category_tag'] = categoryTag;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (unit != null) updates['unit'] = unit;
    if (isActive != null) updates['is_active'] = isActive;

    final row = await _db
        .from('catalog_items')
        .update(updates)
        .eq('id', catalogItemId)
        .select()
        .single();

    return CatalogItemModel.fromJson(row);
  }

  @override
  Future<void> deleteCatalogItem(String catalogItemId) async {
    await _db.from('catalog_items').delete().eq('id', catalogItemId);
  }
}
