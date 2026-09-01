// lib/modules/catalog/providers/catalog_notifier.dart
//
// AsyncNotifier managing the catalog for the current business.
// Owner: sees all items (active and inactive).
// Client: sees only active items.
// In Phase 10, replace MockCatalogSource() with SupabaseCatalogSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/catalog_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/catalog_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_catalog_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/catalog/providers/catalog_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final catalogNotifierProvider =
    AsyncNotifierProvider<CatalogNotifier, List<CatalogItemModel>>(
  CatalogNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class CatalogNotifier extends AsyncNotifier<List<CatalogItemModel>> {
  static const String _tag = 'CatalogNotifier';
  late CatalogRepository _repo;

  @override
  Future<List<CatalogItemModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('catalog')) {
      AppLogger.debug('CatalogNotifier: module not included', tag: _tag);
      return [];
    }

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
        'CatalogNotifier: loading for role ${role.value}', tag: _tag);

    if (role.isClient) {
      return _repo.getActiveCatalogItems(profile.businessId);
    }
    return _repo.getCatalogItems(profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new catalog item. Returns the created item or null on error.
  Future<CatalogItemModel?> create({
    required String title,
    required double price,
    required String currency,
    String? description,
    String? categoryTag,
    String? imageUrl,
    String? unit,
    bool isActive = true,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(catalogActionErrorProvider.notifier).state = null;

    try {
      final item = await _repo.createCatalogItem(
        businessId: authState.profile.businessId,
        title: title,
        price: price,
        currency: currency,
        description: description,
        categoryTag: categoryTag,
        imageUrl: imageUrl,
        unit: unit,
        isActive: isActive,
      );
      ref.invalidateSelf();
      AppLogger.info('CatalogNotifier: created ${item.id}', tag: _tag);
      return item;
    } catch (e, st) {
      AppLogger.error('CatalogNotifier: create failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(catalogActionErrorProvider.notifier).state =
          'Could not add catalog item. Please try again.';
      return null;
    }
  }

  /// Updates a catalog item. Returns updated item or null on error.
  Future<CatalogItemModel?> edit({
    required String catalogItemId,
    String? title,
    String? description,
    double? price,
    String? categoryTag,
    String? imageUrl,
    String? unit,
    bool? isActive,
  }) async {
    ref.read(catalogActionErrorProvider.notifier).state = null;
    try {
      final item = await _repo.updateCatalogItem(
        catalogItemId: catalogItemId,
        title: title,
        description: description,
        price: price,
        categoryTag: categoryTag,
        imageUrl: imageUrl,
        unit: unit,
        isActive: isActive,
      );
      ref.invalidateSelf();
      return item;
    } catch (e, st) {
      AppLogger.error('CatalogNotifier: update failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(catalogActionErrorProvider.notifier).state =
          'Could not update item. Please try again.';
      return null;
    }
  }

  /// Deletes a catalog item. Returns true on success.
  Future<bool> delete(String catalogItemId) async {
    ref.read(catalogActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteCatalogItem(catalogItemId);
      ref.invalidateSelf();
      AppLogger.info('CatalogNotifier: deleted $catalogItemId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('CatalogNotifier: delete failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(catalogActionErrorProvider.notifier).state =
          'Could not delete item. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  CatalogRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockCatalogSource();
    throw UnimplementedError(
        'SupabaseCatalogSource not yet wired (Phase 10 only).');
  }
}

