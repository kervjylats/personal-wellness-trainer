// lib/data/sources/mock/mock_media_source.dart
//
// Mock implementation of MediaRepository.
// Returns generic seed data for Phases 1–9.
// ⚠️  No industry-specific words anywhere in this file.

import 'package:personal_wellness_trainer/data/models/media_item_model.dart';
import 'package:personal_wellness_trainer/data/repositories/media_repository.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_source_mixin.dart';

class MockMediaSource with MockSourceMixin implements MediaRepository {
  static const String _businessId = 'biz_mock_001';
  static const String _ownerUserId = 'usr_owner_001';

  static final List<MediaItemModel> _store = _buildSeedData();
  static int _idCounter = 100;

  // ── Read ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<MediaItemModel>> getMediaItems(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((m) => m.businessId == businessId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<MediaItemModel>> getPublicMediaItems(String businessId) async {
    await simulateNetworkDelay();
    return _store
        .where((m) => m.businessId == businessId && m.isPublic)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<MediaItemModel>> getMediaItemsByType(
    String businessId,
    String mediaType,
  ) async {
    await simulateNetworkDelay();
    return _store
        .where((m) => m.businessId == businessId && m.mediaType == mediaType)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── Write ─────────────────────────────────────────────────────────────────────

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
    await simulateNetworkDelay();
    final item = MediaItemModel(
      id: 'media_mock_${++_idCounter}',
      businessId: businessId,
      uploadedByUserId: uploadedByUserId,
      title: title,
      description: description,
      mediaType: mediaType,
      url: url,
      thumbnailUrl: thumbnailUrl,
      isPublic: isPublic,
      fileSizeBytes: fileSizeBytes,
      createdAt: DateTime.now(),
    );
    _store.add(item);
    return item;
  }

  @override
  Future<MediaItemModel> updateMediaItem({
    required String mediaItemId,
    String? title,
    String? description,
    bool? isPublic,
    String? thumbnailUrl,
  }) async {
    await simulateNetworkDelay();
    final idx = _store.indexWhere((m) => m.id == mediaItemId);
    if (idx == -1) {
      throw StateError('MediaItem $mediaItemId not found in mock store');
    }
    final updated = _store[idx].copyWith(
      title: title,
      description: description,
      isPublic: isPublic,
      thumbnailUrl: thumbnailUrl,
    );
    _store[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteMediaItem(String mediaItemId) async {
    await simulateNetworkDelay();
    _store.removeWhere((m) => m.id == mediaItemId);
  }

  // ── Seed data ─────────────────────────────────────────────────────────────────

  static List<MediaItemModel> _buildSeedData() {
    final base = DateTime(2025, 6);
    return [
      MediaItemModel(
        id: 'media_mock_001',
        businessId: _businessId,
        uploadedByUserId: _ownerUserId,
        title: 'Welcome Video',
        description: 'An introduction to our services.',
        mediaType: 'video',
        url: 'mock://videos/welcome.mp4',
        thumbnailUrl: 'mock://thumbnails/welcome.jpg',
        isPublic: true,
        fileSizeBytes: 52428800,
        createdAt: base.subtract(const Duration(days: 30)),
      ),
      MediaItemModel(
        id: 'media_mock_002',
        businessId: _businessId,
        uploadedByUserId: _ownerUserId,
        title: 'Getting Started Guide',
        description: 'PDF guide for new members.',
        mediaType: 'pdf',
        url: 'mock://docs/guide.pdf',
        isPublic: true,
        fileSizeBytes: 1048576,
        createdAt: base.subtract(const Duration(days: 20)),
      ),
      MediaItemModel(
        id: 'media_mock_003',
        businessId: _businessId,
        uploadedByUserId: _ownerUserId,
        title: 'Internal Training Audio',
        description: 'Staff-only training material.',
        mediaType: 'audio',
        url: 'mock://audio/training.mp3',
        isPublic: false,
        fileSizeBytes: 8388608,
        createdAt: base.subtract(const Duration(days: 10)),
      ),
    ];
  }
}
