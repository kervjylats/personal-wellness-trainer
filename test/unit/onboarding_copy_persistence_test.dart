// test/unit/onboarding_copy_persistence_test.dart
//
// Round 7 — onboarding must not silently discard the Owner's own copy.
//
// The onboarding form collected Business Tagline, Description and Bio, but
// completeOnboarding() only ever received four values, so all three were
// thrown away. The Bio step was worse: it overwrote displayName with the
// business name, so an Owner named "Jim" who typed a personal bio ended up
// renamed to their business's name.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';

UserProfile _owner({String displayName = 'Jim Rivera'}) {
  return UserProfile(
    userId: 'u1',
    businessId: 'b1',
    role: 'owner',
    displayName: displayName,
    joinedAt: DateTime(2026, 1, 1),
    isActive: true,
  );
}

void main() {
  group('UserProfile marketing copy', () {
    test('carries tagline, description and bio through copyWith', () {
      final updated = _owner().copyWith(
        businessTagline: 'Nutrition with purpose',
        businessDescription: 'Personalised meal plans for busy parents.',
        ownerBio: 'Certified nutritionist, 10 years.',
      );

      expect(updated.businessTagline, 'Nutrition with purpose');
      expect(
        updated.businessDescription,
        'Personalised meal plans for busy parents.',
      );
      expect(updated.ownerBio, 'Certified nutritionist, 10 years.');
    });

    test('round-trips through JSON', () {
      final original = _owner().copyWith(
        businessTagline: 'Pilates with purpose',
        businessDescription: 'Small group classes.',
        ownerBio: 'Ex-dancer.',
      );

      final restored = UserProfile.fromJson(original.toJson());

      expect(restored.businessTagline, original.businessTagline);
      expect(restored.businessDescription, original.businessDescription);
      expect(restored.ownerBio, original.ownerBio);
    });

    test('is null when never supplied — not an empty string', () {
      final plain = _owner();

      expect(plain.businessTagline, isNull);
      expect(plain.businessDescription, isNull);
      expect(plain.ownerBio, isNull);
    });

    test('stays out of toJson when null, so untouched optional fields '
        'do not persist blanks', () {
      final json = _owner().toJson();

      expect(json.containsKey('business_tagline'), isFalse);
      expect(json.containsKey('business_description'), isFalse);
      expect(json.containsKey('owner_bio'), isFalse);
    });

    test('writing copy does not clobber displayName', () {
      // Regression guard for the Bio step bug: setting the bio saved
      // displayName = businessName instead.
      final updated = _owner(displayName: 'Jim Rivera').copyWith(
        businessName: "Jim's Nutrition",
        ownerBio: 'Certified nutritionist, 10 years.',
      );

      expect(updated.displayName, 'Jim Rivera');
      expect(updated.businessName, "Jim's Nutrition");
      expect(updated.ownerBio, 'Certified nutritionist, 10 years.');
    });
  });
}