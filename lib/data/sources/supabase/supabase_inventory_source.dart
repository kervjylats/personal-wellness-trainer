// lib/data/sources/supabase/supabase_inventory_source.dart
//
// Real Supabase implementation of InventoryRepository. adjustStock()
// wraps the adjust_stock() Postgres function (triggers.sql) rather than
// a client-side read-then-write — see that function's own comment for
// the race-condition reasoning, and for the caller-authorization check
// inside it (SECURITY DEFINER bypasses RLS, so the function itself has
// to verify the caller belongs to this item's business).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/inventory_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/inventory_repository.dart';

class SupabaseInventorySource implements InventoryRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<InventoryItemModel>> getInventoryItems(String businessId) async {
    final rows = await _db
        .from('inventory_items')
        .select()
        .eq('business_id', businessId);
    return (rows as List)
        .map((r) => InventoryItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<InventoryItemModel>> getLowStockItems(String businessId) async {
    // Postgrest can't compare two columns of the same row directly in a
    // filter, so this pulls all items for the business and filters
    // low-stock client-side — small tables (a business's own inventory),
    // no pagination concern in practice.
    final all = await getInventoryItems(businessId);
    // Use the model's isLowStock (accounts for reserved units) — not a raw
    // stockCount comparison that ignores reservations.
    return all.where((i) => i.isLowStock).toList();
  }

  @override
  Future<InventoryItemModel> createInventoryItem({
    required String businessId,
    required String catalogItemId,
    required int stockCount,
    int lowStockThreshold = 5,
    String? catalogItemTitle,
  }) async {
    final row = await _db.from('inventory_items').insert({
      'business_id': businessId,
      'catalog_item_id': catalogItemId,
      'stock_count': stockCount,
      'low_stock_threshold': lowStockThreshold,
      if (catalogItemTitle != null) 'catalog_item_title': catalogItemTitle,
    }).select().single();

    return InventoryItemModel.fromJson(row);
  }

  @override
  Future<InventoryItemModel> adjustStock(
    String inventoryItemId,
    int delta,
  ) async {
    final row = await _db.rpc('adjust_stock', params: {
      'p_inventory_item_id': inventoryItemId,
      'p_delta': delta,
    });
    return InventoryItemModel.fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<InventoryItemModel> setReserved(
    String inventoryItemId,
    int reservedCount,
  ) async {
    final row = await _db
        .from('inventory_items')
        .update({
          'reserved_count': reservedCount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inventoryItemId)
        .select()
        .single();
    return InventoryItemModel.fromJson(row);
  }

  @override
  Future<InventoryItemModel> setLowStockThreshold(
    String inventoryItemId,
    int threshold,
  ) async {
    final row = await _db
        .from('inventory_items')
        .update({
          'low_stock_threshold': threshold,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inventoryItemId)
        .select()
        .single();
    return InventoryItemModel.fromJson(row);
  }

  @override
  Future<void> deleteInventoryItem(String inventoryItemId) async {
    await _db.from('inventory_items').delete().eq('id', inventoryItemId);
  }
}
