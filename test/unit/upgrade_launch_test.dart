import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_auth_source.dart';
import 'package:personal_wellness_trainer/data/sources/mock/mock_profiles.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Waits until the notifier has finished its async restore/sign-in work.
  /// A plain `await Future.delayed` is racy: the session-restore that
  /// fires inside AuthNotifier.build() can land after a quick devQuickSignIn
  /// and overwrite the freshly signed-in state (the pre-existing flake in
  /// auth_notifier_test.dart). This polls until the state settles instead.
  Future<void> waitSettled(
    ProviderContainer container, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final state = container.read(authNotifierProvider);
      if (state is! AuthLoading && state is! AuthInitial) return;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    fail('AuthNotifier did not settle within $timeout');
  }

  Future<ProviderContainer> freshContainer() async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    await waitSettled(container);
    return container;
  }

  Future<void> signInOwner(ProviderContainer container) async {
    unawaited(container.read(authNotifierProvider.notifier)
        .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio'));
    await waitSettled(container);
  }

  Future<void> signInPartner(ProviderContainer container) async {
    unawaited(container.read(authNotifierProvider.notifier)
        .devQuickSignIn(jobId: 'partner', jobLabel: 'Partner'));
    await waitSettled(container);
  }

  group('upgradeToPremium (Free Owner → Pro Owner)', () {
    test('upgrades plan tier but keeps role, business, and no data loss',
        () async {
      final container = await freshContainer();
      addTearDown(container.dispose);

      await signInOwner(container);
      final before = container.read(authNotifierProvider) as AuthAuthenticated;
      expect(before.profile.planTier, equals('free'));

      await container.read(authNotifierProvider.notifier).upgradeToPremium();
      await waitSettled(container);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      if (state is AuthAuthenticated) {
        expect(state.profile.planTier, equals('premium'));
        expect(state.profile.role, equals('owner'));
        // Same business — nothing migrated, nothing recreated.
        expect(state.profile.businessId, equals(before.profile.businessId));
        expect(state.isNewOwner, isFalse);
      }
    });

    test('logs an upgrade event with to_tier premium', () async {
      final container = await freshContainer();
      addTearDown(container.dispose);

      await signInOwner(container);
      final ownerId =
          (container.read(authNotifierProvider) as AuthAuthenticated)
              .profile
              .userId;

      await container.read(authNotifierProvider.notifier).upgradeToPremium();
      await waitSettled(container);

      final event =
          MockAuthSource.upgradeEvents.lastWhere((e) => e['user_id'] == ownerId);
      expect(event['to_tier'], equals('premium'));
      expect(event['to_role'], equals('owner'));
      expect(event['from_tier'], equals('free'));
    });

    test('is a no-op for an Associate (role untouched)', () async {
      final container = await freshContainer();
      addTearDown(container.dispose);

      await signInPartner(container);
      final partnerId =
          (container.read(authNotifierProvider) as AuthAuthenticated)
              .profile
              .userId;
      final eventsBefore =
          MockAuthSource.upgradeEvents.where((e) => e['user_id'] == partnerId).length;

      await container.read(authNotifierProvider.notifier).upgradeToPremium();
      await waitSettled(container);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      if (state is AuthAuthenticated) {
        expect(state.profile.role, equals('partner'));
        expect(state.profile.planTier,
            equals(MockProfiles.partnerProfile.planTier));
        expect(state.profile.businessId, isNot(startsWith('biz_spin_')));
      }
      expect(
        MockAuthSource.upgradeEvents
            .where((e) => e['user_id'] == partnerId)
            .length,
        equals(eventsBefore),
        reason: 'Associate must not log an upgrade to Pro',
      );
    });
  });

  group('launchOwnBusiness (Associate → own free business)', () {
    test('spins off a new FREE owner business and triggers onboarding',
        () async {
      final container = await freshContainer();
      addTearDown(container.dispose);

      await signInPartner(container);
      final before = container.read(authNotifierProvider) as AuthAuthenticated;

      await container.read(authNotifierProvider.notifier).launchOwnBusiness();
      await waitSettled(container);

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      if (state is AuthAuthenticated) {
        expect(state.profile.role, equals('owner'));
        expect(state.profile.planTier, equals('free'));
        expect(state.profile.businessId, startsWith('biz_spin_'));
        expect(state.profile.businessId, isNot(equals(before.profile.businessId)));
        expect(state.isNewOwner, isTrue,
            reason: 'isNewOwner must be true so the router runs onboarding');
      }
    });

    test('logs a launch event (to_role owner, to_tier free)', () async {
      final container = await freshContainer();
      addTearDown(container.dispose);

      await signInPartner(container);
      final partnerId = MockProfiles.partnerProfile.userId;

      await container.read(authNotifierProvider.notifier).launchOwnBusiness();
      await waitSettled(container);

      final event = MockAuthSource.upgradeEvents
          .lastWhere((e) => e['user_id'] == partnerId);
      expect(event['to_role'], equals('owner'));
      expect(event['to_tier'], equals('free'));
      expect(event['business_id'], startsWith('biz_spin_'));
    });

    test('is a no-op for an Owner', () async {
      final container = await freshContainer();
      addTearDown(container.dispose);

      await signInOwner(container);
      final before = container.read(authNotifierProvider) as AuthAuthenticated;

      await container.read(authNotifierProvider.notifier).launchOwnBusiness();
      await waitSettled(container);

      final state = container.read(authNotifierProvider);
      if (state is AuthAuthenticated) {
        expect(state.profile.role, equals('owner'));
        expect(state.profile.businessId, equals(before.profile.businessId));
        expect(state.isNewOwner, isFalse);
      }
    });
  });

  group('setPlanTier persistence (survives a restart)', () {
    test('persists an upgraded tier to prefs and restores it on session restore',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await waitSettled(container);

      // Build a real signed-up owner so setPlanTier has a persisted profile.
      await container.read(authNotifierProvider.notifier).signUp(
            email: 'persist.owner@test.com',
            password: 'Passw0rd!',
            displayName: 'Persist Owner',
          );
      await waitSettled(container);
      final ownerId =
          (container.read(authNotifierProvider) as AuthAuthenticated)
              .profile
              .userId;
      container.dispose();

      // New container, same prefs: session restored as free owner.
      final container2 = ProviderContainer();
      await waitSettled(container2);
      final restored = container2.read(authNotifierProvider);
      expect(restored, isA<AuthAuthenticated>());
      if (restored is AuthAuthenticated) {
        expect(restored.profile.planTier, equals('free'));
      }

      // Upgrade → tier persists.
      await container2.read(authNotifierProvider.notifier).upgradeToPremium();
      await waitSettled(container2);
      expect(
        (container2.read(authNotifierProvider) as AuthAuthenticated)
            .profile
            .planTier,
        equals('premium'),
      );
      container2.dispose();

      // Brand-new container, same prefs: still Pro after "restart".
      final container3 = ProviderContainer();
      await waitSettled(container3);
      final afterRestart = container3.read(authNotifierProvider);
      expect(afterRestart, isA<AuthAuthenticated>());
      if (afterRestart is AuthAuthenticated) {
        expect(afterRestart.profile.userId, equals(ownerId));
        expect(afterRestart.profile.planTier, equals('premium'));
      }
      container3.dispose();
    });
  });
}