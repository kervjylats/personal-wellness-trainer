// lib/modules/inventory/providers/inventory_notifier.dart
//
// AsyncNotifier managing inventory stock levels for the current business.
// Owner-only module — staff and clients do not see inventory management.
// In Phase 10, replace MockInventorySource() with SupabaseInventorySource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/inventory_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/inventory_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_inventory_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/modules/inventory/providers/inventory_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final inventoryNotifierProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItemModel>>(
  InventoryNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class InventoryNotifier extends AsyncNotifier<List<InventoryItemModel>> {
  static const String _tag = 'InventoryNotifier';
  late InventoryRepository _repo;

  @override
  Future<List<InventoryItemModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('inventory')) {
      AppLogger.debug('InventoryNotifier: module not included', tag: _tag);
      return [];
    }

    AppLogger.debug(
      'InventoryNotifier: loading for business '
      '${authState.profile.businessId}',
      tag: _tag,
    );

    return _repo.getInventoryItems(authState.profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates an inventory record for a catalog item.
  Future<InventoryItemModel?> create({
    required String catalogItemId,
    required int stockCount,
    int lowStockThreshold = 5,
    String? catalogItemTitle,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(inventoryActionErrorProvider.notifier).state = null;

    try {
      final item = await _repo.createInventoryItem(
        businessId: authState.profile.businessId,
        catalogItemId: catalogItemId,
        stockCount: stockCount,
        lowStockThreshold: lowStockThreshold,
        catalogItemTitle: catalogItemTitle,
      );
      ref.invalidateSelf();
      AppLogger.info('InventoryNotifier: created ${item.id}', tag: _tag);
      return item;
    } catch (e, st) {
      AppLogger.error('InventoryNotifier: create failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(inventoryActionErrorProvider.notifier).state =
          'Could not create inventory record. Please try again.';
      return null;
    }
  }

  /// Adjusts stock by delta (positive = add, negative = remove).
  Future<bool> adjustStock(String inventoryItemId, int delta) async {
    ref.read(inventoryActionErrorProvider.notifier).state = null;
    try {
      await _repo.adjustStock(inventoryItemId, delta);
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      AppLogger.error('InventoryNotifier: adjustStock failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(inventoryActionErrorProvider.notifier).state =
          'Could not adjust stock. Please try again.';
      return false;
    }
  }

  /// Deletes an inventory record. Returns true on success.
  Future<bool> delete(String inventoryItemId) async {
    ref.read(inventoryActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteInventoryItem(inventoryItemId);
      ref.invalidateSelf();
      AppLogger.info('InventoryNotifier: deleted $inventoryItemId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('InventoryNotifier: delete failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(inventoryActionErrorProvider.notifier).state =
          'Could not delete record. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  InventoryRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockInventorySource();
    throw UnimplementedError(
        'SupabaseInventorySource not yet wired (Phase 10 only).');
  }
}

