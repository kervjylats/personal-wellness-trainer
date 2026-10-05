// test/unit/marketplace_listing_test.dart
//
// MarketplaceListing — the same-job opt-in flag has to survive every layer
// it crosses (model → repository → Supabase row), because a silent default
// here would silently re-hide an owner who had opted in.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';

void main() {
  MarketplaceListing build({bool showToSameTitle = true}) {
    return MarketplaceListing(
      id: 'mkt_1',
      platformId: 'platform_1',
      ownerUserId: 'usr_1',
      businessId: 'biz_1',
      businessName: 'Test Studio',
      ownerCategoryId: 'yoga_studio',
      discoverable: true,
      openCategories: const ['pilates_studio'],
      showToSameTitle: showToSameTitle,
      updatedAt: DateTime.utc(2026, 2, 1),
      tagline: 'Tagline',
      averageRating: 4.5,
    );
  }

  group('showToSameTitle', () {
    test('defaults to false when not supplied', () {
      final listing = MarketplaceListing(
        id: 'mkt_2',
        platformId: 'p',
        ownerUserId: 'u',
        businessId: 'b',
        businessName: 'n',
        ownerCategoryId: 'yoga_studio',
        discoverable: false,
        openCategories: const [],
        updatedAt: DateTime.utc(2026),
      );
      expect(listing.showToSameTitle, isFalse);
    });

    test('survives a toJson/fromJson round trip as true', () {
      final decoded = MarketplaceListing.fromJson(build().toJson());
      expect(decoded.showToSameTitle, isTrue);
    });

    test('survives a toJson/fromJson round trip as false', () {
      final decoded =
          MarketplaceListing.fromJson(build(showToSameTitle: false).toJson());
      expect(decoded.showToSameTitle, isFalse);
    });

    test('a row written before the column existed loads as false', () {
      final json = build().toJson()..remove('show_to_same_title');
      expect(MarketplaceListing.fromJson(json).showToSameTitle, isFalse);
    });

    test('toJson uses the snake_case key the database column expects', () {
      expect(build().toJson()['show_to_same_title'], isTrue);
    });

    test('copyWith sets it and leaves it alone when omitted', () {
      final listing = build();
      expect(listing.copyWith(discoverable: false).showToSameTitle, isTrue);
      expect(listing.copyWith(showToSameTitle: false).showToSameTitle, isFalse);
    });

    test('toString names the flag so debug output is diagnosable', () {
      expect(build().toString(), contains('showToSameTitle: true'));
    });
  });

  group('round trip', () {
    test('preserves every field', () {
      final original = build();
      final decoded = MarketplaceListing.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.platformId, original.platformId);
      expect(decoded.ownerUserId, original.ownerUserId);
      expect(decoded.businessId, original.businessId);
      expect(decoded.businessName, original.businessName);
      expect(decoded.ownerCategoryId, original.ownerCategoryId);
      expect(decoded.discoverable, original.discoverable);
      expect(decoded.openCategories, original.openCategories);
      expect(decoded.updatedAt, original.updatedAt);
      expect(decoded.tagline, original.tagline);
      expect(decoded.averageRating, original.averageRating);
    });
  });
}