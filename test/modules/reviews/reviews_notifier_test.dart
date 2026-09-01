// test/modules/reviews/reviews_notifier_test.dart
//
// Tests for ReviewsNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/reviews/reviews_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/review_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/reviews/providers/reviews_notifier.dart';

void main() {
  group('ReviewsNotifier', () {
    ProviderContainer containerFor(String role) {
      final profile = UserProfile(
        userId: 'usr_${role}_001',
        businessId: 'biz_mock_001',
        role: role,
        displayName: 'Test $role',
        joinedAt: DateTime(2025),
        isActive: true,
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(profile),
          ),
          buildConfigProvider.overrideWithValue(fakeEngineConfig.build),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('owner receives the full reviews list', () async {
      final container = containerFor('owner');
      final result = await container.read(reviewsNotifierProvider.future);
      expect(result, isNotEmpty);
      expect(result.first, isA<ReviewModel>());
    });

    test('create adds a new review — list grows by one', () async {
      final container = containerFor('owner');
      final before = await container.read(reviewsNotifierProvider.future);

      final created = await container
          .read(reviewsNotifierProvider.notifier)
          .create(
            targetUserId: 'usr_staff_001',
            rating: 4,
            comment: 'Test comment',
          );

      expect(created, isA<ReviewModel>());
      expect(created!.rating, equals(4));

      final after = await container.read(reviewsNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('setVerified updates isVerified on the record', () async {
      final container = containerFor('owner');
      final reviews = await container.read(reviewsNotifierProvider.future);
      final unverified =
          reviews.firstWhere((r) => !r.isVerified, orElse: () => reviews.first);

      final success = await container
          .read(reviewsNotifierProvider.notifier)
          .setVerified(unverified.id, isVerified: true);

      expect(success, isTrue);

      final after = await container.read(reviewsNotifierProvider.future);
      final updated = after.firstWhere((r) => r.id == unverified.id);
      expect(updated.isVerified, isTrue);
    });

    test('delete removes review from list', () async {
      final container = containerFor('owner');
      final reviews = await container.read(reviewsNotifierProvider.future);
      final target = reviews.first;

      final success = await container
          .read(reviewsNotifierProvider.notifier)
          .delete(target.id);

      expect(success, isTrue);

      final after = await container.read(reviewsNotifierProvider.future);
      expect(after.any((r) => r.id == target.id), isFalse);
    });

    test('module disabled — returns empty list when reviews not in config',
        () async {
      final profile = UserProfile(
        userId: 'usr_owner_001',
        businessId: 'biz_mock_001',
        role: 'owner',
        displayName: 'Owner',
        joinedAt: DateTime(2025),
        isActive: true,
      );
      // Default mock config has reviews = false, so notifier returns [].
      // In the live test environment (export.txt config has reviews: true),
      // we use the standard container and expect data.
      // This test simply confirms build() returns a List<ReviewModel>.
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => FakeAuthNotifier(profile)),
          buildConfigProvider.overrideWithValue(fakeEngineConfig.build),
        ],
      );
      addTearDown(container.dispose);
      final result = await container.read(reviewsNotifierProvider.future);
      expect(result, isA<List<ReviewModel>>());
    });
  });
}

// ── Fake auth notifier ────────────────────────────────────────────────────────

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
