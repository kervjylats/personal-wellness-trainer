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
// exists (/#/accept-invitation).
//
// Two realities this file must respect (Round 7 browser verification):
//
//   1. HASH URL STRATEGY — the app is a hash router (no url_strategy
//      package / usePathUrlStrategy anywhere). Routes live inside the
//      FRAGMENT: `#/accept-invitation`. A path-style link
//      (/accept-invitation?token=…) would make the browser GET that path
//      from the server (404 on a static host, app never loads), and even
//      if served, the router would land on the default route instead of
//      the redemption screen. So the query rides INSIDE the fragment:
//      `https://host/#/accept-invitation?token=wlp_000011` — that is what
//      GoRouterState.uri.queryParameters sees.
//
//   2. LIVE ORIGIN by default — links must point at wherever the app is
//      actually running (localhost during dev/demo, the real domain in
//      production). BuyerConfig.inviteBaseUrl is an OPTIONAL override for
//      a reseller who wants invites to point at a different canonical
//      domain; when it's blank, Uri.base.origin is used.
// ═══════════════════════════════════════════════════════════════

import 'package:personal_wellness_trainer/config/buyer_config.dart';

abstract final class InviteLinkBuilder {
  /// The query parameter carrying the invite/activation code on a shared
  /// link. Kept as a constant so the builder, the screens that read it
  /// back off a URL, and any future QR payload agree on one name.
  static const String tokenParam = 'token';

  /// Full shareable link for [token] — e.g.
  /// https://host/#/accept-invitation?token=wlp_000011
  ///
  /// This is what every invite surface shows, copies, shares and encodes
  /// into its QR code, so a recipient can tap or scan it and land
  /// directly on the redemption screen with the code already filled in.
  static String buildInviteUrl(String token) {
    final base = _base();
    return '$base$_acceptInvitationPath?$tokenParam=$token';
  }

  /// The plain front door of the app — no invite, no token. This is what
  /// gets shared when someone taps Share inside a chat thread: there's no
  /// invite code in play there, so we share the app's own landing page
  /// rather than inventing a token.
  static String buildAppLink() => _base();

  /// Buyer-configured canonical domain when set, otherwise the live
  /// origin of the running app. Falls back to http://host for the odd
  /// non-web environment (Dart VM tests) where Uri.base has no scheme.
  static String _base() {
    final configured = BuyerConfig.inviteBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }
    final current = Uri.base;
    if (current.isScheme('http') || current.isScheme('https')) {
      return current.origin;
    }
    return 'http://localhost';
  }

  /// Pulls a code back out of whatever the visitor actually has:
  ///   - a full shared link   'https://…/#/accept-invitation?token=wlp_000011'
  ///   - the old path-style    'https://…/accept-invitation?token=wlp_000011'
  ///   - a fragment by itself  '#/accept-invitation?token=wlp_000011'
  ///   - a bare token          'wlp_000011'
  ///   - a pasted activation   'DEMO-YOGA-001'
  ///
  /// Returns null when there's nothing usable in [input]. Used by the
  /// redemption screen (deep link / scanned QR) and by "Join" when a
  /// visitor pastes a whole link instead of just the code.
  static String? extractCode(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Bare code — no scheme, no query, no fragment. Return it untouched so
    // ordinary hand-typed tokens and activation keys pass straight through.
    if (!trimmed.contains('?') && !trimmed.contains('/')) {
      return trimmed;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    // Query before the fragment (path-style links, /?token=… front door).
    final fromQuery = _codeFrom(uri.queryParameters);
    if (fromQuery != null) return fromQuery;

    // Hash-style links keep the route AND its query inside the fragment
    // ('#/accept-invitation?token=wlp_000011') — the fragment is where a
    // hash router stores its location, so this is the common case.
    final fragment = uri.fragment;
    if (fragment.contains('?')) {
      final fromFragment = Uri.tryParse(fragment);
      final code = _codeFrom(fromFragment?.queryParameters ?? const {});
      if (code != null) return code;
    }

    // A link with no usable token — try the LAST non-empty path segment so
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

  static String? _codeFrom(Map<String, String> params) {
    final raw = params[tokenParam];
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Route to the redemption screen. With hash routing the '#' belongs to
  /// the final URL (added by [_base] + this path), so the fragment carries
  /// both the route and its ?token= query.
  static const String _acceptInvitationPath = '/#/accept-invitation';
}