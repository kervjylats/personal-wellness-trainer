// lib/data/repositories/media_repository.dart
//
// Abstract interface for all media library data operations.
// MediaNotifier talks ONLY to this interface.
// Mock: MockMediaSource (Phases 1–9). Real: SupabaseMediaSource (Phase 10).

import 'package:personal_wellness_trainer/data/models/media_item_model.dart';

abstract class MediaRepository {
  /// Returns all media items for a business, newest first.
  Future<List<MediaItemModel>> getMediaItems(String businessId);

  /// Returns only public media items. Used for client-facing library.
  Future<List<MediaItemModel>> getPublicMediaItems(String businessId);

  /// Returns media items of a specific type ('video', 'audio', 'pdf', 'image').
  Future<List<MediaItemModel>> getMediaItemsByType(
    String businessId,
    String mediaType,
  );

  /// Creates a new media item record. Returns the created record.
  Future<MediaItemModel> createMediaItem({
    required String businessId,
    required String uploadedByUserId,
    required String title,
    required String mediaType,
    required String url,
    String? description,
    String? thumbnailUrl,
    bool isPublic = true,
    int? fileSizeBytes,
  });

  /// Updates the metadata of an existing media item.
  Future<MediaItemModel> updateMediaItem({
    required String mediaItemId,
    String? title,
    String? description,
    bool? isPublic,
    String? thumbnailUrl,
  });

  /// Permanently deletes a media item.
  Future<void> deleteMediaItem(String mediaItemId);
}
