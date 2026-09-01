// lib/modules/catalog/registry/catalog_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/catalog/registry/catalog_item_card.dart';

abstract final class CatalogRegistry {
  static void register() {
    WidgetRegistry.register(
      'catalog.ItemCard',
      (context, data) => CatalogItemCard(data: data),
    );
  }
}
