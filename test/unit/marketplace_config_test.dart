// test/unit/marketplace_config_test.dart
//
// ConfigMarketplace — the same-job visibility defaults. The app ships with
// no `partnership_marketplace` block in any config asset, so these
// fallbacks ARE the production behaviour: opt-in off, owner may toggle.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/engine/config/config_schema.dart';

void main() {
  group('ConfigMarketplace defaults', () {
    test('same-job visibility starts off', () {
      expect(ConfigMarketplace.defaults.sameTitleVisibilityDefault, isFalse);
    });

    test('the owner may change it', () {
      expect(ConfigMarketplace.defaults.sameTitleVisibilityOwnerCanToggle,
          isTrue);
    });

    test('an absent block keeps the same-job network closed', () {
      final config = ConfigMarketplace.fromJson(const {});
      expect(config.sameTitleVisibilityDefault, isFalse);
      expect(config.sameTitleVisibilityOwnerCanToggle, isTrue);
    });
  });

  group('ConfigMarketplace fromJson', () {
    test('a buyer can open the same-job network platform-wide', () {
      final config = ConfigMarketplace.fromJson(
          const {'same_title_visibility_default': true});
      expect(config.sameTitleVisibilityDefault, isTrue);
    });

    test('a buyer can lock the toggle so owners cannot change it', () {
      final config = ConfigMarketplace.fromJson(
          const {'same_title_visibility_owner_can_toggle': false});
      expect(config.sameTitleVisibilityOwnerCanToggle, isFalse);
    });

    test('the pre-existing keys are untouched', () {
      final config = ConfigMarketplace.fromJson(const {
        'enabled': false,
        'show_business_name': false,
        'show_rating': false,
        'show_tagline': false,
        'request_message_required': true,
      });
      expect(config.enabled, isFalse);
      expect(config.showBusinessName, isFalse);
      expect(config.showRating, isFalse);
      expect(config.showTagline, isFalse);
      expect(config.requestMessageRequired, isTrue);
    });
  });
}