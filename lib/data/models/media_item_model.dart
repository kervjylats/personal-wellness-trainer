// lib/data/models/media_item_model.dart
//
// Immutable data record for a media file in the content library.
// mediaType values: 'video' | 'audio' | 'pdf' | 'image'
// No industry-specific words. Media type labels come from industry config.

class MediaItemModel {
  const MediaItemModel({
    required this.id,
    required this.businessId,
    required this.uploadedByUserId,
    required this.title,
    required this.mediaType,
    required this.url,
    required this.createdAt,
    this.description,
    this.thumbnailUrl,
    this.isPublic = true,
    this.fileSizeBytes,
  });

  final String id;
  final String businessId;

  /// The userId of the owner or staff member who uploaded this item.
  final String uploadedByUserId;

  final String title;
  final String? description;

  /// Values: 'video' | 'audio' | 'pdf' | 'image'
  final String mediaType;

  /// Storage URL or mock path.
  final String url;

  /// Optional thumbnail URL for video/image previews.
  final String? thumbnailUrl;

  /// When true, all authenticated clients can view. When false, owner-only.
  final bool isPublic;

  /// Optional file size in bytes.
  final int? fileSizeBytes;

  final DateTime createdAt;

  // ── fromJson ──────────────────────────────────────────────────────────────────

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      uploadedByUserId: json['uploaded_by_user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaType: json['media_type'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      fileSizeBytes: json['file_size_bytes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'uploaded_by_user_id': uploadedByUserId,
      'title': title,
      'description': description,
      'media_type': mediaType,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'is_public': isPublic,
      'file_size_bytes': fileSizeBytes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────────

  MediaItemModel copyWith({
    String? id,
    String? businessId,
    String? uploadedByUserId,
    String? title,
    String? description,
    String? mediaType,
    String? url,
    String? thumbnailUrl,
    bool? isPublic,
    int? fileSizeBytes,
    DateTime? createdAt,
  }) {
    return MediaItemModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaType: mediaType ?? this.mediaType,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPublic: isPublic ?? this.isPublic,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
