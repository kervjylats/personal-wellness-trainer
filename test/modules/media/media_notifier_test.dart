// test/modules/media/media_notifier_test.dart
//
// Tests for MediaNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/media/media_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import '../../helpers/fake_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/media_item_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/media/providers/media_notifier.dart';

void main() {
  group('MediaNotifier', () {
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

    test('owner receives all media items (public + private)', () async {
      final container = containerFor('owner');
      final result = await container.read(mediaNotifierProvider.future);
      expect(result, isNotEmpty);
      // Seed data includes a private item — owner should see it.
      expect(result.any((m) => !m.isPublic), isTrue);
    });

    test('client receives only public media items', () async {
      final container = containerFor('client');
      final result = await container.read(mediaNotifierProvider.future);
      for (final item in result) {
        expect(item.isPublic, isTrue);
      }
    });

    test('create adds a new media item — list grows by one', () async {
      final container = containerFor('owner');
      final before = await container.read(mediaNotifierProvider.future);

      final created = await container
          .read(mediaNotifierProvider.notifier)
          .create(
            title: 'New Video',
            mediaType: 'video',
            url: 'mock://new.mp4',
          );

      expect(created, isA<MediaItemModel>());
      expect(created!.mediaType, equals('video'));

      final after = await container.read(mediaNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('delete removes item from list', () async {
      final container = containerFor('owner');
      final items = await container.read(mediaNotifierProvider.future);
      final target = items.first;

      final success = await container
          .read(mediaNotifierProvider.notifier)
          .delete(target.id);

      expect(success, isTrue);

      final after = await container.read(mediaNotifierProvider.future);
      expect(after.any((m) => m.id == target.id), isFalse);
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}
