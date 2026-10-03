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
import 'package:personal_wellness_trainer/engine/auth/marketing_landing_screen.dart';
import 'package:personal_wellness_trainer/engine/invites/invite_link_builder.dart';
import 'package:personal_wellness_trainer/engine/navigation/role_routes.dart';
import 'package:personal_wellness_trainer/engine/roles/app_role.dart';
import 'package:personal_wellness_trainer/modules/challenges/screens/challenge_detail_screen.dart';
import 'package:personal_wellness_trainer/modules/settings/screens/own_business_screen.dart';

/// The platform route captured at app entry (set by main() before runApp).
///
/// The engine resets `defaultRouteName` to '/' as soon as the framework
/// starts reporting navigation, which on web races with GoRouter's
/// construction when the incoming link carries `?token=` in the hash —
/// the router then boots at '/' and the shared invite token is dropped
/// before the redemption screen can read it (Round 7 probe). Pinning the
/// captured route with `overridePlatformDefaultLocation` makes the boot
/// location deterministic instead.
String bootInitialRoute = RouteNames.rootPath;

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier._redirect,
    initialLocation: bootInitialRoute,
    overridePlatformDefaultLocation: true,
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
        path: RouteNames.marketingLandingPath,
        name: RouteNames.marketingLanding,
        builder: (_, __) => const MarketingLandingScreen(),
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
        // The login and marketing-landing forms have their own inline
        // loading UI (button spinner), so they must NOT be bounced to
        // /loading: doing so made a FAILED sign-in land on /loading first
        // and then — because /loading isn't whitelisted for
        // AuthUnauthenticated below — silently drop the user on the front
        // door with the error message rendered nowhere (Round 6 probe).
        //
        // The redemption screen joins them (Round 7): a shared invite
        // link opens COLD, so it spends its first beats in AuthInitial
        // while the session restores. Bouncing it to /loading discards
        // ?token= (the redirect target carries no query), and when
        // AuthUnauthenticated then redirects again the token is already
        // gone — the recipient landed on a generic front door with no
        // prefilled code. It's a public form; let it render.
        if (location == RouteNames.loadingPath ||
            location == RouteNames.rootPath ||
            location == RouteNames.loginPath ||
            location == RouteNames.marketingLandingPath ||
            location == RouteNames.acceptInvitationPath) {
          return null;
        }
        return RouteNames.loadingPath;

      case AuthUnauthenticated():
        if (location == RouteNames.loginPath ||
            location == RouteNames.onboardingPath ||
            location == '/forgot-password' ||
            location == RouteNames.acceptInvitationPath ||
            location == RouteNames.marketingLandingPath) {
          return null;
        }
        // Front door: logged-out visitors land on the buyer's marketing
        // landing page (/get-started), not the login form. Sign-in remains
        // reachable via the "Sign in" link on that page. If the bounced
        // route was carrying an invite token, keep it on the query string
        // — the landing screen reads it and shows the "you've been
        // invited" state with the code prefilled, so no shared link ever
        // arrives dead (Round 7).
        final token = routerState.uri
            .queryParameters[InviteLinkBuilder.tokenParam];
        if (token != null && token.trim().isNotEmpty) {
          return '${RouteNames.marketingLandingPath}'
              '?${InviteLinkBuilder.tokenParam}=${Uri.encodeComponent(token.trim())}';
        }
        return RouteNames.marketingLandingPath;

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
            location == RouteNames.onboardingPath ||
            location == '/forgot-password' ||
            location == RouteNames.acceptInvitationPath ||
            location == RouteNames.marketingLandingPath) {
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

