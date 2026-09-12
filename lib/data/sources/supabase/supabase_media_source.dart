// lib/data/sources/supabase/supabase_media_source.dart
//
// Real Supabase implementation of MediaRepository.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/media_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/media_repository.dart';

class SupabaseMediaSource implements MediaRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<List<MediaItemModel>> getMediaItems(String businessId) async {
    final rows = await _db
        .from('media_items')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MediaItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MediaItemModel>> getPublicMediaItems(String businessId) async {
    final rows = await _db
        .from('media_items')
        .select()
        .eq('business_id', businessId)
        .eq('is_public', true)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MediaItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MediaItemModel>> getMediaItemsByType(
    String businessId,
    String mediaType,
  ) async {
    final rows = await _db
        .from('media_items')
        .select()
        .eq('business_id', businessId)
        .eq('media_type', mediaType)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MediaItemModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
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
  }) async {
    final row = await _db.from('media_items').insert({
      'business_id': businessId,
      'uploaded_by_user_id': uploadedByUserId,
      'title': title,
      'media_type': mediaType,
      'url': url,
      'is_public': isPublic,
      if (description != null) 'description': description,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
    }).select().single();

    return MediaItemModel.fromJson(row);
  }

  @override
  Future<MediaItemModel> updateMediaItem({
    required String mediaItemId,
    String? title,
    String? description,
    bool? isPublic,
    String? thumbnailUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (isPublic != null) updates['is_public'] = isPublic;
    if (thumbnailUrl != null) updates['thumbnail_url'] = thumbnailUrl;

    final row = await _db
        .from('media_items')
        .update(updates)
        .eq('id', mediaItemId)
        .select()
        .single();

    return MediaItemModel.fromJson(row);
  }

  @override
  Future<void> deleteMediaItem(String mediaItemId) async {
    await _db.from('media_items').delete().eq('id', mediaItemId);
  }
}
