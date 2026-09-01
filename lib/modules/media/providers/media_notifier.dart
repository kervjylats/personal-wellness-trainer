// lib/modules/media/providers/media_notifier.dart
//
// AsyncNotifier managing the media library for the current business.
// Owner: sees all items. Client: sees public items only.
// In Phase 10, replace MockMediaSource() with SupabaseMediaSource().

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/data/models/media_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/media_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_media_source.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/data_config.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/media/providers/media_action_error_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final mediaNotifierProvider =
    AsyncNotifierProvider<MediaNotifier, List<MediaItemModel>>(
  MediaNotifier.new,
  dependencies: [authNotifierProvider],
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class MediaNotifier extends AsyncNotifier<List<MediaItemModel>> {
  static const String _tag = 'MediaNotifier';
  late MediaRepository _repo;

  @override
  Future<List<MediaItemModel>> build() async {
    _repo = _resolveRepository();
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) return [];

    final buildConfig = ref.watch(buildConfigProvider);
    if (!buildConfig.modulesIncluded.isIncluded('media')) {
      AppLogger.debug('MediaNotifier: module not included', tag: _tag);
      return [];
    }

    final profile = authState.profile;
    final role = AppRole.fromString(profile.role);

    AppLogger.debug(
      'MediaNotifier: loading for role ${role.value}',
      tag: _tag,
    );

    if (role.isClient) {
      return _repo.getPublicMediaItems(profile.businessId);
    }
    return _repo.getMediaItems(profile.businessId);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new media item record. Returns the created item or null on error.
  Future<MediaItemModel?> create({
    required String title,
    required String mediaType,
    required String url,
    String? description,
    String? thumbnailUrl,
    bool isPublic = true,
    int? fileSizeBytes,
  }) async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthAuthenticated) return null;

    ref.read(mediaActionErrorProvider.notifier).state = null;

    try {
      final item = await _repo.createMediaItem(
        businessId: authState.profile.businessId,
        uploadedByUserId: authState.profile.userId,
        title: title,
        mediaType: mediaType,
        url: url,
        description: description,
        thumbnailUrl: thumbnailUrl,
        isPublic: isPublic,
        fileSizeBytes: fileSizeBytes,
      );
      ref.invalidateSelf();
      AppLogger.info('MediaNotifier: created ${item.id}', tag: _tag);
      return item;
    } catch (e, st) {
      AppLogger.error('MediaNotifier: create failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(mediaActionErrorProvider.notifier).state =
          'Could not add media item. Please try again.';
      return null;
    }
  }

  /// Updates a media item. Returns updated item or null on error.
  Future<MediaItemModel?> edit({
    required String mediaItemId,
    String? title,
    String? description,
    bool? isPublic,
    String? thumbnailUrl,
  }) async {
    ref.read(mediaActionErrorProvider.notifier).state = null;
    try {
      final item = await _repo.updateMediaItem(
        mediaItemId: mediaItemId,
        title: title,
        description: description,
        isPublic: isPublic,
        thumbnailUrl: thumbnailUrl,
      );
      ref.invalidateSelf();
      return item;
    } catch (e, st) {
      AppLogger.error('MediaNotifier: update failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(mediaActionErrorProvider.notifier).state =
          'Could not update item. Please try again.';
      return null;
    }
  }

  /// Deletes a media item. Returns true on success.
  Future<bool> delete(String mediaItemId) async {
    ref.read(mediaActionErrorProvider.notifier).state = null;
    try {
      await _repo.deleteMediaItem(mediaItemId);
      ref.invalidateSelf();
      AppLogger.info('MediaNotifier: deleted $mediaItemId', tag: _tag);
      return true;
    } catch (e, st) {
      AppLogger.error('MediaNotifier: delete failed',
          tag: _tag, error: e, stackTrace: st);
      ref.read(mediaActionErrorProvider.notifier).state =
          'Could not delete item. Please try again.';
      return false;
    }
  }

  // ── Repository resolution ─────────────────────────────────────────────────────

  MediaRepository _resolveRepository() {
    if (DataConfig.useMockData) return MockMediaSource();
    throw UnimplementedError(
        'SupabaseMediaSource not yet wired (Phase 10 only).');
  }
}

