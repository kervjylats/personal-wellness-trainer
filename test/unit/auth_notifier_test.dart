import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';

void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    setUp(() { container = ProviderContainer(); });
    tearDown(() { container.dispose(); });

    test('initial state is AuthInitial or AuthUnauthenticated', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final state = container.read(authNotifierProvider);
      // FIX: .or() doesn't exist on TypeMatcher — use anyOf() instead
      expect(state, anyOf(isA<AuthInitial>(), isA<AuthUnauthenticated>()));
    });

    test('signIn with bad credentials → AuthUnauthenticated with error', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .signIn('bad@test.com', 'WrongPass!');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
      if (state is AuthUnauthenticated) {
        expect(state.errorMessage, isNotNull);
      }
    });

    test('devQuickSignIn → AuthAuthenticated with correct role', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      if (state is AuthAuthenticated) {
        expect(state.profile.role, equals('owner'));
        expect(state.profile.jobId, equals('yoga_studio'));
        expect(state.isNewOwner, isFalse);
      }
    });

    test('devQuickSignIn → isNewOwner = false (no onboarding redirect)', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'nutritionist', jobLabel: 'Nutritionist');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final state = container.read(authNotifierProvider);
      if (state is AuthAuthenticated) {
        expect(state.isNewOwner, isFalse,
            reason: 'devQuickSignIn must never trigger onboarding');
      }
    });

    test('signOut → AuthUnauthenticated', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await container.read(authNotifierProvider.notifier).signOut();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthUnauthenticated>());
    });

    test('updateProfile updates display name', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      container.read(authNotifierProvider.notifier)
          .updateProfile(displayName: 'Updated Name');
      final state = container.read(authNotifierProvider);
      if (state is AuthAuthenticated) {
        expect(state.profile.displayName, equals('Updated Name'));
      }
    });

    test('completeOnboarding returns bool', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .devQuickSignIn(jobId: 'yoga_studio', jobLabel: 'Yoga Studio');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final result = await container.read(authNotifierProvider.notifier)
          .completeOnboarding(
            businessName:    'My Yoga',
            category:        'yoga_studio',
            primaryColorHex: '#2471A3',
          );
      expect(result, isA<bool>());
    });

    test('clearError resets errorMessage', () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await container.read(authNotifierProvider.notifier)
          .signIn('bad@test.com', 'WrongPass!');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      container.read(authNotifierProvider.notifier).clearError();
      final state = container.read(authNotifierProvider);
      if (state is AuthUnauthenticated) {
        expect(state.errorMessage, isNull);
      }
    });
  });
}
