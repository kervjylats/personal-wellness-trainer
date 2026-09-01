// lib/modules/media/screens/media_library_screen.dart
//
// Role-aware media library screen.
// Owner/Staff: sees all items. Client: sees public items only.
//
// Phase 9 fix: moduleLabel now reads from activeJobConfigProvider so the
// AppBar title shows the job-specific term (e.g. "Content" for yoga/pilates).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/theme/app_colors.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_card_list_view.dart';
import 'package:personal_wellness_trainer/core/widgets/app_empty_state.dart';
import 'package:personal_wellness_trainer/core/widgets/error_display.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/media_item_model.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/jobs_config_provider.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/media/providers/media_notifier.dart';

class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(mediaNotifierProvider);
    final authState  = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final role        = AppRole.fromString(authState.profile.role);
    final jobConfig   = ref.watch(activeJobConfigProvider);
    final moduleLabel = jobConfig.terminology.labelFor('media');

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleLabel),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: role.isOwner
          ? FloatingActionButton(
              onPressed: () {},
              tooltip: 'Upload',
              child: const Icon(Icons.upload),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mediaNotifierProvider),
        child: mediaAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(
            message: 'Could not load $moduleLabel.',
            onRetry: () => ref.invalidate(mediaNotifierProvider),
          ),
          data: (items) => items.isEmpty
              ? AppEmptyState(
                  icon: Icons.perm_media_outlined,
                  headline: 'No $moduleLabel items yet',
                  subtext: role.isOwner
                      ? 'Tap + to upload your first item.'
                      : null,
                )
              : _MediaGrid(items: items, role: role, ref: ref),
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.items, required this.role, required this.ref});
  final List<MediaItemModel> items;
  final AppRole              role;
  final WidgetRef            ref;

  @override
  Widget build(BuildContext context) {
    return AppCardListView<MediaItemModel>(
      items: items,
      itemBuilder: (context, index, item) =>
          _MediaTile(item: item, role: role, ref: ref),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item, required this.role, required this.ref});
  final MediaItemModel item;
  final AppRole        role;
  final WidgetRef      ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.insert_drive_file_outlined,
              color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(item.title, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          item.mediaType,
          style:
              AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: role.isOwner
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: 'Delete',
                onPressed: () => ref
                    .read(mediaNotifierProvider.notifier)
                    .delete(item.id),
              )
            : null,
      ),
    );
  }
}
