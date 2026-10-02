// lib/engine/invites/invite_link_builder.dart
// ═══════════════════════════════════════════════════════════════
// INVITE LINK BUILDER — the ONE place an invite becomes a URL.
//
// Before this file, three screens each hand-rolled "the invite" and
// all three disagreed:
//
//   1. invite_dialog.dart        → passed the BARE TOKEN (wlp_000011),
//                                   so the QR encoded a token, not a link.
//   2. client_dashboard_screen   → hardcoded a fake domain,
//                                   'https://wellpath.app/join?token=$token'
//                                   — the leftover pre-rename brand, and
//                                   /join was never a real route.
//   3. slot_conflict_screen      → 'https://YOUR_DOMAIN_HERE/join?token=\$token'
//                                   inside a `const`, with an ESCAPED dollar,
//                                   so it printed the literal text "$token"
//                                   and the real token was never displayed.
//
// Everything now goes through buildInviteUrl() so a shared link and its
// QR encode the SAME thing, and it points at a route that actually
// exists (/accept-invitation). The base is configurable per buyer — see
// BuyerConfig.inviteBaseUrl — because an Owner's invite links are
// different from a reseller's own marketing page.
// ═══════════════════════════════════════════════════════════════

import 'package:personal_wellness_trainer/config/buyer_config.dart';

abstract final class InviteLinkBuilder {
  /// The query parameter carrying the invite/activation code on a shared
  /// link. Kept as a constant so the builder, the screens that read it
  /// back off a URL, and any future QR payload agree on one name.
  static const String tokenParam = 'token';

  /// Full shareable link for [token] — e.g.
  /// https://your-domain.example/accept-invitation?token=wlp_000011
  ///
  /// This is what every invite surface shows, copies, shares and encodes
  /// into its QR code, so a recipient can tap or scan it and land
  /// directly on the redemption screen with the code already filled in.
  static String buildInviteUrl(String token) {
    final base = BuyerConfig.inviteBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base$_acceptInvitationPath?$tokenParam=$token';
  }

  /// The plain front door of the app — no invite, no token. This is what
  /// gets shared when someone taps Share inside a chat thread: there's no
  /// invite code in play there, so we share the app's own landing page
  /// rather than inventing a token.
  static String buildAppLink() {
    final base = BuyerConfig.inviteBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return base;
  }

  /// Pulls a code back out of whatever the visitor actually has:
  ///   - a full shared link   'https://…/accept-invitation?token=wlp_000011'
  ///   - a bare token         'wlp_000011'
  ///   - a pasted activation  'DEMO-YOGA-001'
  ///
  /// Returns null when there's nothing usable in [input]. Used by the
  /// redemption screen (deep link / scanned QR) and by "Join" when a
  /// visitor pastes a whole link instead of just the code.
  static String? extractCode(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Bare code — no scheme, no query. Return it untouched so ordinary
    // hand-typed tokens and activation keys pass straight through.
    if (!trimmed.contains('?') && !trimmed.contains('/')) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    final fromQuery = uri.queryParameters[tokenParam];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return fromQuery.trim();
    }

    // A link with no usable ?token= — try the LAST non-empty path segment so
    // a future /wlp_000011-style link still resolves. Known route names are
    // skipped deliberately: a link like /accept-invitation?token= (param
    // present but blank) must resolve to nothing rather than handing the
    // caller the literal route name as if it were a code.
    const knownRoutes = {'accept-invitation', 'get-started', 'login', 'onboarding'};
    final segments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty && !knownRoutes.contains(s))
        .toList(growable: false);
    if (segments.isNotEmpty) return segments.last;
    return null;
  }

  static const String _acceptInvitationPath = '/accept-invitation';
}