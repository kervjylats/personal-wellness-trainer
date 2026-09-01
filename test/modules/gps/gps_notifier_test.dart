// test/modules/gps/gps_notifier_test.dart
//
// Tests for GpsNotifier — Blueprint Section 16.
// Run with: flutter test test/modules/gps/gps_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/gps_point_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/config/config_provider.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/modules/gps/providers/gps_notifier.dart';
import '../../helpers/fake_config.dart';

// A version of the build config with GPS enabled, for testing.
final _gpsEnabledBuild = ModulesIncluded(
  activity:      true,
  finance:       true,
  team:          true,
  messaging:     true,
  notifications: true,
  agreements:    true,
  media:         true,
  catalog:       true,
  gps:           true,   // ← enable GPS for these tests
  deliveryFees:  fakeEngineConfig.build.modulesIncluded.deliveryFees,
  scheduling:    true,
  reservations:  true,
  inventory:     true,
  reviews:       true,
);

void main() {
  group('GpsNotifier', () {
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
          // Override build config so GPS module is considered included.
          buildConfigProvider
              .overrideWithValue(fakeEngineConfig.build.copyWith(
            modulesIncluded: _gpsEnabledBuild,
          )),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    // Ensure AppBuildConfig has a copyWith (we'll add it below).
    // We'll quickly extend AppBuildConfig in the test file.
    // (See extension at bottom of file.)

    test('owner receives latest point per user', () async {
      final container = containerFor('owner');
      final result = await container.read(gpsNotifierProvider.future);
      expect(result, isNotEmpty);
      final userIds = result.map((p) => p.userId).toList();
      expect(userIds.toSet().length, equals(userIds.length));
    });

    test('staff receives their own full history', () async {
      final container = containerFor('staff');
      final result = await container.read(gpsNotifierProvider.future);
      for (final point in result) {
        expect(point.userId, equals('usr_staff_001'));
      }
    });

    test('recordPoint adds a new GPS point', () async {
      final container = containerFor('staff');
      final before = await container.read(gpsNotifierProvider.future);

      final recorded = await container
          .read(gpsNotifierProvider.notifier)
          .recordPoint(
            latitude: 51.5000,
            longitude: -0.1200,
            label: 'Test point',
          );

      expect(recorded, isA<GpsPointModel>());
      expect(recorded!.latitude, equals(51.5000));

      final after = await container.read(gpsNotifierProvider.future);
      expect(after.length, greaterThan(before.length));
    });

    test('clearMyPoints removes all points for current user', () async {
      final container = containerFor('staff');

      final success = await container
          .read(gpsNotifierProvider.notifier)
          .clearMyPoints();

      expect(success, isTrue);

      final after = await container.read(gpsNotifierProvider.future);
      expect(after, isEmpty);
    });
  });
}

// ── Fake auth ──────────────────────────────────────────────────────────

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._profile);
  final UserProfile _profile;

  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}

// ── Temporary copyWith for AppBuildConfig (only needed for tests) ──────

extension _AppBuildConfigCopyWith on AppBuildConfig {
  AppBuildConfig copyWith({
    ModulesIncluded? modulesIncluded,
  }) {
    return AppBuildConfig(
      buildName: buildName,
      version: version,
      modulesIncluded: modulesIncluded ?? this.modulesIncluded,
      mediaTypes: mediaTypes,
      paymentProviders: paymentProviders,
      ownerHasControlPanel: ownerHasControlPanel,
      ownerCanInvitePartners: ownerCanInvitePartners,
      ownerCanManageClientContent: ownerCanManageClientContent,
    );
  }
}