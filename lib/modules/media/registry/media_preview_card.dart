// lib/modules/media/registry/media_preview_card.dart
//
// Registry widget: shows a compact preview of recent media items.
// Registered as 'media.PreviewCard' in MediaRegistry.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/modules/media/providers/media_notifier.dart';

class MediaPreviewCard extends ConsumerWidget {
  const MediaPreviewCard({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(mediaNotifierProvider);
    return mediaAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final latest = items.first;
        return Card(
          child: ListTile(
            leading: Icon(Icons.perm_media_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text(latest.title, style: AppTextStyles.bodyMedium),
            subtitle: Text(
              '${items.length} item${items.length == 1 ? '' : 's'}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          ),
        );
      },
    );
  }
}
