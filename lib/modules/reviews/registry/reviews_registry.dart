// lib/modules/reviews/registry/reviews_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/reviews/registry/reviews_summary_card.dart';

abstract final class ReviewsRegistry {
  static void register() {
    WidgetRegistry.register(
      'reviews.SummaryCard',
      (context, data) => ReviewsSummaryCard(data: data),
    );
  }
}
