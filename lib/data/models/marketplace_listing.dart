// lib/data/models/marketplace_listing.dart
//
// Data model for a single marketplace listing entry.
//
// IMPORTANT: This model uses platform_id, NOT business_id, for the
// cross-tenant DISCOVERY/filtering itself (who can see whom in the
// marketplace) — that part is still governed by platform_id per Blueprint
// Section 9 (Model B Deep Dive) and Section 18.
//
// business_id IS still included here, separately: once two owners agree
// to partner, the resulting AgreementModel records are properly
// tenant-scoped (each stored under its own owner's business_id, per the
// normal per-tenant isolation rule) — so accepting a cross-tenant request
// needs to know each side's business_id to create those two records
// correctly. It is never used for discovery/filtering, only for that.
//
// A listing represents an owner's availability signal:
//   - discoverable: master toggle — OFF means invisible to the entire marketplace.
//   - openCategories: the category IDs the owner is seeking a partner for.
//     Slots with an active agreement are removed from openCategories
//     by the notifier (never shown as available when filled).
//   - showToSameTitle: opt-in to the same-job peer network. Owners with the
//     SAME ownerCategoryId are hidden from each other unless BOTH listings
//     carry this true — mutual consent, so nobody is ever exposed to a
//     same-job rival who didn't ask for it. Defaults to false, which
//     reproduces the original "same job never appears" behaviour exactly.
//
// Design rules (Blueprint §14):
//   - Immutable. All fields final.
//   - copyWith() for producing updated copies.
//   - fromJson() / toJson() for mock and Supabase layers.
//   - ZERO business logic. Pure data container.

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.platformId,
    required this.ownerUserId,
    required this.businessId,
    required this.businessName,
    required this.ownerCategoryId,
    required this.discoverable,
    required this.openCategories,
    required this.updatedAt,
    this.showToSameTitle = false,
    this.tagline,
    this.averageRating,
  });

  final String id;
  final String platformId;
  final String ownerUserId;
  final String businessId;
  final String businessName;
  final String ownerCategoryId;
  final bool discoverable;
  final List<String> openCategories;
  final DateTime updatedAt;

  /// Whether this owner wants to appear to (and see) other owners in the
  /// same job. Mutual opt-in — see the file header.
  final bool showToSameTitle;
  final String? tagline;
  final double? averageRating;

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] as String,
      platformId: json['platform_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      businessId: json['business_id'] as String,
      businessName: json['business_name'] as String? ?? '',
      ownerCategoryId: json['owner_category_id'] as String,
      discoverable: json['discoverable'] as bool? ?? false,
      openCategories: List<String>.from(
        json['open_categories'] as List<dynamic>? ?? [],
      ),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      showToSameTitle: json['show_to_same_title'] as bool? ?? false,
      tagline: json['tagline'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform_id': platformId,
      'owner_user_id': ownerUserId,
      'business_id': businessId,
      'business_name': businessName,
      'owner_category_id': ownerCategoryId,
      'discoverable': discoverable,
      'open_categories': openCategories,
      'show_to_same_title': showToSameTitle,
      // Always serialise in UTC: this payload is written by
      // SupabaseMarketplaceSource.upsertListing into a timestamptz column.
      // An offset-less local ISO string gets read as session-time (UTC) on
      // the server, shifting the stored instant by the device's offset.
      'updated_at': updatedAt.toUtc().toIso8601String(),
      if (tagline != null) 'tagline': tagline,
      if (averageRating != null) 'average_rating': averageRating,
    };
  }

  MarketplaceListing copyWith({
    String? id,
    String? platformId,
    String? ownerUserId,
    String? businessId,
    String? businessName,
    String? ownerCategoryId,
    bool? discoverable,
    List<String>? openCategories,
    DateTime? updatedAt,
    bool? showToSameTitle,
    String? tagline,
    double? averageRating,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      platformId: platformId ?? this.platformId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      ownerCategoryId: ownerCategoryId ?? this.ownerCategoryId,
      discoverable: discoverable ?? this.discoverable,
      openCategories: openCategories ?? this.openCategories,
      updatedAt: updatedAt ?? this.updatedAt,
      showToSameTitle: showToSameTitle ?? this.showToSameTitle,
      tagline: tagline ?? this.tagline,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  @override
  String toString() =>
      'MarketplaceListing(id: $id, platform: $platformId, '
      'category: $ownerCategoryId, discoverable: $discoverable, '
      'showToSameTitle: $showToSameTitle)';
}