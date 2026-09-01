// lib/modules/media/registry/media_registry.dart

import 'package:personal_wellness_trainer/engine/registry/widget_registry.dart';
import 'package:personal_wellness_trainer/modules/media/registry/media_preview_card.dart';

abstract final class MediaRegistry {
  static void register() {
    WidgetRegistry.register(
      'media.PreviewCard',
      (context, data) => MediaPreviewCard(data: data),
    );
  }
}
