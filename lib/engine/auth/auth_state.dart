// lib/engine/auth/auth_state.dart
//
// Sealed class representing every possible authentication state.
// AuthNotifier holds one of these states and the router redirects on change.
//
// States:
//   AuthInitial          — app just launched, no session check done yet
//   AuthLoading          — sign-in or session restore in progress
//   AuthAuthenticated    — user is signed in; profile is available
//   AuthUnauthenticated  — no active session; optional error message
//
// Phase 7: AuthAuthenticated gains isNewOwner flag.
//   true  → router redirects to /onboarding (runs once, first owner login)
//   false → normal shell routing

import 'package:personal_wellness_trainer/data/models/user_profile.dart';

sealed class AuthState {
  const AuthState();
}

/// Initial state before any auth check has run.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A sign-in or session-restore operation is in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is signed in. [profile] is guaranteed non-null.
///
/// [isNewOwner] is true only after a fresh owner sign-up, until
/// [AuthNotifier.completeOnboarding] is called. The router uses this
/// to redirect to the onboarding screen exactly once.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.profile,
    this.isNewOwner = false,
  });

  final UserProfile profile;

  /// True only on the first owner login — redirects to /onboarding.
  /// Always false for partner / staff / client.
  final bool isNewOwner;
}

/// No active session. [errorMessage] is set when sign-in failed.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});
  final String? errorMessage;
}
