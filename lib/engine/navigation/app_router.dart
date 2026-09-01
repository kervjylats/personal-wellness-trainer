// lib/engine/navigation/app_router.dart (cleaned)
//
// Route *tables* (per-role route lists + the reusable auth-flow list)
// now live in role_routes.dart — this file was 624 lines and most of
// that was route tables, not actual router/redirect logic. See
// role_routes.dart's header for why.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_wellness_trainer/core/constants/route_names.dart';
import 'package:personal_wellness_trainer/core/utils/logger.dart';
import 'package:personal_wellness_trainer/core/widgets/loading_indicator.dart';
import 'package:personal_wellness_trainer/data/models/challenge_model.dart';
import 'package:personal_wellness_trainer/engine/auth/accept_invitation_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/engine/auth/forgot_password_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/onboarding_screen.dart';
import 'package:personal_wellness_trainer/engine/auth/signup_screen.dart';
import 'package:personal_wellness_trainer/engine/navigation/role_routes.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/challenges/screens/challenge_detail_screen.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/own_business_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier._redirect,
    initialLocation: RouteNames.rootPath,
    routes: [
      GoRoute(
        path: RouteNames.rootPath,
        name: 'root',
        builder: (_, __) => const FullScreenLoader(message: 'Starting…'),
      ),
      GoRoute(
        path: RouteNames.loadingPath,
        name: RouteNames.splash,
        builder: (_, __) => const FullScreenLoader(message: 'Loading…'),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.signupPath,
        name: RouteNames.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.onboardingPath,
        name: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.acceptInvitationPath,
        name: RouteNames.acceptInvitation,
        builder: (_, __) => const AcceptInvitationScreen(),
      ),
      GoRoute(
        path: '/own-business',
        name: RouteNames.ownBusiness,
        builder: (_, __) => const OwnBusinessScreen(),
      ),
      GoRoute(
        path: '/challenge-detail',
        name: 'challenge-detail',
        builder: (_, state) =>
            ChallengeDetailScreen(challenge: state.extra! as ChallengeModel),
      ),
      ...ownerRoutes(),
      ...partnerRoutes(),
      ...staffRoutes(),
      ...clientRoutes(),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      AppLogger.debug(
        'RouterNotifier: auth changed '
        '${previous.runtimeType} → ${next.runtimeType}',
        tag: 'AppRouter',
      );
      notifyListeners();
    });
  }

  final Ref _ref;

  String? _redirect(BuildContext context, GoRouterState routerState) {
    final authState = _ref.read(authNotifierProvider);
    final location = routerState.matchedLocation;

    switch (authState) {
      case AuthInitial():
      case AuthLoading():
        if (location == RouteNames.loadingPath ||
            location == RouteNames.rootPath) {
          return null;
        }
        return RouteNames.loadingPath;

      case AuthUnauthenticated():
        if (location == RouteNames.loginPath ||
            location == RouteNames.signupPath ||
            location == RouteNames.onboardingPath ||
            location == '/forgot-password' ||
            location == RouteNames.acceptInvitationPath) {
          return null;
        }
        return RouteNames.loginPath;

      case AuthAuthenticated(:final profile, :final isNewOwner):
        if (isNewOwner) {
          if (location == RouteNames.onboardingPath) return null;
          return RouteNames.onboardingPath;
        }

        final role = AppRole.fromString(profile.role);
        final targetPath = _shellPathForRole(role);

        if (location.startsWith(targetPath) || location == '/own-business') {
          return null;
        }

        if (location == RouteNames.loginPath ||
            location == RouteNames.loadingPath ||
            location == RouteNames.rootPath ||
            location == RouteNames.signupPath ||
            location == RouteNames.onboardingPath ||
            location == '/forgot-password' ||
            location == RouteNames.acceptInvitationPath) {
          return targetPath;
        }

        if (_isShellPath(location) && !location.startsWith(targetPath)) {
          return targetPath;
        }

        return null;
    }
  }

  String _shellPathForRole(AppRole role) {
    switch (role) {
      case AppRole.owner:
        return RouteNames.ownerPath;
      case AppRole.partner:
        return RouteNames.partnerPath;
      case AppRole.staff:
        return RouteNames.staffPath;
      case AppRole.client:
        return RouteNames.clientPath;
    }
  }

  bool _isShellPath(String path) {
    return path == RouteNames.ownerPath ||
        path == RouteNames.partnerPath ||
        path == RouteNames.staffPath ||
        path == RouteNames.clientPath;
  }
}

